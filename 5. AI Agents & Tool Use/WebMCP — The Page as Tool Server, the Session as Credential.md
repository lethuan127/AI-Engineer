# WebMCP — The Page as Tool Server, the Session as Credential

> Extends §5 of [The Agent Protocol Stack](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md), which listed WebMCP as an emerging fourth layer to watch. It stopped being a thing to watch. Read alongside [Computer and Browser Toolsets](./Computer%20and%20Browser%20Toolsets%20—%20Batched%20Actions%2C%20Ref%20Targeting%2C%20and%20the%20Toolset%20Shape.md) and [Agent-Native Browser Runtimes](./Agent-Native%20Browser%20Runtimes%20—%20Rebuilding%20the%20Browser%20for%20Machines%2C%20Not%20Humans.md), which attack the same problem from the client side.

On 2026-08-25 OpenAI shipped **Site tools** in the ChatGPT desktop app's built-in browser — a client implementation of WebMCP, the browser API that lets a web page register tools an agent can call. The W3C Web Machine Learning Community Group published a matching Draft Community Group Report on 2026-08-26. Chrome has been running an origin trial since Chrome 149.

The feature is easy to file as "structured tool calls instead of screen-scraping," which is true and uninteresting. The load-bearing change is where two things now live. The **tool contract** moves out of a server you operate and into the live page. The **credential** stops being a token you provision and becomes the user's already-signed-in browser session. Both moves delete work you are currently doing, and both move a trust boundary you are currently holding.

---

## 1. Three ways an agent acts on a web app

| | Server MCP | Computer/browser use | WebMCP |
|---|---|---|---|
| Where the contract lives | your MCP server | nowhere — inferred from pixels or the a11y tree | the live page, registered in JS |
| What the agent sees | `tools/list` over HTTP | screenshot or accessibility tree | `getTools()` on the document |
| Credential | OAuth token / API key you provision | whatever the browser profile carries | the user's existing signed-in session |
| Who owns correctness | you (server code) | the model (guessing the UI) | you (page code you already wrote) |
| Works headless | yes | yes | **no** — needs an open tab |
| Discovery | registry, config, catalog | n/a | **only by visiting the page** |
| Blast radius on failure | scoped by token scopes | scoped by whatever the session can do | scoped by whatever the session can do |

The row that matters is the last-but-one. Server MCP and WebMCP are not competitors on the same axis — they answer different questions. Server MCP answers *"how does an agent reach my backend from anywhere?"* WebMCP answers *"how does an agent act as this user, in this tab, right now?"*

> **Architectural takeaway:** if the action is meaningful without a user present, it belongs on an MCP server. If it only makes sense *as this signed-in person, in this session*, WebMCP is the cheaper and safer place to put it — because you never mint a credential that can outlive the tab.

## 2. The API surface

The spec puts a `ModelContext` interface on `Document`. A page registers tools imperatively:

```javascript
if (typeof document.modelContext?.registerTool === "function") {
  await document.modelContext.registerTool({
    name: "add_to_cart",
    description: "Add a product to the current user's cart.",
    inputSchema: {
      type: "object",
      properties: {
        sku: { type: "string" },
        quantity: { type: "integer", minimum: 1 }
      },
      required: ["sku"],
      additionalProperties: false
    },
    annotations: { readOnlyHint: false },
    execute: async ({ sku, quantity = 1 }) => {
      // the same function your own "Add to cart" button calls
      return await cart.add(sku, quantity);
    }
  });
}
```

Three details are worth reading carefully:

- **`execute` is your existing handler.** The point of the design is that you are not writing a parallel API. You are naming and describing code paths the UI already calls. The refactor cost is proportional to how tangled your handlers are with your view layer.
- **Registration is imperative and page-scoped**, not a static manifest. Tools come and go with page state — a `toolchange` event fires on register/unregister — so a checkout tool can exist only on the checkout page. This is progressive tool disclosure done by navigation rather than by a filtering layer, which is the same problem the [MCP roadmap](./The%20Post-Stateless%20MCP%20Roadmap%20—%20Agent%20Identity%2C%20Progressive%20Discovery%2C%20and%20One%20Transport.md) is trying to solve server-side.
- **The surface moved.** The spec is `document.modelContext`; Chrome's origin trial shipped `navigator.modelContext`. Feature-detect both if you are targeting the trial. The move from `navigator` to `document` is deliberate — tools belong to a page, not to the browser.

The spec also defines `getTools()` and `executeTool()` on the agent side, a `ModelContextRegisterToolOptions` with an `exposedTo` origin list and an `AbortSignal`, and (in the explainer) HTML `<form>` elements as a declarative tool source. ChatGPT's implementation does **not** yet support declarative form tools, and does not support tools registered in iframes — same-origin or cross-origin.

## 3. The session is the credential

This is the part with real consequences.

A server MCP integration forces you to answer a provisioning question before anything works: who mints the token, what scopes does it carry, how is it rotated, how is it revoked, and what happens when an agent fleet shares one. That question is currently unsolved well enough that agent identity is the headline item on the MCP roadmap.

WebMCP sidesteps it by not issuing anything. The `execute` handler runs in the page, under the user's cookies, behind whatever authorization your server already enforces on that endpoint. There is no new secret, no new scope model, and no credential that survives the user logging out.

