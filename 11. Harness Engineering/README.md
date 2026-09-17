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
| [11.6. Slash Commands and Subagents](./11.6.%20Slash%20Commands%20and%20Subagents.md) | Commands vs subagents; clean-slate vs forked context; peer messaging; when to dispatch; cache TTL as a bet on idle time | User-driven and parallel work |
| [11.7. Tools and MCP](./11.7.%20Tools%20and%20MCP.md) | Built-in / custom / MCP tool taxonomy; MCP servers, resources, prompts, sampling | The action surface |
| [11.8. Context Engineering in the Harness](./11.8.%20Context%20Engineering%20in%20the%20Harness.md) | Prompt caching and the append-never-mutate invariant, text-summary vs server-side compaction, attachments, file-system-as-memory; what the harness manages vs what you manage | The expensive resource |
| [11.9. Vendor Diff Matrix](./11.9.%20Vendor%20Diff%20Matrix.md) | Cursor / Claude Code / Codex CLI / Copilot CLI side-by-side per primitive | Versioned snapshot |
| [11.10. Reference Implementation Tour](./11.10.%20Reference%20Implementation%20Tour.md) | Walkthrough of this repo's harness — every file in `.cursor/` and `.claude/`, with rationale | The worked example |
| [11.11. Operational Concerns](./11.11.%20Operational%20Concerns.md) | Versioning, drift detection, eval, multi-developer governance, CI | What changes when more than one person owns the harness |
| [11.12. Harness Engineering for Private Equity & Venture Capital](./11.12.%20Harness%20Engineering%20for%20Private%20Equity%20%26%20Venture%20Capital.md) | Same primitives re-applied to deal-intelligence agents; identity propagation; audit | Domain transfer |
| [11.13. Harness Engineering for Stock Investment](./11.13.%20Harness%20Engineering%20for%20Stock%20Investment.md) | Public-equity research and trade-proposal agents; Chinese wall; pre-trade gate; never-in-execution rule | Domain transfer |
| [11.14. Tuning the Harness, Not the Model](./11.14.%20Tuning%20the%20Harness%2C%20Not%20the%20Model%20%E2%80%94%20The%20Harness%20as%20an%20Optimization%20Surface.md) | The harness as an optimization surface; separating harness vs model failures; the tune-screen-repeat-regress loop; the ~10x cost economics and the capability ceiling | Cross-cutting thesis |
| [11.15. Self-Evolving Harnesses — Observability-Driven Automatic Evolution](./11.15.%20Self-Evolving%20Harnesses%20%E2%80%94%20Observability-Driven%20Automatic%20Evolution.md) | Automating the 11.14 loop: component/experience/decision observability, the falsifiable-edit contract, why structural edits transfer while prose edits don't, and what a shipped version looks like (Warp's two-skill loop) | Cross-cutting thesis |
| [11.16. Harness Engineering for Incident Response — The On-Call Agent](./11.16.%20Harness%20Engineering%20for%20Incident%20Response%20%E2%80%94%20The%20On-Call%20Agent.md) | Event-triggered triage agents; `ONCALL.md` as quantitative escalation policy; the read/act split; investigation skills distilled from transcripts; the promotable lessons log | Domain transfer |
| [11.17. The AI-Native SDLC — The Committed Artifact Chain](./11.17.%20The%20AI-Native%20SDLC%20%E2%80%94%20The%20Committed%20Artifact%20Chain.md) | The harness applied across the whole lifecycle: `intent.md` → `spec.md` → `plan.md` → diff → PR → incident record; the advisory-vs-deterministic control split; config as a tested asset; deterministic control bands with tiered model response | Cross-cutting thesis |
| [11.18. Tool Architecture — The Interface as a Behavioral Knob](./11.18.%20Tool%20Architecture%20%E2%80%94%20The%20Interface%20as%20a%20Behavioral%20Knob.md) | Tool architecture as a measured variable: consistency, recall, and step-count wins pull toward different interfaces; the null result on cognitive-scaffolding tools; canary tools as a per-model tool-selection diagnostic | Cross-cutting thesis |
| [11.19. Permission Check Integrity — Aliases, Re-Resolution, and the Capability Floor](./11.19.%20Permission%20Check%20Integrity%20%E2%80%94%20Aliases%2C%20Re-Resolution%2C%20and%20the%20Capability%20Floor.md) | Why a permission rule that matches a string can still miss the resource: alias-complete matching (allow as AND, deny as OR), re-resolution at open time, matcher/executor grammar gaps, and the subtractive capability floor | Deepens 11.5 |
| [11.20. Harness Benchmarking — Controlled Cross-Harness Evaluation](./11.20.%20Harness%20Benchmarking%20%E2%80%94%20Controlled%20Cross-Harness%20Evaluation.md) | The first controlled same-model comparison of whole harnesses: what to hold fixed, why quality clusters while cost spreads 17.5x, the harness-model cache coupling trap, turn count as the real cost driver, and preset-vs-vendor variance | Cross-cutting thesis |
| [11.21. Agent Fleet Economics — Agent-Workdays and the Intervention Ceiling](./11.21.%20Agent%20Fleet%20Economics%20%E2%80%94%20Agent-Workdays%20and%20the%20Intervention%20Ceiling.md) | What it costs to run a fleet of agents beside a team of humans: agent-workdays as a supply metric you must never target, the ~10x p50-to-p90 spread in per-seat inference spend, and the intervention rate as the number a harness change has to move | Cross-cutting thesis |
| [11.22. Agent Resources as Code — Declarative Definition, Lockfiles, and Drift](./11.22.%20Agent%20Resources%20as%20Code%20%E2%80%94%20Declarative%20Definition%2C%20Lockfiles%2C%20and%20Drift.md) | Hosted agent resources (agent, environment, memory store, deployment, skill) become reviewable files: path-as-reference with dependency ordering, the dual-hash lockfile that separates local edits from console edits, drift as a *refusal* rather than a merge, and the three unsafe edges — rename-is-create, no adoption, no state locking | Deepens 11.11 |
| [11.23. Cost-Performance Hillclimbing — Searching the Model, Effort, and Prompt Space](./11.23.%20Cost-Performance%20Hillclimbing%20%E2%80%94%20Searching%20the%20Model%2C%20Effort%2C%20and%20Prompt%20Space.md) | Cost and quality are jointly searchable, not a dial: the three coupled levers (cache hit rate, accumulated instructions, effort), the six migration anti-patterns a frontier model starts obeying literally, effort as a curve whose *shape* is the diagnostic, and the train/test hillclimb that recovers quality after a downgrade | Deepens 11.14 |
| [11.24. Server-Side Permission Arbitration — Intent Provenance and the Evaluation Record](./11.24.%20Server-Side%20Permission%20Arbitration%20%E2%80%94%20Intent%20Provenance%20and%20the%20Evaluation%20Record.md) | Per-call arbitration moved inside a hosted runtime: the three-outcome contract and why the deny must be terminal, the intent-provenance rule that decides which channel carries authority (and the relay trap it creates for multi-tenant apps), the structured evaluation record, and re-attaching a human to a remote session | Deepens 11.5 |
| [11.25. Downstream Capacity Planning — When the Agent Fleet Overloads Shared Infrastructure](./11.25.%20Downstream%20Capacity%20Planning%20%E2%80%94%20When%20the%20Agent%20Fleet%20Overloads%20Shared%20Infrastructure.md) | The third bill the fleet sends — the services downstream of it: the three multipliers that make load exponential against flat headcount, the collapsing half-life of a patch (70 → 29 → <1 days), state-in-process as the sharding blocker, and why test selection is a harness surface rather than CI plumbing | Deepens 11.21 |
| [11.26. The Agent Control Plane — Inventory, Federation, and the Confidence Gap](./11.26.%20The%20Agent%20Control%20Plane%20%E2%80%94%20Inventory%2C%20Federation%2C%20and%20the%20Confidence%20Gap.md) | The fleet-level layer no per-agent primitive covers: the five planes that couple through agent identity, standard seams (OTel/MCP/OAuth2) as the only durable attachment point, the measured 33–55 point gap between confidence and control, why asserting *absence* needs a running detector, and where federated management stops being enforcement — also available as a [Vietnamese translation](./11.26.%20The%20Agent%20Control%20Plane%20%E2%80%94%20Inventory%2C%20Federation%2C%20and%20the%20Confidence%20Gap%20%28vi%29.md) | Deepens 11.11 |

