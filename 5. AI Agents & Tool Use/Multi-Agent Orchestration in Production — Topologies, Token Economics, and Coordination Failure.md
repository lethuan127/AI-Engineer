# Multi-Agent Orchestration in Production — Topologies, Token Economics, and Coordination Failure

> **Updated 2026-06-18.** The rest of this track makes a *single* agent better:
> trained ([RL Environments](RL%20Environments%20for%20LLM%20Agents%20—%20Where%20Agents%20Are%20Actually%20Trained.md)),
> faster ([Speculative Execution](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md)),
> cheaper ([Small Language Models](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md)),
> self-improving ([Agentic Context Engineering](Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md)).
> This note is about the moment you decide to run *more than one*. In mid-2025 two
> influential engineering memos drew opposite conclusions on the same week — Anthropic
> shipped a multi-agent research system that beat a single agent by 90.2%, and Cognition
> published *"Don't Build Multi-Agents."* By 2026 the field has converged on a narrow,
> opinionated answer that reconciles them. This note is that answer: the topology zoo,
> the token bill, why these systems fail (it is almost never the model), and the rules
> that actually survived contact with production.

---

## 1. The split: two memos, opposite conclusions

Both were written by serious teams, both in mid-2025, and both are still the canonical references.

| | **Anthropic — multi-agent research system** | **Cognition — "Don't Build Multi-Agents"** |
|---|---|---|
| Claim | Multi-agent beat single-agent Claude Opus 4 by **90.2%** on an internal research eval | Multi-agent fragments work; prefer a **single-threaded linear agent** |
| Why | Breadth-first research exceeds one context window; parallel subagents add reasoning capacity | Subagents can't see each other's actions, so they make **conflicting implicit decisions** |
| Cost stance | Accepts ~15× the tokens of a chat — worth it for high-value research | Pays for context continuity; compress, don't split |
| Failure example | — | A Flappy Bird build where one subagent renders a Mario background and another a mismatched bird |

These do not actually contradict. They describe **different work shapes**. Anthropic's win is on *parallelizable, read-heavy* tasks (search many sources, return findings). Cognition's warning is about *sequential, write-heavy* tasks (build one coherent artifact) where every action encodes a decision the next action must respect. The 2026 consensus is the union of the two:

> **Architectural takeaway:** Multi-agent helps when the work *fans out* (independent subproblems, read-only, results merge cleanly). It hurts when the work is a *single thread of dependent edits* — there, splitting context manufactures disagreement. The shape of the task, not the sophistication of the framework, decides.

---

## 2. What resolved in 2026: the star topology

The pattern that survived in production is narrow: **one orchestrator owning the full conversation context, fanning out to ephemeral, context-isolated subagents that return compressed summaries — with no subagent-to-subagent edges.** A star, not a mesh.

```text
                 ┌───────────────┐
        ┌────────│  Orchestrator │────────┐   owns the full conversation;
        │        │  (lead agent) │        │   plans, decomposes, synthesizes,
        ▼        └──────┬────────┘        ▼   runs the final verification pass
  ┌───────────┐   ┌───────────┐    ┌───────────┐
  │ subagent  │   │ subagent  │    │ subagent  │   isolated context each,
  │ (scoped,  │   │ (scoped,  │    │ (scoped,  │   scoped tools, mostly read-only
  │  read-only)│   │  read-only)│    │  read-only)│
  └─────┬─────┘   └─────┬─────┘    └─────┬─────┘
        └───────────────┼────────────────┘
                  compressed summaries only
              (no peer-to-peer; orchestrator merges)
```

By 2026 the major frameworks had all converged on a version of this — Anthropic's role-scoped subagents, OpenAI's Agents SDK with handoffs (nested history opt-in), Microsoft's Agent Framework (peer GroupChat demoted from flagship), LangChain's supervisor-as-tool, and Cognition itself softening into agent-*management* tooling rather than free agent swarms. The free peer mesh did **not** survive except as a tightly bounded subroutine.

> **Why it matters:** context isolation is the whole point. Subagents get scoped prompts, scoped tools, and a clean window; the orchestrator never inherits a subagent's 50k-token scratch history, only its conclusion. This is simultaneously the cost win (you don't re-pay for every subagent's full trace) and the safety/observability win (blast radius is one subagent).

---

## 3. The topology zoo

| Topology | Execution flow | Context model | Dominant failure | Verdict in 2026 |
|---|---|---|---|---|
| **Single-threaded** | One loop perceives → plans → acts | Full, continuous | Context-window overflow on long tasks | Default. Reach for more only when this breaks. |
| **Pipeline / assembly line** | Fixed DAG of stages, artifacts between | Each stage sees prior artifact | Brittle to inputs the DAG didn't anticipate | Survived for repeatable, well-typed workflows |
| **Orchestrator / hub-and-spoke** | Lead routes to isolated workers, merges | Lead = full; workers = isolated | Single hub-prompt error cascades to all workers | The default multi-agent pattern |
| **Supervisor hierarchy** | Orchestrators of orchestrators | Re-pays context at each layer | Heaviest token tax; deep telephone-game drift | Use sparingly; one level of nesting, rarely two |
| **Free mesh / swarm** | Agents hand off to each other autonomously | Fragmented, peer-to-peer | Conflicting implicit decisions (the Flappy Bird problem) | Did **not** survive as a default |
| **Bounded collaboration** | Peers, but with phase gates + an arbiter | Shared within a phase | Coordination overhead if gates are loose | Survived only when controlled |

> **Lesson:** the axis that predicts success is not "how many agents" but **"who owns the writing."** Patterns with a single writer (single-thread, orchestrator, pipeline) are stable. Patterns where several agents write into the same artifact without an arbiter (free mesh) are where the famous coordination failures come from.

---

