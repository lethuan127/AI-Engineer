# The Post-Stateless MCP Roadmap — Agent Identity, Progressive Discovery, and One Transport

> **Source:** the MCP Core Maintainers' updated roadmap, published
> **2026-08-22** — [blog post](https://blog.modelcontextprotocol.io/posts/mcp-roadmap/)
> and [roadmap document](https://modelcontextprotocol.io/development/roadmap).
> Companion to
> [MCP Goes Stateless — The 2026-07-28 Release Candidate](./MCP%20Goes%20Stateless%20—%20The%202026-07-28%20Release%20Candidate.md),
> which covers the release this roadmap builds on. For the layer cake see
> [The Agent Protocol Stack](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md);
> for the harness view see
> [11.7. Tools and MCP](../11.%20Harness%20Engineering/11.7.%20Tools%20and%20MCP.md).

A roadmap is normally the least interesting artifact a standards body produces. This one
is worth reading because of *what it concedes*. The `2026-07-28` release made a remote MCP
server an ordinary HTTP workload — that solved scaling. The new roadmap names the four
things statelessness did not solve, and three of them are problems every team currently
solves with private glue: authenticating an agent that has no human behind it, keeping a
hundred tool schemas out of the context window, and knowing which field of a tool result
the model will actually see. The protocol is moving to absorb that glue.

---

## 1. The delta from March is the signal

The [March 2026 roadmap](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/)
had four priorities — transport scalability, agent communication, governance, enterprise
readiness — and an "On the Horizon" list of things maintainers were happy to support but
were not standing up. Five months later, three horizon items are top-line priorities.

| March 2026 | August 2026 | Read |
|---|---|---|
| Transport evolution & scalability (priority) | Shipped as `2026-07-28`; now "unification and hardening" | The stateless bet paid off; the work moved from *design* to *collapse the second transport* |
| Governance maturation (priority) | Gone from the list | WGs are now the delivery vehicle, not a goal |
| Enterprise readiness (priority, "least defined") | Became "Agent identity and enterprise-ready security" | The vague enterprise bucket resolved into a concrete identity problem |
| Deeper security & authorization (horizon) | Priority: DPoP, Workload Identity Federation, ID-JAG, RFC 8693 token exchange | Promoted |
| Triggers & event-driven updates (horizon, "needs a WG") | Priority: server-initiated events, Triggers & Events WG exists | Promoted, WG formed |
| Streamed / reference-based result types (horizon) | Priority: `tools/call` result-shape redesign | Promoted |

> **Why it matters:** the March roadmap said "these need a community WG to form." The
> August roadmap says "the WG formed and here are the deliverables." That is the actual
> maturity signal — not the feature list, but the fact that the horizon list drained.

---

## 2. Agent identity is the load-bearing item

This is the area with the most direct consequence for anything you are building now. The
maintainers state the problem plainly: MCP authorization assumes a person with a browser
at consent time, and existing servers "lean on pasted API keys and long-lived refresh
tokens." Three caller shapes break that assumption:

```text
1. Cloud workload with its own identity        — no human, ever
2. Agent acting for an absent user             — human consented once, months ago
3. Sub-agent spawned by a parent agent         — needs *narrower* authority than parent
```

Case 3 is the one no current deployment handles honestly. When an orchestrator fans work
out to subagents, the subagents almost always inherit the parent's full token, because
there is no standard way to mint a reduced one. The roadmap's answer assembles existing
IETF machinery rather than inventing anything:

| Building block | What it buys |
|---|---|
| **DPoP** (SEP-1932) | Proof-of-possession binds a token to a key, so a stolen bearer token is no longer sufficient |
| **Workload Identity Federation** (SEP-1933) | A cloud workload authenticates as *itself*, no pasted secret |
| **ID-JAG** via [Enterprise-Managed Authorization](https://modelcontextprotocol.io/extensions/auth/enterprise-managed-authorization) | The org's IdP is the policy decision point; central grant and central revocation |
| **RFC 8693 token exchange** | The mechanism for parent → sub-agent attenuation |
| **Human-presence attestation** (under discussion) | A server can tell an interactive client from a headless agent and price/gate accordingly |

> **Architectural takeaway:** design your agent's credential model around *exchangeable,
> attenuable, key-bound* tokens now, even if you implement it privately. Everything on
> this list assumes you can name a distinct identity per agent and per delegation hop. An
> architecture where the whole fleet shares one API key cannot adopt any of it without a
> rewrite.

The ID-JAG flow is also the answer to a question that keeps recurring in enterprise
deployments: how do you offboard someone from forty MCP servers at once? You revoke at
the IdP, and the client can no longer obtain an ID-JAG to exchange. Per-server revocation
never scaled.

---

## 3. Progressive discovery — the protocol absorbs a harness hack

The roadmap's framing: "servers need more options to guide clients through large sets of
tools," so a server can "offer a small entry point and reveal more of its catalog as the
conversation narrows."

Every serious harness already does some version of this, because the arithmetic is
brutal: a JSON Schema for one tool is rarely under 300 tokens, ten servers at twenty tools
each puts six figures of tokens in the system prompt before the user types, and tool
selection accuracy *degrades* as the list grows. The workarounds in the wild —
search-a-tool-index meta-tools, category gating, per-task allowlists — are all
client-side, all bespoke, all invisible to the server that actually knows its own
taxonomy. See [tool-search-tool.md](./tool-search-tool.md) and
[tool call - filtering strategy.md](./tool%20call%20-%20filtering%20strategy.md) for the
client-side versions.

Moving discovery server-side changes who owns the decision:

| Where discovery lives | Who knows the taxonomy | Cost of being wrong |
|---|---|---|
| Client-side filter (today) | Client guesses from tool names/descriptions | Silent capability loss — the model never learns the tool exists |
| Model-visible search tool (today) | Client index, model drives | An extra round-trip per discovery hop |
| Server-side progressive discovery (roadmap) | Server, authoritatively | Server versioning burden; needs cache semantics to not re-fetch constantly |

The roadmap explicitly couples progressive discovery to the caching work, which is the
right instinct — a catalog you reveal incrementally is worthless if the client re-walks it
every turn. Watch for whether the design lets a *deterministic* subset be cached, because
non-deterministic tool lists destroy downstream LLM prompt caching.

---

## 4. Tool result shape — an ambiguity that produced diverging clients

`tools/call` can return both `content` and `structuredContent` in the same response, and a
server author has no way to know which one a given client will put in front of the model.
This is a small spec gap with an outsized failure mode: your server works against one
client and silently loses information against another, and you find out from a
hallucination rather than an error.

The Core Primitives WG is redesigning the interface to a single contract. Related:
applying content **annotations** (audience, priority) to tool results and resources, or
deprecating annotations outright if implementers continue to ignore them.

> **Lesson:** "the response may carry the same data in two shapes, client's choice" is not
> a flexibility feature, it is an untested matrix. If you author servers, pick one shape
> and populate it consistently until the contract lands.

---

## 5. One transport, and caching that reaches tool calls

Two items that look like plumbing and are not.

**HTTP over stdio.** Today every HTTP-native feature needs a second stdio-specific design
or it does not work locally, SDKs carry two transport pipelines, and protocol metadata is
duplicated between HTTP headers and message fields that servers must cross-validate. The
proposal is Streamable HTTP as the single binding, spoken over stdin/stdout — specifically
HTTP/2 over stdio, to get multiplexing while keeping the subprocess security and lifecycle
model. Collapsing two bindings into one is the cheapest reliability win available to the
SDK layer.

**ETags on tool call results.** `2026-07-28` added `ttlMs` and `cacheScope` to list
results and resource reads. Extending to ETags means *versioning primitive results,
including tool calls* — a conditional-request path for expensive idempotent tools. Pair
this with the idempotency discipline in
[Tool-Call Reliability](./Tool-Call%20Reliability%20—%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md):
an ETag is only meaningful for a call whose result is a function of its arguments.

---

## 6. Agentic messaging: the composition risk, stated out loud

MCP has grown three separate answers to "the server isn't done yet" — Tasks,
`subscriptions/listen`, and progress notifications — spread across different Working
Groups. The roadmap names the risk directly: three answers "that don't share a lifecycle,
a cancellation model, or an error surface."

Deliverables are server-initiated events (webhooks and channels, so clients stop polling)
and a **composition review** across the Agents, Transports, and Triggers & Events WGs.
[SEP-2663 Tasks](https://modelcontextprotocol.io/seps/2663-tasks-extension) continues
toward eventual inclusion in the core protocol.

> **Why it matters:** a protocol accumulating overlapping async primitives is how you get
> the situation where cancelling a long tool call works one way inside a Task, another way
> on a subscription, and not at all on a progress stream. Scheduling a composition review
> before shipping the fourth primitive is the discipline most protocols skip.

---

## 7. SDKs as generated artifacts

The last priority area is the most unusual: generate a candidate Tier-1 SDK and its
quickstarts *from the specification*, validate against the conformance test suite, and
publish findings on which layers should be deterministic codegen versus model-assisted.
Spec-clarity issues surfaced by generation failures get treated as documentation bugs.

The stated motivation is worth quoting in substance: many developers now build MCP clients
and servers by pointing an agent at the libraries, so clear APIs and accurate docs decide
whether the generated code works. The spec's readability has become a runtime dependency
of everyone else's agents.

---

## 8. Governance as a mechanism, not a virtue

SEPs inside the five priority areas get expedited review; outside them, "expect a longer
queue and a higher bar." Each area names responsible Core Maintainers and a Working Group.
SEP-2133 lets any group experiment in an `experimental-ext-` repository before writing a
formal SEP.

This is the practical read for anyone with an idea for MCP: the roadmap is a routing
table. Find your area, bring the WG, or expect to wait.

---

## 9. What to do now

| You are… | Act now | Wait for the spec |
|---|---|---|
| **Server author** | Pick one of `content`/`structuredContent` and be consistent. Keep tool order deterministic and set `ttlMs`/`cacheScope`. Design a coarse "entry point" tool surface you could reveal progressively later. | Progressive discovery mechanism; ETag semantics; the new result contract |
| **Client / harness author** | Stop assuming one identity per fleet — thread a distinct principal per agent and per delegation hop. Keep your client-side tool filtering, but make it swappable. | Server-side discovery; DPoP; human-presence attestation |
| **Platform / infra owner** | Wire MCP auth through your IdP now (ID-JAG path) rather than distributing per-server API keys. Budget for HTTP/2-over-stdio in local server tooling. | Workload Identity Federation; unified transport |
| **Anyone running long tool calls** | Use Tasks, but isolate your cancellation and error handling behind your own interface — the three async primitives are about to be reconciled. | Composition review; Tasks moving into core |

The through-line: `2026-07-28` made MCP scale. This roadmap is about making it *trustable*
— an agent that can prove who it is, a tool catalog that does not cost a context window,
and a result contract with one interpretation. Those are the three things you currently
paper over with private code.

---

## References

- [Model Context Protocol — The New MCP Roadmap](https://blog.modelcontextprotocol.io/posts/mcp-roadmap/)
- [Model Context Protocol — Roadmap Document](https://modelcontextprotocol.io/development/roadmap)
- [Model Context Protocol — The 2026 MCP Roadmap](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/)
- [Model Context Protocol — Enterprise-Managed Authorization Extension](https://modelcontextprotocol.io/extensions/auth/enterprise-managed-authorization)
- [Model Context Protocol — SEP-2663: Tasks Extension](https://modelcontextprotocol.io/seps/2663-tasks-extension)
- [Model Context Protocol — The 2026-07-28 Specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
</content>
</invoke>
