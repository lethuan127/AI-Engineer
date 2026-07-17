# MCP Apps Debugging — The Staged Diagnostic View and the URI Cache Trap

> **Source:** a real debugging session (2026-07-15) on the 100x `feedback_server`
> (FastMCP + MCP Apps confirmation form), cross-checked against the official
> [`modelcontextprotocol/ext-apps`](https://github.com/modelcontextprotocol/ext-apps)
> examples (`say-server`, `basic-host`). Symptom: the app UI that used to render
> now hangs on the host's loading spinner forever, with **zero** error surfaced
> anywhere — not in the host, not in the server logs.

---

## 1. The problem shape: a pipeline with invisible stages

An MCP App only renders after a chain of stages succeeds, and the host shows the
same "loading…" spinner no matter **which** stage died:

```
tool call → host reads ui:// resource → iframe mounts HTML
  → module script runs → SDK import (CSP gate) → app.connect() handshake
  → ontoolinput / ontoolresult delivered → (user acts) → callServerTool round-trip
```

Server logs only see the first hop (`resources/read`). Everything after runs in
a sandboxed iframe you can't open devtools on in most hosts. So "the UI is not
working" is ~7 different bugs wearing the same spinner.

## 2. The debug harness: a staged diagnostic app next to the real one

This is a **temporary debugging harness, not a production fixture** — end users
should never see a `test_mcp_app` tool. Gate it behind an env flag (or delete
it after the hunt):

```python
if os.environ.get("FEEDBACK_DEBUG_APP") == "1":
    # diagnostic tool + view register only in debug runs
```

When enabled, it adds a trivial tool + view to the same server, registered
**exactly** like the real one (same mime `text/html;profile=mcp-app`, same
`meta={"ui": {"resourceUri": ...}}` + legacy `"ui/resourceUri"` key, same SDK
version, same CSP allowlist) — the say-server pattern reduced to a checklist:

```python
@mcp.tool(meta={"ui": {"resourceUri": TEST_URI}, "ui/resourceUri": TEST_URI},
          structured_output=True)
async def test_mcp_app(message: str = "ping") -> dict: ...   # echoes, writes nothing

@mcp.resource(TEST_URI, mime_type="text/html;profile=mcp-app",
              meta={"ui": {"csp": {"resourceDomains": ["https://esm.sh"]}}})
def diagnostics_view() -> str: ...
```

The view renders each stage as a ✅/❌/⏳ line and dumps raw payloads
(ready-to-use copy: [`mcp-app-diagnostics.html`](./mcp-app-diagnostics.html) —
rename the `test_mcp_app` round-trip target and match the SDK version to the
app under debug):

1. **HTML rendered** — static text, no JS needed. Proves the host fetched the
   `ui://` resource and mounted the iframe.
2. **Module script executing.**
3. **SDK import** — use a *dynamic* `await import(...)` in try/catch, not a
   static import: a static import failure (CSP block, CDN outage) kills the
   whole module silently; a dynamic one prints the error on the page.
4. **`app.connect()`** — the handshake the host's spinner actually waits on.
   On success, dump `getHostContext()`.
5. **`ontoolinput` received** (raw payload shown).
6. **`ontoolresult` received** (raw payload shown).
7. **`callServerTool` round-trip** — a button that calls the diagnostic tool
   itself.

Because it shares every layer with the real app, the diff is diagnostic: if the
test app renders and the real one doesn't, only the real view's *content* or
*URI* can be at fault; if neither renders, it's host/transport/registration.

## 3. The actual culprit: hosts cache `ui://` views by URI

The session's punchline. Diagnostic app: all 7 stages green. Real form
(byte-identical SDK import, same connect pattern): infinite spinner. The only
remaining variables were the tool and the view URI — and the answer was:

> **Hosts cache the `ui://` resource keyed by its URI.** Iterate on the HTML
> behind a stable URI and the host keeps serving the stale cached copy — a
> broken revision stays broken *after* you fix it, on that URI, indefinitely.
> A brand-new URI is always fetched fresh (which is exactly why the diagnostic
> view worked on first try).

Fix: version the URI and bump it on every edit of the view:

```python
# Hosts cache ui:// views by URI — bump the suffix on every form.html edit.
FORM_URI = "ui://feedback/form-v2.html"
```

One constant, referenced by both the tool `meta` and the `@mcp.resource`
decorator, so tool and resource can't drift. `form-v2` rendered immediately.

This is the web's cache-busting lesson (`app.js?v=42`, content-hashed bundles)
re-learned in a protocol where nothing *tells* you there's a cache: no
cache-control header to set, no devtools network tab to see the 304-equivalent.
Treat `ui://` URIs as immutable content addresses, not mutable paths.

## 4. The bisect method, generalized

When a working and a broken app coexist on one server, everything they share is
exonerated. What remains is a 2×2 you can cross in seconds:

| | real view URI | fresh/test view URI |
| --- | --- | --- |
| **real tool** | broken (observed) | → renders? content/URI is the bug |
| **test tool** | → still broken? tool/result shape is the bug | works (observed) |

Point the real tool's `meta.ui.resourceUri` at the test view (or vice versa)
and one tool call tells you which axis carries the bug. In this session the
URI-swap alone (v2) fixed it, confirming the cache hypothesis without even
needing the cross.

## 5. Rules worth keeping

- **Keep a staged diagnostic tool + view behind a debug flag** (off by
  default — it's a debugging harness, not part of the product's tool surface).
  ~100 lines, writes nothing, and converts "spinner forever" into "stage 4
  failed with this error" the moment you flip the flag.
- **Version `ui://` URIs; bump on every view edit.** Stale cache is
  indistinguishable from every other failure.
- **Dynamic-import the Apps SDK in try/catch** so CSP/CDN failures print on the
  page instead of dying silently.
- **Same-register the diagnostic and the real app** (mime profile, meta keys,
  SDK version, CSP) — a diagnostic that differs from production diagnoses
  nothing.
- New conversation when re-testing: hosts may also pin tool *metadata* per
  conversation, not just view content.
- The official local harness is `ext-apps/examples/basic-host` — useful when
  you need devtools access to the iframe; the in-host diagnostic is still the
  ground truth for surface-specific behavior (claude.ai vs Desktop vs Cowork).
