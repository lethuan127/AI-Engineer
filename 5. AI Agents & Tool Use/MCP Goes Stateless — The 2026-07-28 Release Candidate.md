# MCP Goes Stateless — The 2026-07-28 Release Candidate

> **Source:** the official MCP spec changelog (draft → `2026-07-28`), locked
> 2026-05-21, final publication 2026-07-28. This note covers what the release
> candidate changes for people who *build* MCP servers, clients, and the
> gateways in between. For the high-level layer cake (MCP vs A2A vs AGENTS.md)
> see [The Agent Protocol Stack](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md);
> for the harness view see
> [11.7. Tools and MCP](../11.%20Harness%20Engineering/11.7.%20Tools%20and%20MCP.md).

---

## 1. The one change that matters: the session is gone

The headline is that **MCP is now stateless at the protocol layer**. Two things
disappear from the Streamable HTTP transport:

- the `initialize` / `notifications/initialized` handshake (SEP-2575), and
- the `Mcp-Session-Id` header and the protocol-level session it keyed (SEP-2567).

Before, a client opened a connection, negotiated version and capabilities once,
got a session id, and every later request rode that session. That forced two
costs on anyone scaling MCP: **sticky routing** (a request had to return to the
instance that owned its session) and a **shared session store** if you wanted to
spread load. Both are now unnecessary at the protocol layer.

