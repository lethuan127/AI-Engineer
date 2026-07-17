# MCP App Lifecycle — Protocol Phases from Discovery to Teardown

> **Source:** SEP-1865, "MCP Apps: Interactive User Interfaces for MCP" — the extension
> spec at [`modelcontextprotocol/ext-apps`](https://github.com/modelcontextprotocol/ext-apps)
> (`specification/2026-01-26/apps.mdx`), status Stable since 2026-01-26.
> Companion to: [MCP Apps Debugging — The Staged Diagnostic View and the URI Cache Trap](./MCP%20Apps%20Debugging%20—%20The%20Staged%20Diagnostic%20View%20and%20the%20URI%20Cache%20Trap.md),
> which debugs the symptom; this note is the map of the protocol underneath it.

---

## 1. Four phases, one spinner

The spec's `### Lifecycle` section defines exactly four phases. Every MCP App — Claude,
ChatGPT, Goose, VS Code — goes through all four, in order, per tool call:

| Phase | Who talks | What it proves |
| --- | --- | --- |
| 1. Connection & Discovery | Server → Host | the tool exists and declares a UI |
| 2. UI Initialization | Host ↔ View (↔ Server) | the iframe mounted and the handshake completed |
| 3. Interactive Phase | View ↔ Host ↔ Server | the user can act and the model can see it |
| 4. Cleanup | Host → View | the View got a chance to wind down before destruction |

> Why it matters: the debugging note treats a hung MCP App as "one of ~7 silent stages."
> Those 7 stages are a *developer-facing* subdivision of phases 2 and 3 above (SDK import,
> `app.connect()`, `ontoolinput`, `ontoolresult`, `callServerTool`). This note maps them back
> to the actual wire messages, so a failed stage points at a specific JSON-RPC exchange
> instead of a vague "the handshake."

## 2. Phase 1 — Connection & Discovery

Two ordinary MCP calls, no App-specific messages yet:

```
Server → Host: resources/list   (includes ui:// resources)
Server → Host: tools/list       (includes tools carrying _meta.ui)
```

A tool opts into a UI by attaching `_meta.ui.resourceUri`. The deprecated flat key still
appears in the wild because it predates the nested form:

```ts
interface Tool {
  name: string;
  _meta?: {
    ui?: { resourceUri?: string; visibility?: Array<"model" | "app"> };
    /** @deprecated — use ui.resourceUri; removed before GA */
    "ui/resourceUri"?: string;
  };
}
```

- `visibility` defaults to `["model", "app"]`. `"model"` = the agent can call the tool;
  `"app"` = the View itself can call it (its own `tools/call`, scoped to the same server
  connection). A `visibility: ["app"]`-only tool is invisible to the agent's tool list and
  the Host MUST reject a `tools/call` for it that doesn't come from the View.
- The resource referenced by `resourceUri` MUST already exist on the server — the Host reads
  it with `resources/read`, not inline in the tool result.
- **Host MAY prefetch and cache the `ui://` resource content here**, "for performance
  optimization." This is the first mention of the caching behavior that becomes the cache
  trap in §7 — it is opt-in and unspecified in mechanism, not a guarantee of freshness.

## 3. Phase 2 — UI Initialization

Two things run in parallel: the real tool call, and the View coming up.

| Direction | Message | Purpose |
| --- | --- | --- |
| Host → Server | `tools/call` | invoke the tool carrying `_meta.ui` |
| Host → Host | mount iframe from the `ui://` HTML (or, on web hosts, mount a Sandbox Proxy first) | render surface |
| View → Host | `ui/initialize` | handshake request; carries `McpUiAppCapabilities` |
| Host → View | `McpUiInitializeResult` | response: `hostContext`, `hostCapabilities` |
| View → Host | `ui/notifications/initialized` | ack — Host MUST NOT send anything to the View before this |
| Host → View | `ui/notifications/tool-input-partial` (0..n) | streamed args, optional |
| Host → View | `ui/notifications/tool-input` | complete args, sent exactly once |
| Host → View | `ui/notifications/tool-result` **or** `ui/notifications/tool-cancelled` | terminal for this call |

> Architectural takeaway: `ui/initialize` → `McpUiInitializeResult` → `initialized` is the
> exact handshake the debugging note's stage 4 (`app.connect()`) blocks on. If a diagnostic
> view goes green through "SDK import" and then hangs, the failure is binary: either the View
> never sent `ui/initialize`, or the Host never returned `McpUiInitializeResult`. Nothing else
> in this phase produces that specific symptom.

`McpUiInitializeResult` has four top-level fields:

```ts
interface McpUiInitializeResult {
  protocolVersion: string;
  hostInfo: { name: string; version: string };
  hostCapabilities: HostCapabilities;
  hostContext: HostContext;
}
```

`hostContext` is environment info about where the View is actually running:

| Field | Type | What it's for |
| --- | --- | --- |
| `toolInfo` | `{ id?: RequestId, tool: Tool }` | which tool call instantiated this View |
| `theme` | `"light" \| "dark"` | color scheme to render in |
| `styles` | `{ variables?, css?: { fonts? } }` | CSS custom properties + `@font-face` block — theming without a design-system dependency |
| `displayMode` / `availableDisplayModes` | `"inline"\|"fullscreen"\|"pip"` | current + negotiable render modes |
| `containerDimensions` | `{ width, maxHeight, ... }` | how much space the iframe actually has |
| `locale` / `timeZone` | BCP 47 / IANA | for formatting |
| `platform` | `"web"\|"desktop"\|"mobile"` | host surface |
| `deviceCapabilities` | `{ touch?, hover? }` | input affordances available |
| `safeAreaInsets` | `{ top, right, bottom, left }` | notch/rounded-corner clearance |

`hostContext` is not a one-shot snapshot — the Host can push updates later via
`ui/notifications/host-context-changed` carrying a `Partial<HostContext>` (theme flips,
resize, display-mode change); this is the "unsolicited Host notification" in §4's interactive-
phase table.

`hostCapabilities` is what the Host is willing to do for this View:

| Field | Meaning |
| --- | --- |
| `openLinks` | Host will open external links on the View's behalf |
| `serverTools.listChanged` / `serverResources.listChanged` | Host will forward `list_changed` notifications from the server |
| `logging` | Host accepts `notifications/message` for telemetry |
| `sandbox.permissions` | which of camera/microphone/geolocation/clipboardWrite the iframe's `allow` attribute actually grants |
| `sandbox.csp` | the CSP domain lists actually in force (echoes back what got applied from `_meta.ui.csp`, §7) |

> Vocabulary correction: `getHostContext()` is not a spec method — it's SDK sugar. The `App`
> class's `connect()` call is what sends `ui/initialize` and resolves with this exact
> `McpUiInitializeResult`; anything exposing `getHostContext()` in a debugging harness is
> reading `.hostContext` off that already-resolved object, not making a second round-trip.

Web (non-desktop) hosts insert a same-origin-isolation hop: a Sandbox Proxy iframe, a
different origin from the Host, with `allow-scripts allow-same-origin` only. It transparently
forwards every message except ones named `ui/notifications/sandbox-*`, and the Host still
can't talk to the View until the proxy is ready:

```
Sandbox Proxy → Host:  ui/notifications/sandbox-proxy-ready
Host → Sandbox Proxy:  ui/notifications/sandbox-resource-ready { html, csp?, permissions? }
```

## 4. Phase 3 — Interactive Phase

The loop, entirely View-initiated; the Host stays reactive:

| View sends | Host does | Reply |
| --- | --- | --- |
| `tools/call` | forwards to Server, streams `tool-input(-partial)` back, then `tool-result` | tool result |
| `ui/message` | may append to conversation context; **MAY request user consent** | ack |
| `ui/update-model-context` | overwrites stored model context | ack |
| `notifications/message` | logs for debugging/telemetry | none (fire-and-forget) |
| `resources/read` | proxies straight to Server | resource contents |

The Host can also push unsolicited notifications the View didn't ask for —
`ui/notifications/host-context-changed` on a theme or display-mode change — and the View can
push `ui/notifications/size-changed` back.

The SDK's `App` class (`callServerTool()`, `updateModelContext()`, `ontoolresult`, …) is a
typed wrapper over exactly these messages; nothing in the interactive phase exists outside
this table.

## 5. Phase 4 — Cleanup

```
Host → View:  ui/resource-teardown { reason }
View:         graceful termination — internal; the spec does not define a save-state API
View → Host:  ui/resource-teardown response
Host:         tears down the iframe and its listeners
```

Teardown is **Host-initiated only** — there is no `ui/close` for a View to request its own
teardown. And it is not confined to end-of-conversation: "cleanup may be triggered at any
point in the lifecycle following View initialization," so a Host resource-reallocation event
can tear down a View that is mid-interactive-phase, with no other warning.

## 6. Reload and persisted conversations: the phases replay, the view doesn't

A host reopening a past conversation — a browser refresh, a new desktop session, a Cowork
window reload — has to bring a tool-backed view back without the tool running again. The
lifecycle handles this by **replaying, not re-triggering**:

- Discovery already happened when the turn was first produced — the Host isn't re-listing
  tools for a historical message.
- Phase 2 runs again from scratch for that historical turn: a brand-new iframe, a fresh
  `ui/initialize` → `McpUiInitializeResult` → `initialized` handshake, then the Host resends
  the *same* `ui/notifications/tool-input` / `ui/notifications/tool-result` it stored from
  the original call. There is no new `tools/call` — the tool does not re-execute.

That distinction is why in-memory View state can't be trusted across a reload: the View is a
brand-new JS runtime every time, so `let`-bound variables, in-flight promises, and unsaved
edits are gone. The only thing that reliably survives is `localStorage` — and only if it's
keyed by something stable across replays. The session id is the wrong key (it comes from the
transport and may legitimately differ across reconnects); the right key is an id minted once
and carried *inside the replayed tool result itself*.

The 100x `feedback_server` example: `report_feedback` mints a `draft_id` (a UUID) into its
structured output on first call. That id is part of the historical tool result, so every
replay of that turn hands the same `draft_id` back to a fresh View. The form keys an
"already filed" flag in `localStorage` off that id, so a reload can tell "still an editable
draft" apart from "already filed — show the ticket URL, don't let the user re-file":

```
reload → fresh iframe → ui/initialize (again) → tool-result replayed (same draft_id)
                                                        │
                                        localStorage[draft_id] set?
                                     ┌────────── no ─────┴───── yes ──────────┐
                              show editable form                  show the ticket URL
```

> Lesson (inferred, not spec text): SEP-1865 never discusses reload or replay. This behavior
> falls out of two things the spec does say — tool execution and view rendering are separate
> concerns (§2), and the View has no persistent memory of its own. Anything an app needs to
> survive a reload has to be pinned to *data the Host will hand back on replay* (a result
> field), never to the view's runtime state or to the session id.

This also answers a question §5 leaves open: does `ui/resource-teardown` fire on a hard
reload? Almost certainly not — it's a request that expects a response from a live View over
an existing `postMessage` channel, and on a tab refresh or app restart the old iframe (often
the old host process too) is already gone before the "reload" happens; there's no channel
left to send it on. Treat Cleanup as covering in-app view replacement while the Host keeps
running, not process or browser restarts — those just skip straight to a new Phase 2 for
whatever turns get re-rendered.

## 7. The `ui://` resource: format, CSP, and the cache trap

The resource's `mimeType` MUST be exactly `text/html;profile=mcp-app`. Its `_meta.ui.csp`
maps declared domain lists straight onto CSP directives — omit a list and that directive
locks down to nothing:

| Field | CSP directive | If omitted |
| --- | --- | --- |
| `connectDomains` | `connect-src` | `'none'` |
| `resourceDomains` | `img-src`, `script-src`, `style-src`, `font-src`, `media-src` | same origin only |
| `frameDomains` | `frame-src` | `'none'` — no nested iframes |
| `baseUriDomains` | `base-uri` | `'self'` |

> Lesson (confirmed against the spec, not just observed behavior): the debugging note's
> fix — bump the URI on every edit of the view — is exactly what the design rationale
> predicts, not a workaround for a bug. Predeclared, URI-addressed resources exist so hosts
> can "prefetch and cache UI resource content for performance optimization" and "preload
> templates before tool execution." Caching is a Host **MAY**, and the spec defines no
> cache-invalidation mechanism for it — no ETag, no cache-control header, no version
> negotiation. Treating `ui://` URIs as immutable content addresses and manually versioning
> them (`form-v2.html`) is the only cache-busting lever the protocol gives you.

## 8. Security gates baked into the lifecycle

Four mitigations, all normative (`MUST`/`SHOULD`, not suggestions):

1. **Iframe sandboxing** — all View content MUST render in a sandboxed iframe; the sandbox
   limits the View to `postMessage`, with the Host in control of the channel.
2. **Auditable communication** — every View-to-Host exchange is a loggable JSON-RPC message;
   Host SHOULD validate and log View-initiated RPC calls for security review.
3. **Predeclared resource review** — the Host receives UI templates during connection setup,
   before any tool executes, so it can review HTML for malicious patterns and hash/allowlist
   resources ahead of rendering.
4. **CSP enforcement** — Host MUST construct a CSP from the declared domain lists and MUST
   block connections to undeclared domains; if `_meta.ui.csp` is omitted entirely, the Host
   MUST fall back to a restrictive default (`default-src 'none'`, `connect-src 'none'`, no
   external images/scripts/styles).

## 9. Reconciling with the debugging note's 7 stages

| Debugging-note stage | Spec phase / message |
| --- | --- |
| 1. HTML rendered | Phase 2 — iframe mounted from the `ui://` resource |
| 2. Module script executing | before any MCP message — spec is silent here |
| 3. SDK import (dynamic, try/catch) | same — page-load concern, not protocol |
| 4. `app.connect()` | `ui/initialize` → `McpUiInitializeResult` → `ui/notifications/initialized` |
| 5. `ontoolinput` received | `ui/notifications/tool-input(-partial)` |
| 6. `ontoolresult` received | `ui/notifications/tool-result` |
| 7. `callServerTool` round-trip | Phase 3 `tools/call` |

Stages 2–3 are outside the protocol entirely — they're why a diagnostic view that never gets
past "module script executing" is a CSP or CDN problem, not an MCP problem, and no amount of
staring at server logs will show it: the Server only ever sees the Phase-1 `resources/read`.

## References

- [SEP-1865 — MCP Apps: Interactive User Interfaces for MCP](https://github.com/modelcontextprotocol/ext-apps/blob/main/specification/2026-01-26/apps.mdx)
- [Model Context Protocol Blog — MCP Apps: Bringing UI Capabilities To MCP Clients](https://blog.modelcontextprotocol.io/posts/2026-01-26-mcp-apps/)
- [modelcontextprotocol/ext-apps](https://github.com/modelcontextprotocol/ext-apps)


# MCP App Lifecycle — Protocol Phases from Discovery to Teardown

> Reference note on how Model Context Protocol (MCP) sessions live and die, how
> interactive tool views (widgets / "MCP Apps") are wired to those sessions, and
> why a reopened conversation shows **"Client server capabilities not
> available."**
>
> **Epistemic tag:** Parts 1 and 3 are grounded in the MCP specification and are
> reliable. Part 4 (widget/app lifecycle) and the rehydration path in Part 5 are a
> *reasonable-architecture model*, not authoritative host internals. The
> spec-vs-inference boundary is called out explicitly in the last section.

---

## 0. Mental model in one line

Capabilities are **per-session**, sessions are **per-transport**, and a reopened
conversation is — from the server's point of view — a **different session or no
session at all**. Only the *static render* of an interactive view survives a round
trip through storage; its live wiring does not.

---

## 1. MCP session lifetime (protocol-level)

A **session** is a stateful logical connection over a single transport:

- **stdio** — local subprocess server.
- **Streamable HTTP** — remote server (the relevant case for hosted connectors).

It moves through discovery → initialization → operation → teardown.

### Phase A — Discovery

Before a session exists, the host has to know the server is available and reachable:

1. The server is registered/installed as a connector (URL + name), or advertised in
   a registry the host can search.
2. The host resolves the endpoint and prepares a transport.

Discovery answers *"which server, at what URL, over what transport"* — it does **not**
yet establish capabilities or a session id. Nothing is negotiated here.

### Phase B — Initialization (the handshake)

1. Client opens the transport and sends an `initialize` request carrying:
   - `protocolVersion`
   - client `capabilities` (e.g. `sampling`, `elicitation`, `roots`)
   - `clientInfo`
2. Server replies with:
   - its `protocolVersion`
   - server `capabilities` (e.g. `tools`, `resources`, `prompts`, each with
     sub-flags like `listChanged`)
   - `serverInfo` and optional `instructions`
3. Client sends the `notifications/initialized` notification. **Only now is the
   session operational.** Before this, traffic is limited (pings, logging).

Two things are pinned here **for the whole session, not per request**:

- **The negotiated capability set** — the intersection contract of what each side
  supports. Never re-negotiated mid-session. A client cannot begin using a
  capability that was not agreed at init.
- **The session identifier** — on Streamable HTTP the server MAY return an
  `Mcp-Session-Id` response header.

### Phase C — Operation

- Every subsequent request echoes the `Mcp-Session-Id` header.
- The server uses that id to look up session state, including the capabilities
  negotiated in Phase B.
- Requests, responses, and server-initiated messages flow over the live stream
  (the SSE channel inside Streamable HTTP).

### Phase D — Teardown

A session ends when any of these happens:

- the transport closes (tab/app closes the stream);
- the client sends an explicit `DELETE` with the session id;
- the server expires the session and answers a later request with **`404`**.

A `404` means *"that session id is dead — re-`initialize` for a new one."* There is
**no "reattach to session X with its old capability set"** operation. A new
connection is always: fresh handshake → fresh session id → fresh capability
negotiation.

---

## 2. Resumability nuance (don't over-read the spec)

Streamable HTTP supports **stream resumption**:

- events on the stream carry an `id`;
- a client can reconnect with the `Last-Event-ID` header to replay missed messages.

This resumes **message delivery on a still-valid session**. It is **not** a mechanism
for reconstituting a torn-down session's negotiated capabilities after the transport
is gone.

**Delivery resumption ≠ session reconstitution.** This distinction is the crux of why
reopened widgets fail.

---

## 3. Interactive tool view (widget / "MCP App") lifecycle

> Standard sandboxed-embed architecture. Shape is conventional; exact host wiring is
> inferred.

1. **Tool returns an interactive resource.** A tool call (e.g. `report_feedback`)
   returns — alongside normal content — a resource the host recognizes as renderable
   UI rather than plain text.
2. **Host renders it sandboxed.** The client mounts it in an isolated context
   (iframe / sandboxed component). The widget has **no direct access** to the MCP
   connection; it can only talk to its host.
3. **A host↔widget bridge exists.** Communication is via a message channel
   (postMessage-style). When the widget needs a side effect — e.g. the confirmation
   card invoking `submit_feedback` — it does **not** call the server. It emits an
   *intent* to the host.
4. **Host brokers the callback.** The host translates that intent into an MCP tool
   call **over the live session from Part 1**. For the host to accept and route it,
   the relevant client-server capability channel from the negotiated set must be
   **present and active**. This is the dependency the error names.
5. **Persistence is asymmetric.** What is written to conversation storage is the
   widget's *rendered/serialized output* — enough to redraw it. The live session, the
   bridge, and the negotiated capabilities are **runtime-only** and are **not**
   serialized with the message.

---

## 4. Reopening an old conversation — step by step

1. You navigate to the archived conversation. The transport that hosted the original
   session is long closed → that session was **terminated** (Phase D).
2. The app rehydrates the transcript from storage, including the widget's stored
   visual shell → it **redraws**.
3. On mount, the widget runs its startup check: it asks the host for the
   client-server capability channel it needs to route actions.
4. No live session backs this rehydrated view — either **no MCP connection is bound**
   to the restored widget at all, or a **new** session exists but the stored widget
   isn't wired into its freshly negotiated capabilities. The lookup returns empty.
5. The widget renders its failure state:
   **`Client server capabilities not available.`**
   The pixels are real; the nervous system behind them isn't.

**Consequence for stateful flows:** a draft-style widget (e.g. feedback) was **never
filed** just by drawing. Submission only happens over a *live* session. If the card
is dead on reload, the action did not go through — re-drive it from a live session
instead.

---

## 5. Engineering takeaways

- **Treat every interactive tool result as fire-once and ephemeral.** Do not assume a
  rendered widget can act after the session that spawned it ends.
- **If an action must be recoverable, persist state server-side behind a stable id.**
  Don't rely on the rendered component surviving. Example: a feedback flow whose
  `report_feedback` returns a `draft_id` lets a later live session re-fetch and
  re-drive the draft; a widget that only held state in the client would lose it.
- **Design for `404`-then-reinitialize.** Clients must handle session expiry by
  re-running the handshake, not by trying to resume dead capabilities.
- **Separate "delivery resumption" from "session reconstitution"** in your own
  reconnect logic — `Last-Event-ID` buys you the former only.
- **Idempotency on brokered callbacks.** Because a user may retry a widget action from
  a fresh session, side-effecting tool calls should be idempotent (or dedupe on a
  client-supplied key) to avoid double-submission.

---

## 6. Spec-grounded vs. inferred (boundary)

**Spec-grounded (reliable):**
- Discovery → initialize → operation → teardown lifecycle.
- Capabilities negotiated once at `initialize` and scoped to the session.
- `Mcp-Session-Id` semantics; `404` → re-initialize.
- Stream resumption via `Last-Event-ID`, and the resumption-vs-reconstitution
  distinction.

**Inferred (reasonable architecture, not authoritative host internals):**
- The specific widget sandboxing model.
- The host-brokered callback path (widget → intent → host → MCP tool call).
- Exactly what the host serializes to storage on reload and how it rehydrates.

For the precise client-side rehydration logic, consult the host team's internal
documentation rather than treating Parts 3–4 as canonical.

---

## 7. Quick reference

| Concern | Behavior |
|---|---|
| When are capabilities set? | Once, at `initialize`. Never re-negotiated mid-session. |
| Scope of capabilities | The session (bound to the transport + `Mcp-Session-Id`). |
| Session end triggers | Transport close, client `DELETE`, or server expiry (`404`). |
| Can you reattach to an old session? | No. New connection = new handshake = new id. |
| What `Last-Event-ID` gives you | Replay of missed messages on a *still-valid* session — not capability recovery. |
| What survives conversation reload | The widget's static render only. |
| What dies on reload | Live session, host↔widget bridge, negotiated capabilities. |
| Meaning of "capabilities not available" | Rehydrated widget found no live capability channel to route its action. |
| Was a draft-widget action filed by drawing? | No. Submission needs a live session. |