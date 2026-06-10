# The Agent Protocol Stack — MCP, A2A, and AGENTS.md

> **Updated 2026-06-10.** In 2026 the way agents connect to the world has
> settled into a small "layer cake" of open standards. You no longer glue every
> integration by hand. You target three protocols, each solving one job:
> **MCP** (agent ↔ tools), **A2A** (agent ↔ agent), and **AGENTS.md**
> (human ↔ agent, repo-level instructions). This note explains each layer, why
> they don't compete, and how they fit together.

---

## 1. Why a stack at all

A useful agent needs three different kinds of connection:

1. **Down to tools and data** — call an API, read a database, search files.
2. **Sideways to other agents** — hand a task to an agent owned by another
   team or another company.
3. **Up to humans** — read the instructions a developer left about *this*
   project (build commands, style, what not to touch).

For a long time everyone built these by hand, one custom adapter at a time.
That does not scale: *N* agents × *M* tools = *N×M* glue code. In 2026 each of
the three connections has **one open standard**, so you build to the standard
once and everything interoperates.

```
        ┌─────────────────────────────────────────────┐
        │                   Human                       │
        │            AGENTS.md  (repo rules)            │
        └───────────────────────┬───────────────────────┘
                                 │ reads on startup
                                 ▼
   Agent A  ◄────── A2A (agent ↔ agent) ──────►  Agent B
     │                                              │
     │ MCP (agent ↔ tools)         MCP (agent ↔ tools)
     ▼                                              ▼
  [DB] [API] [files]                        [CRM] [search]
```

**Key idea:** these are *complementary*, not rivals. MCP is the "USB-C port"
for tools. A2A is the "phone line" between agents. AGENTS.md is the "README the
agent actually obeys." Mixing them up is the most common 2026 mistake.

---

## 2. MCP — Model Context Protocol (agent ↔ tools)

**Job:** a standard way for one agent to discover and call external **tools**
and **data sources**.

- The agent connects to an **MCP server**. The server advertises a list of
  *tools* (functions the agent can call), *resources* (data it can read), and
  *prompts* (reusable templates).
- The agent picks a tool, sends arguments, gets a result. The model never needs
  custom code per integration — it just speaks MCP.

```
Agent ──"what can you do?"──► MCP server ──► [search_docs, run_sql, send_email]
Agent ──run_sql("SELECT…")──► MCP server ──► rows back
```

**Governance (important for 2026):** Anthropic **donated MCP to the Linux
Foundation in December 2025**. It is now a neutral open standard, not an
Anthropic-only thing. Google announced **managed MCP servers** across Google
Cloud at Cloud Next 2026, and frameworks like LangGraph, CrewAI, LlamaIndex,
and Semantic Kernel support it natively.

**When you use it:** any time your agent needs to reach a tool or data store.
This is the layer you will touch most often.

> Related repo note: [MCP.md](MCP.md), and the harness view in
> [11.7. Tools and MCP](../11.%20Harness%20Engineering/11.7.%20Tools%20and%20MCP.md).

---

## 3. A2A — Agent2Agent (agent ↔ agent)

**Job:** let two agents **talk to each other** even when they run on completely
different platforms, owned by different teams or vendors.

Example: a Salesforce agent hands a task to a Google Vertex AI agent, which in
turn asks a ServiceNow agent — all without anyone writing a custom bridge, and
without sharing the underlying data stores.

```
Salesforce Agent ──A2A──► Vertex AI Agent ──A2A──► ServiceNow Agent
   (task: "resolve ticket #42")    (delegates)         (looks up record)
```

How it works at a glance:
- Each agent publishes an **Agent Card** — a small description of what it can
  do and how to reach it (think "business card for an agent").
- Another agent reads the card, sends a **task**, and gets back results or
  status updates. Long tasks can stream progress.

**Governance:** A2A is governed by the **Linux Foundation's Agentic AI
Foundation** (now at v1.2) and is deployed across 150+ organizations including
Microsoft, AWS, Salesforce, and ServiceNow. It started at Google but is now
vendor-neutral, and is explicitly designed to **complement MCP, not replace
it**: MCP connects an agent to tools; A2A connects an agent to another agent.

**When you use it:** federated or cross-org systems — specialized agents owned
by different teams collaborating without giving up data sovereignty (each side
keeps its own data; only the task and result cross the line).

> Related repo note: [multi-agent.md](multi-agent.md) (single-system patterns:
> graph, swarm, workflow). A2A is the *cross-system* version of the same idea.

---

## 4. AGENTS.md — repo instructions (human ↔ agent)