In the new model every request is self-contained. Protocol version, client
identity, and client capabilities travel in `_meta` on *each* request:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "run_sql",
    "arguments": { "query": "SELECT 1" },
    "_meta": {
      "io.modelcontextprotocol/protocolVersion": "2026-07-28",
      "io.modelcontextprotocol/clientInfo": { "name": "my-agent", "version": "3.1" },
      "io.modelcontextprotocol/clientCapabilities": { "extensions": [] }
    }
  }
}
```

> **Why it matters:** any MCP request can now land on any server instance behind
> a plain round-robin load balancer. The protocol stopped assuming a connection
> has memory. That is the difference between "a long-lived RPC session" and "an
> HTTP endpoint you can put N replicas behind" — the same shift REST made years
> ago, arriving late but arriving.

Version selection moves to a new RPC: servers **MUST** implement `server/discover`
to advertise supported protocol versions, capabilities, and identity. Clients
**MAY** call it up front to pick a version, or use it as a compatibility probe on
stdio. A version mismatch returns `UnsupportedProtocolVersionError`.

---

## 2. State doesn't vanish — it becomes a visible handle

Stateless protocol does **not** mean stateless servers. It means state stops
hiding inside the connection and becomes an explicit, server-minted **handle**
passed as an ordinary tool argument. If a server needs cross-call state (a cursor,
an upload id, a transaction), it returns an opaque token and the client passes it
back next time.

| Old (hidden state) | New (explicit handle) |
|---|---|
| Session id keys server-side state | Server mints a handle, returns it in the result |
| Client implicitly "is in" a session | Client passes the handle as a tool argument |
| State lifetime = connection lifetime | State lifetime = whatever the server decides |
| Invisible to gateways and logs | Visible in the payload, traceable |

> **Architectural takeaway:** this is strictly better for observability and for
> the agent's own reasoning. The model can *see* the handle it is threading
> through calls instead of relying on an invisible session it has no token for.

---

## 3. Server-to-client traffic was rebuilt

A stateless core breaks the old "server pushes a request down the open
connection" pattern. Two replacements:

**Multi Round-Trip Requests (MRTR, SEP-2322).** Server-initiated calls
(`roots/list`, `sampling/createMessage`, `elicitation/create`) are gone. Instead a
server answers with an `InputRequiredResult` (`resultType: "input_required"`)
whose `inputRequests` array names what it still needs. The client **retries the
original request** with `inputResponses` filled in. Because the retry carries
everything, any instance can finish it. To support this, **every result now
carries a required `resultType` field** — `"complete"` or `"input_required"`;
results from older servers that omit it are treated as `"complete"`.

**Opt-in change streams.** The HTTP `GET` endpoint and
`resources/subscribe`/`unsubscribe` are replaced by a single `subscriptions/listen`
— one long-lived POST-response stream the client opts into per notification type
(`toolsListChanged`, `promptsListChanged`, `resourcesListChanged`,
`resourceSubscriptions`). Request-scoped notifications (`notifications/progress`,
`notifications/message`) still flow on the response stream of the request they
belong to. SSE stream **resumability is removed**: a broken stream loses the
in-flight request and the client re-issues it with a new request id. `ping`,
`logging/setLevel`, and `notifications/roots/list_changed` are also removed.

---

## 4. Routing and caching become first-class

Two minor changes punch above their weight for infrastructure:

- **Header-based routing.** Streamable HTTP POSTs now require `Mcp-Method` and
  `Mcp-Name` headers (SEP-2243). A gateway can route, rate-limit, and log on the
  *operation* without parsing the JSON body. Custom headers can be driven from
  tool parameters via `x-mcp-header`.
- **Cache hints.** `tools/list`, `prompts/list`, `resources/list`,
  `resources/read`, and `resources/templates/list` now return `ttlMs` (freshness
  hint, ms) and `cacheScope` (`"public"` | `"private"`) via a `CacheableResult`
  interface (SEP-2549), modeled on HTTP `Cache-Control`. Servers **SHOULD** also
  return tools in a deterministic order so client-side caches — and downstream LLM
  prompt caches — actually hit.

> **Lesson:** the spec is being shaped so that an MCP request looks, to a load
> balancer, like an ordinary cacheable HTTP request. That is what "production
> grade" means for a protocol — not new features, but boring infrastructure
> compatibility.

---

## 5. Extensions, Tasks, MCP Apps

The core shrinks; optional capability moves into a formal **Extensions
framework**. Extensions get reverse-DNS identifiers
(`io.modelcontextprotocol/tasks`), independent versioning, and a new `extensions`
field on `ClientCapabilities`/`ServerCapabilities` for negotiation.

- **Tasks** (`io.modelcontextprotocol/tasks`, SEP-2663) left the core protocol and
  became an extension. The blocking `tasks/result` is replaced by polling via
  `tasks/get`; `tasks/update` lets the client feed input to a running task;
  `tasks/list` is gone; and a server may hand back a task handle unsolicited (no
  per-request opt-in). This is the protocol's answer to long-running tool calls
  without holding a connection open.
- **MCP Apps** is an official extension for server-rendered UI in sandboxed
  iframes — a tool can return an interface, not just text/JSON.

---

## 6. Authorization hardening

A cluster of SEPs tighten the OAuth 2.0 / OpenID Connect story for the
multi-server world a stateless protocol creates:

- Clients **MUST** validate the `iss` parameter against the recorded issuer before
  redeeming an authorization code (SEP-2468, per RFC 9207).
- Clients **MUST** declare an appropriate `application_type` during Dynamic Client
  Registration to avoid OIDC redirect-URI conflicts (SEP-837).
- Credentials are bound to the issuing authorization server: key them by issuer,
  never reuse across servers, re-register when the AS changes (SEP-2352).
- OTel trace context (`traceparent`, `tracestate`, `baggage`) gets documented
  `_meta` conventions (SEP-414).

With no session to anchor a token to, **authorization is now validated per
request** — verify the token, check scopes against the operation, respond. There
is no connection lifecycle to hang refresh logic on.

---

## 7. Deprecations and the feature lifecycle

The RC also introduces MCP's first formal **feature lifecycle**: Active →
Deprecated → Removed, with a **minimum twelve-month deprecation window** and a
public registry of deprecated features (SEP-2596).

| Deprecated feature | Suggested migration |
|---|---|
| **Roots** | Pass directories/files via tool parameters, resource URIs, or server config |
| **Sampling** | Call the LLM provider API directly |
| **Logging** | `stderr` (stdio) or OpenTelemetry |
| **HTTP+SSE transport** (deprecated since `2025-03-26`) | Streamable HTTP |
| **OAuth Dynamic Client Registration** | Client ID Metadata Documents |

Sampling and Roots removal is the philosophically interesting one: it narrows MCP
back to *tools and data*, and pushes "let the server call a model" out to direct
provider integration. MCP stops trying to be a model-routing layer.

---

## 8. What it means for builders

| You are… | What to do |
|---|---|
| **Server author** | Stop relying on session id. Mint explicit handles for any cross-call state. Implement `server/discover`. Add `resultType` to every result; support MRTR if you ever needed to ask the client for input. Return `ttlMs`/`cacheScope` and deterministic tool order. |
| **Client / SDK author** | Put version + identity + capabilities in `_meta` on every request. Drop the handshake. Handle `input_required` results by retrying with `inputResponses`. Re-issue on broken streams (no resumability). Migrate off Sampling/Roots. |
| **Gateway / infra owner** | You can finally treat MCP like HTTP: round-robin across replicas, route on `Mcp-Method`/`Mcp-Name`, cache list responses by `cacheScope`. Drop sticky sessions and the shared session store. |

The ten-week window (RC locked 2026-05-21 → final 2026-07-28) is for SDK
maintainers to validate against real workloads; Tier-1 SDKs are expected to ship
support inside it. If you run MCP in production, the migration is real but
mechanical — and it removes the two things (sticky routing, session stores) that
made MCP awkward to scale.

---

## References

- [The 2026-07-28 MCP Specification Release Candidate](https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/)
- [MCP Specification — Key Changes (draft changelog)](https://modelcontextprotocol.io/specification/draft/changelog)
- [Agentic AI Foundation — MCP Is Growing Up](https://aaif.io/blog/mcp-is-growing-up/)
- [SEP-2567 — Remove protocol-level sessions](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2567)
- [SEP-2575 — Stateless protocol and server/discover](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2575)
- [SEP-2322 — Multi Round-Trip Requests](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2322)
- [SEP-2596 — Feature lifecycle and deprecation policy](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2596)
</content>
</invoke>
