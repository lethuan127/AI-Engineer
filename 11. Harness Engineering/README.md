# 11. Harness Engineering

> Companion section to [7. AI System Architecture](../7.%20AI%20System%20Architecture/README.md). Section 7 treats the agent harness as a backend **platform you build or buy**. Section 11 treats the harness as a **practice you apply** as a consumer of an existing agent — initially a coding agent (Cursor, Claude Code, Codex CLI, Copilot CLI), then increasingly any agent that operates over a domain corpus.

Most AI engineers will never build a harness from scratch. They will spend their careers shaping the harness someone else built so it behaves correctly in *their* codebase — or *their* deal pipeline, *their* support queue, *their* portfolio dashboard. Harness engineering is that shaping discipline. Notes 11.1 through 11.11 develop it in the coding-agent context (where the primitives are clearest); note 11.12 onward transfers the same primitives to enterprise domains.

## What this section is about

A modern coding agent ships with a hard-coded loop, a built-in toolset, and a sandbox. Around that core, the vendor exposes a small number of **configuration surfaces** that let you bend agent behavior to your repository:

- **Repo memory** — root-level instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`).
- **Rules** — file-scoped instructions that fire conditionally (`.cursor/rules/*.mdc`, Claude Code project memory).
- **Skills** — packaged step-by-step procedures keyed by description (`SKILL.md`).
- **Hooks** — event-driven scripts that fire on edits, tool calls, or session lifecycle.
- **Slash commands** — user-invocable prompts with arguments.
- **Subagents** — child agents with their own context window and tool subset.
- **MCP servers** — out-of-process tool servers exposed via the Model Context Protocol.
- **Tools** — built-in, custom (per-app), and MCP-provided.
- **Context engineering knobs** — caching, compaction, attachments, file-system-as-memory.

Each is a primitive. The discipline is choosing **which one** to use for a given problem, and avoiding the obvious traps (rule sprawl, hook noise, skill drift, MCP overuse).

## Why it matters

> The same agent in two different repos is two different products.

A clean, well-engineered harness turns a generic coding agent into a **repo-specific tool**: it knows your filename conventions, your style guide, your test commands, your deploy gates. A neglected harness leaves the agent guessing, which it does badly and silently.

The cost of harness engineering is small (hours, not weeks). The cost of *not* doing it shows up as a thousand papercut "why did the agent do X" moments — every one of which is a missing rule, hook, or skill.

## Mental model

```text
                    ┌─────────────────────────────┐
                    │     Coding Agent (vendor)   │
                    │  loop · model · toolset     │
                    └──────────────┬──────────────┘
                                   │ reads
       ┌───────────────────────────┼───────────────────────────┐
       │                           │                           │
  Repo Memory               Rules / Project           Skills / Slash Commands
  (AGENTS.md)               Instructions              (procedures, prompts)
       │                           │                           │
       │                           │                           │
  Hooks ←─────── Tools ──────→ MCP Servers ──────→ Subagents
  (events)       (built-in,        (out-of-process)   (Task tool)
                  custom)
                           ▲
                           │
                  Context engineering knobs
                  (caching, compaction, attachments)
```

Section 11 walks each box and the edges between them.

## Learning path

| Note | Topic | Why it's here |
|---|---|---|
| [11.1. What Is a Harness](./11.1.%20What%20Is%20a%20Harness.md) | Definition; the harness loop; how a vendor harness differs from the platform harness in section 7 | Frame |
| [11.2. Repo Memory — AGENTS.md & Friends](./11.2.%20Repo%20Memory%20%E2%80%94%20AGENTS.md%20%26%20Friends.md) | `AGENTS.md`, `CLAUDE.md`, `.cursorrules`; precedence; what belongs where | Foundation: the file every agent reads first |
| [11.3. Rules and Project Instructions](./11.3.%20Rules%20and%20Project%20Instructions.md) | Cursor `.mdc` rules (always/auto/agent-requested/manual); Claude Code memory; scoping | Conditional context injection |
| [11.4. Skills](./11.4.%20Skills.md) | Anthropic Agent Skills standard; `SKILL.md` format; description-as-router | Packaged procedures |
| [11.5. Hooks, Permissions, and Side Effects](./11.5.%20Hooks%2C%20Permissions%2C%20and%20Side%20Effects.md) | Event hooks (afterFileEdit, preToolUse, …); allow/deny lists; secret hygiene | The dangerous primitives |
| [11.6. Slash Commands and Subagents](./11.6.%20Slash%20Commands%20and%20Subagents.md) | Commands vs subagents; parent/child context; when to dispatch | User-driven and parallel work |
| [11.7. Tools and MCP](./11.7.%20Tools%20and%20MCP.md) | Built-in / custom / MCP tool taxonomy; MCP servers, resources, prompts, sampling | The action surface |
| [11.8. Context Engineering in the Harness](./11.8.%20Context%20Engineering%20in%20the%20Harness.md) | Prompt caching, compaction, attachments, file-system-as-memory; what the harness manages vs what you manage | The expensive resource |
| [11.9. Vendor Diff Matrix](./11.9.%20Vendor%20Diff%20Matrix.md) | Cursor / Claude Code / Codex CLI / Copilot CLI side-by-side per primitive | Versioned snapshot |
| [11.10. Reference Implementation Tour](./11.10.%20Reference%20Implementation%20Tour.md) | Walkthrough of this repo's harness — every file in `.cursor/` and `.claude/`, with rationale | The worked example |
| [11.11. Operational Concerns](./11.11.%20Operational%20Concerns.md) | Versioning, drift detection, eval, multi-developer governance, CI | What changes when more than one person owns the harness |
| [11.12. Harness Engineering for Private Equity & Venture Capital](./11.12.%20Harness%20Engineering%20for%20Private%20Equity%20%26%20Venture%20Capital.md) | Same primitives re-applied to deal-intelligence agents; identity propagation; audit | Domain transfer |
| [11.13. Harness Engineering for Stock Investment](./11.13.%20Harness%20Engineering%20for%20Stock%20Investment.md) | Public-equity research and trade-proposal agents; Chinese wall; pre-trade gate; never-in-execution rule | Domain transfer |

Read 11.1 → 11.8 in order. 11.9 and 11.10 are reference material. 11.11 is for when the harness becomes a team asset rather than a personal config. 11.12 and 11.13 are the first "domain transfer" notes — same discipline, different corpus.

## How section 11 relates to section 7

| | Section 7 | Section 11 |
|---|---|---|
| Audience | Platform builder | Application engineer |
| Subject | The agent harness as a runtime | The agent harness as a configurable product |
| Example | Build/buy Claude Managed Agents, OpenAI Assistants, your own loop | Configure Cursor or Claude Code for one repo |
| Primitives | Sessions, events, sandboxes, tool dispatch | Rules, skills, hooks, MCP, slash commands |
| Operational lens | Multi-tenancy, billing, SLOs | Drift, eval, multi-developer governance |
| Cross-ref | [7.1. Claude Platform Managed Agent](../7.%20AI%20System%20Architecture/7.1.%20Claude%20Platform%20Managed%20Agent.md), [7.2. Self-Implemented Agent Harness — Components](../7.%20AI%20System%20Architecture/7.2.%20Self-Implemented%20Agent%20Harness%20%E2%80%94%20Components.md) | This section |

They are complementary tracks. A reader who studies both can move fluidly between "I am a user of an agent" and "I am the operator of an agent platform" — which is the dual perspective every senior AI engineer ends up needing.

## What this section is **not**

- **Not a tutorial for any single vendor.** Vendor specifics belong in [11.9](./11.9.%20Vendor%20Diff%20Matrix.md). The other notes deliberately stay above the vendor line.
- **Not a prompt-engineering guide.** Prompt engineering for the *model* lives in [3. Prompt & Context Engineering](../3.%20Prompt%20%26%20Context%20Engineering/README.md). Harness engineering shapes the *system around the model*.
- **Not an MCP server tutorial.** Building MCP servers is a topic in itself; this section treats them as one configuration surface among many.
- **Not evaluation methodology.** That lives in [6. Evaluation & Observability](../6.%20Evaluation%20%26%20Observability/README.md). Section 11.11 brushes it only as it pertains to detecting harness drift.