> **Why it matters:** for internal tools and authenticated SaaS, this collapses the most expensive part of an integration to zero. You do not build an MCP server, an OAuth app, or a scope taxonomy. You add descriptions to functions you already ship.

The cost is symmetric and should not be understated. **You inherit the session's full authority with no attenuation layer.** A server MCP token can be scoped read-only; a browser session cannot. Whatever the signed-in user can do, a tool bug or a successful injection can do. Your only enforcement points are (a) the authorization checks already on your endpoints, and (b) the client's confirmation prompts — and (b) is not yours.

## 4. The trust boundary inverts

In server MCP, the server is a party you chose to connect. In WebMCP, the tool definitions arrive from whatever page the agent happens to be on.

OpenAI's implementation states the correct posture: website-provided tool definitions **and their results** are treated as untrusted content. Invocations are tied to the originating page, each call gets a safety review before running, and the client's existing confirmation policy still applies to consequential actions — messaging, purchases, deletions, permission changes. Users can turn site tools off entirely under Settings → Browser → Permissions.

Notice what that list implies. A tool `description` is attacker-controlled text that lands directly in the model's context. So is every string an `execute` handler returns. This is the classic indirect prompt injection surface, except the injected content now arrives pre-formatted as an authoritative tool contract rather than as page text the model might discount.

The spec has not settled the defense. The explainer lists user-confirmation-for-sensitive-tools as an **open question**, with the mechanism possibly delegated to the agent's UI or to a browser permission dialog. Today, therefore:

| Control | Owned by | Status |
|---|---|---|
| Whether tools are exposed at all | site (`registerTool`) + Permissions Policy (`self` by default) | shipped |
| Which origins may see a tool | site (`exposedTo`) | in spec |
| Whether the agent may call site tools | user, via client settings | shipped (ChatGPT) |
| Confirmation before a consequential call | **client**, not the site | client-specific, not in spec |
| Server-side authorization on the action | you | your existing code — this is the only durable one |

> **Lesson:** treat the client's confirmation prompt as a UX nicety, not a control. The only control you own is the authorization check inside `execute`'s server call. Write the tool as if the argument values came from a hostile caller, because in the injection case they did.

## 5. What it structurally cannot do

Four limits are not v1 gaps; they follow from putting the contract in the page.

1. **No headless operation.** A tab or webview must be open. Batch jobs, cron agents, and server-side pipelines cannot use WebMCP at all — that is server MCP's territory, permanently.
2. **Discovery requires arrival.** There is no registry. A client learns a site has tools by loading it. This makes WebMCP useless for planning ("which site can do X?") and useful only for execution once the agent is already there.
3. **State refactoring cost is uncapped.** The pitch is "expose the functions you already have." On an app whose handlers read from DOM state and component-local stores, there are no such functions — you write them, and now you maintain two entry points into the same behavior.
4. **No attenuation.** Covered above: there is no scoped-down mode of a logged-in session.

## 6. Adoption, and whether to care yet

Client support is one implementation deep. ChatGPT's Site tools require GPT-5.6 Sol or Terra (disabled on Luna), and are unavailable in Enterprise and Edu workspaces — which excludes most of the internal-tool audience the "no credential provisioning" argument is strongest for. Chrome's origin trial is a trial. The spec is a Community Group draft, not on the W3C Standards Track.

| If you are… | Do now | Wait for |
|---|---|---|
| Building an authenticated SaaS UI | extract 3–5 handlers into callable functions; that refactor pays off regardless of WebMCP | declarative `<form>` tools, Enterprise availability |
| Operating an MCP server | nothing changes — WebMCP does not replace you | the composition story for a site that has both |
| Building a browser agent | feature-detect `document.modelContext` and `navigator.modelContext`; prefer a declared tool over the a11y tree when present | a spec'd confirmation primitive |
| Running security review | write the injection case now: hostile `description`, hostile `execute` return value | nothing — this one is live |

> **Architectural takeaway:** the refactor WebMCP asks for — pull each user-facing action into a named function with a typed schema and a plain-English description, decoupled from the view — is the same refactor that makes an app testable, scriptable, and MCP-server-able. Do it for that reason. If WebMCP standardizes, you get the integration nearly free; if it does not, you still have the better codebase.

---

## References

- [ChatGPT Docs — Site tools](https://learn.chatgpt.com/docs/webmcp)
- [W3C Web Machine Learning Community Group — WebMCP Draft Community Group Report](https://webmachinelearning.github.io/webmcp/)
- [WebMCP Explainer and Specification Repository](https://github.com/webmachinelearning/webmcp)
- [OpenAI Developer Community — Build Agent Ready Websites with ChatGPT](https://community.openai.com/t/build-agent-ready-websites-with-chatgpt/1392588)
- [Search Engine Journal — OpenAI Adds WebMCP Site Tools To ChatGPT's Browser](https://www.searchenginejournal.com/chatgpt-adds-webmcp-support/587237/)
- [PPC Land — Chrome 149 Origin Trial Puts WebMCP In Developers' Hands](https://ppc.land/chrome-149-origin-trial-puts-webmcp-in-developers-hands-at-last/)