Read 11.1 → 11.8 in order. 11.19 and 11.24 both deepen 11.5 — read 11.19 right after it, or whenever you are building permission checks of your own, and 11.24 when the checks stop running on your laptop and start being made by a server with no human beside it. 11.22 deepens 11.11 the same way — read it when the harness stops being files on your laptop and starts being resources someone else's runtime holds. 11.23 deepens 11.14 — read it when you have an eval and want the search procedure that runs on top of it, or the first time you migrate a working prompt onto a stronger model. 11.25 deepens 11.21 — read it when the fleet is large enough that its *output* has become someone else's capacity problem, or before you sign a capacity plan built on headcount. 11.26 deepens 11.11 from the other direction — read it when the question stops being "is this agent configured correctly" and becomes "how many agents do we run, and who can stop one," or before anyone buys an agent governance platform. 11.14, 11.15, 11.17, 11.18, 11.20, and 11.21 are cross-cutting theses (11.18 applies 11.14's argument to the toolset specifically, and assumes 11.7; 11.20 supplies the cross-harness measurement 11.14 argues for, and is the one to read before you pick or price a harness; 11.21 moves the same cost question up a level, from one task set to a whole fleet, and is the one to read before you budget or instrument one) — read them after 11.8 and 11.11 (11.15 builds directly on 11.14; 11.17 assumes 11.4, 11.5, and 11.6). 11.9 and 11.10 are reference material. 11.11 is for when the harness becomes a team asset rather than a personal config. 11.12, 11.13, and 11.16 are the "domain transfer" notes — same discipline, different corpus.

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