## 4. Token economics — the 15× tax

Multi-agent is not free reasoning; it is **bought** reasoning, paid in tokens. Anthropic's own numbers anchor the budget:

- A single agentic loop already uses **~4× the tokens of a chat** (it re-reads its growing history every turn).
- A multi-agent system uses **~15× the tokens of a chat**.
- In their BrowseComp eval, **token usage alone explained ~80% of the performance variance** — number of tool calls and model choice were the only other meaningful factors.

That last finding is the uncomfortable one: a large part of "multi-agent is smarter" is really "multi-agent spent more compute, distributed across separate context windows so none of them saturated." Topology changes *where* the tokens go:

- **Independent pools** (workers share nothing) carry the least overhead — but amplify errors, because nothing reconciles their disagreements.
- **Centralized orchestration/supervisors** carry the most — every worker turn re-pays for the orchestrator's context, and hierarchies pay it again per layer.

> **Why it matters:** the economics only close for **high-value, parallelizable** work — legal due diligence, competitive intelligence, biomedical literature review — where the answer quality justifies a 15× bill. For most coding and for sequential planning, the same tokens spent on *one* better-steered agent win. Anthropic says this plainly: multi-agent is a poor fit for tasks where "all agents share the same context or involve many dependencies," and names most coding tasks as exactly that.

---

## 5. Why they fail — it is organizational, not the model

The most important empirical work here is the MAST study (*"Why Do Multi-Agent LLM Systems Fail?"*, Berkeley-led, 2025), which hand-annotated **1,600+ execution traces across 7 popular MAS frameworks** and built a **failure taxonomy of 14 modes in 3 categories**:

1. **Specification & system design** — ambiguous role definitions, poor task decomposition, duplicate roles, missing termination conditions. This is the **largest cluster (~40% of failures).**
2. **Inter-agent misalignment** — agents ignoring each other's input, derailing the task, withholding information, or acting against their own stated reasoning.
3. **Task verification** — no one checks the result, or the system terminates before it's actually done.

The headline is brutal and clarifying:

> **Why it matters:** the failures are almost never "the model wasn't smart enough." They are *organizational* — bad role specs, undefined handoffs, no verification, no stop condition. A more capable base model does not fix an underspecified org chart. This is why the 2026 winners spend their effort on the *protocol between agents*, not on swapping in a bigger model.

This reframes the whole problem. A multi-agent system is a distributed system staffed by unreliable, non-deterministic workers. The discipline it needs is the discipline of distributed systems and management — clear contracts, idempotent handoffs, explicit termination, a verification step — not prompt cleverness. (The same lens explains why [durable execution](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md) and [the agent protocol stack](The%20Agent%20Protocol%20Stack%20—%20MCP,%20A2A,%20AGENTS.md.md) matter so much once you have more than one agent.)

---

## 6. The design rules that survived

Distilled from the Anthropic system, the MAST failure modes, and the 2026 production retrospectives:

1. **Star, not mesh.** One orchestrator owns the conversation. No peer-to-peer edges unless inside a bounded, arbitrated phase.
2. **Isolate context, return summaries.** Subagents get clean, scoped windows; they hand back compressed conclusions, never their raw trace. This is the cost and the safety story at once. (See [Context Engineering in the Harness](../11.%20Harness%20Engineering/11.8.%20Context%20Engineering%20in%20the%20Harness.md).)
3. **Single writer per artifact.** If several agents must touch one output, gate it through an arbiter. Conflicting implicit decisions are the Flappy Bird failure.
4. **Specify roles and stop conditions explicitly.** The plurality of failures is underspecification. Each subagent needs a sharp objective, scoped tools, and a defined "done."
5. **Right-size the fan-out.** Anthropic's rule of thumb: simple fact-find = 1 agent / 3–10 tool calls; comparison = 2–4 subagents; broad research = 3–5. Don't spawn agents you can't justify in tokens.
6. **End with a verification pass.** A dedicated checker (e.g. a citation/consistency pass) catches the "no one verified the result" failure class.
7. **Start single-threaded.** The strongest 2026 heuristic is negative: **most teams reach for multi-agent too early and pay 15× for it.** Exhaust a well-steered single agent first; escalate only when context overflow or genuine parallelism forces your hand.

---

## 7. Decision: when to actually reach for it

| Signal | Single agent | Multi-agent (orchestrator + isolated subagents) |
|---|---|---|
| Work shape | One thread of dependent edits | Independent subproblems that fan out |
| Read vs write | Write-heavy (build one artifact) | Read-heavy (gather, then merge) |
| Context budget | Fits, or fits with compaction | Genuinely exceeds one window |
| Value per task | Routine / latency-sensitive / cost-sensitive | High-value, quality dominates cost |
| Coordination need | High inter-step dependency | Low — results combine cleanly |
| Example | Coding, sequential planning, ops runbooks | Deep research, due diligence, lit review |

> **Mental model:** treat a multi-agent system as **hiring a team, not buying a smarter brain.** Teams beat individuals only on work that genuinely parallelizes, and only when the work is specified, the handoffs are clean, and someone reviews the result. On a single coherent task with tight dependencies, one focused operator beats a committee — and costs 15× less. The frontier question of 2026 is not "single or multi?" but "does this work fan out, and can I afford the team?"

---

## References

- [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Cognition — Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents)
- [Cemri et al. — Why Do Multi-Agent LLM Systems Fail? (MAST)](https://arxiv.org/abs/2503.13657)
- [Multi-Agent in Production 2026 — The Patterns That Survived](https://niteagent.com/blog/multi-agent-production-2026/)
- [AWS Strands — Multi-Agent Patterns: Graph, Swarm, Workflow](https://strandsagents.com/docs/user-guide/concepts/multi-agent/multi-agent-patterns/)