**Job:** a plain-Markdown file at the repo root that tells *any* coding agent
how to work in *this* project: build/test commands, code style, directories to
avoid, conventions. It is the agent equivalent of a README aimed at humans.

- Introduced as a convention by OpenAI and now widely adopted across coding
  agents. Many tools (Claude Code's `CLAUDE.md`, Cursor rules, etc.) read it or
  an equivalent on startup.
- It is **not a network protocol** like MCP/A2A — it's a *file convention*. But
  it completes the stack: it's how a human reliably steers an agent's behavior
  without re-explaining the project every session.

```
repo/
├── AGENTS.md   ← "run `make test`; don't touch /legacy; use 2-space indent"
├── src/
└── …
```

> Related repo note:
> [11.2. Repo Memory — AGENTS.md & Friends](../11.%20Harness%20Engineering/11.2.%20Repo%20Memory%20—%20AGENTS.md%20%26%20Friends.md).

---

## 5. WebMCP — the emerging fourth layer (browser-native tools)

A newer 2026 standard worth watching. **WebMCP** lets a *website* publish
**Tool Contracts** — a list of actions the page supports (search, add to cart,
book) — so an agent can act on the site **directly** instead of screen-scraping
the HTML or reverse-engineering a private backend API.

```
Old way:  Agent ──► reads HTML ──► guesses buttons ──► clicks/scrapes (fragile)
WebMCP:   Agent ──► reads Tool Contract ──► calls publish_review() (stable)
```

It is early, but the direction is clear: the open web becomes directly
callable by agents, the same way MCP made backend tools callable.

---

## 6. How they fit together — one mental model

| Layer      | Connects        | Analogy            | Owner / status (2026)            |
|------------|-----------------|--------------------|----------------------------------|
| AGENTS.md  | human → agent   | the project README | OpenAI convention, widely adopted |
| MCP        | agent → tools   | USB-C port         | Linux Foundation (since Dec 2025) |
| A2A        | agent → agent   | phone line         | LF Agentic AI Foundation, v1.2    |
| WebMCP     | agent → website | callable web page  | open standard, emerging           |

A request flows through all of them in a real system:

```
1. Agent boots, reads AGENTS.md            → learns project rules
2. Agent needs data → calls an MCP tool    → gets the data
3. Agent can't finish alone → A2A handoff  → another agent helps
4. Task touches a website → WebMCP contract → acts on the page directly
```

---

## 7. Practical takeaways for building agents in 2026

- **Don't write custom integrations.** Pick the protocol that matches the
  connection (tool = MCP, agent = A2A, repo = AGENTS.md) and target it once.
- **MCP first.** It is the most mature and the one you will use daily. Expose
  your own tools as an MCP server so any agent can use them.
- **Reach for A2A only at the boundary.** Inside one system, normal multi-agent
  patterns (orchestrator-worker, swarm) are simpler. Use A2A when agents cross
  team/company/platform lines and data must stay put.
- **These are open and neutral now.** MCP and A2A both sit under the Linux
  Foundation, so building on them is not a bet on one vendor.
- **Watch WebMCP.** If your agent works against the public web, a callable-web
  standard removes the most fragile part of today's browser agents.

> **Bigger picture:** this stack is *one half* of agent engineering — the
> *connection* half. The other half is **context engineering** (what the agent
> sees and remembers): compaction, structured note-taking/memory, and sub-agent
> isolation. See [3. Prompt & Context Engineering](../3.%20Prompt%20%26%20Context%20Engineering/)
> and the harness notes in [11. Harness Engineering](../11.%20Harness%20Engineering/).

---

## References

- [AI Weekly: The Agent Protocol Stack Hardens (DEV, May 2026)](https://dev.to/alexmercedcoder/ai-weekly-google-reshapes-the-coding-stack-claude-pulls-ahead-and-the-agent-protocol-stack-17co) — MCP + A2A + WebMCP layer cake, governance, adoption.
- [Google Cloud Next 2026: AI agents, A2A protocol (The Next Web)](https://thenextweb.com/news/google-cloud-next-ai-agents-agentic-era) — managed MCP servers, production A2A, full-stack agent bet.
- [AI Agent Frameworks in 2026: SDKs, ACP, trade-offs (Morph)](https://www.morphllm.com/ai-agent-framework) — how frameworks adopt the protocols.
- [LLM Agent Architectures in 2026 (Future AGI)](https://futureagi.com/blog/llm-agent-architectures-core-components/) — six-layer agent architecture (model, memory, tools, planner, runtime, observability).
