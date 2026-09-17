# Model Routing in the Agent Loop — Per-Step Model Selection

> **Added 2026-08-14.** Companion to
> [Small Language Models for Agents — The Heterogeneous Architecture](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md),
> which argues *that* a heterogeneous agent should exist and draws a box labelled
> "Router". This note opens that box. NVIDIA's **NeMo Switchyard** (open source,
> 2026-08-11) is the first release to publish a router *taxonomy* rather than a
> single heuristic, along with third-party numbers on what routing actually buys
> and what it costs. Treat the vendor framing as one instance of a general design
> problem: routing is a control-plane decision, and the interesting questions are
> which signals it reads, when it reads them, and what it does when it is wrong.
>
> This note is the *build* side. For the buy side — orchestration trained into a
> model and sold behind a chat-completions endpoint, which deletes §7's logging
> contract along with the code — see
> [Orchestration Below the API Line — When the Router Ships as a Model](Orchestration%20Below%20the%20API%20Line%20—%20When%20the%20Router%20Ships%20as%20a%20Model.md).

---

## 1. The premise: no model dominates every step

The single-model agent is a modelling convenience, not a fact about workloads. On
Terminal-Bench Hard with the Terminus agent, NVIDIA's per-task-group breakdown
shows the highest-accuracy model overall — DeepSeek V4 — losing two of nine task
groups: Kimi K2.6 leads on ML and RL, Qwen3.5 397B A17B leads on math and
science. Six groups go to the overall winner. Two do not.

Cost makes the picture worse, not simpler. Each model has its own verbosity
profile — not just output tokens but *tool calls*, which multiply round-trips.
A model that is 3 points more accurate and twice as chatty may be strictly worse
on a loop that runs for an hour.

> **Why it matters:** an agent step is not a request for the best answer. It is a
> request for an answer *good enough to keep the loop moving*, at the lowest cost
> that clears that bar. Those are different objectives, and only the second one
> is sensitive to which model you pick.

---

## 2. Three signal families

Every router, however implemented, reads from three sources.

| Signal family | What it answers | Concrete signals |
|---|---|---|
| **Model capability** | Which models *can* solve this correctly? | Request topic classification, estimated difficulty, embedding features, logprobs, residual stream, agentic trace |
| **Cost profile** | What does each candidate charge, in money and latency? | Per-token price, prompt/output verbosity, tool-call count, p50/p95 latency |
| **Infrastructure** | Can the handoff actually happen right now? | Endpoint load, provider availability, error rates, session state |

Where you *read* those signals is a separate axis from which ones you use:

- **Look at the request.** Cheapest. A classifier or embedding model derives
  topic and difficulty from the prompt alone, before any inference.
- **Look at the model.** Logprobs, cascades, the residual stream, attention —
  richer, but requires you to run (or at least prefill) a model to get the
  signal, so the router now has an inference cost of its own.
- **Look at the system.** Pricing, load, latency, and agent-specific error
  signals. Free to collect, but tells you nothing about correctness.

---

## 3. The axis most designs get wrong — *when* and *where* to route

Signal choice is the visible decision. The load-bearing one is placement.

| Question | Option A | Option B | Consequence |
|---|---|---|---|
| Granularity | Route the whole request once | Route every step | Per-step wins on heterogeneous tasks; costs a decision per turn |
| Pool scope | One shared model pool | Per-subagent specialised pools | Shared is simpler; per-subagent lets you tune each role independently |
| Route state | Stateless per call | Session-affine (carry the decision forward) | Stateless re-decides constantly and thrashes; affinity risks sticking to a bad early choice |

Session affinity is the underrated one. Re-classifying identical work on every
turn of a twenty-turn task burns a judge call per turn and produces decision
churn — the model flips mid-task, and the new model inherits a context written in
another model's voice. Switchyard's answer is to let the router carry state
across a session (an affinity decision, earlier tool results) and to make
statelessness an explicit opt-out rather than the default.

> **Architectural takeaway:** the router is a stateful component in a system that
> mostly pretends its components are stateless. Design its state — and its
> invalidation rules — deliberately, or the agent will thrash between models
> and you will debug it as a model-quality problem.

---

## 4. Router families

Switchyard splits routers into **tuning-free** (work on day one, no workload data)
and **tunable** (learn from your traffic). The split is the useful part; the
specific implementations are one vendor's picks.

| Router | Signal read | State | Adapts? | Fits |
|---|---|---|---|---|
| **LLM classifier** | Request text, judged by an LLM | Session affinity after first classification | No | Headless, domain-partitioned work (route coding / math / healthcare to fixed targets) |
| **Stage router** | Recent *tool activity* on this turn | Per-turn, reads history | Reactive | Coding agents that move through phases — exploration, error recovery, mechanical implementation |
| **Escalation router** | LLM judge watching turn-by-turn progress | Session, one-way promotion | Yes | Multi-turn work where a small model handles the routine case and needs rescue on sustained difficulty |
| **Prefill router** (tunable) | LLM residual stream → shared-trunk MLP predicting per-model success | Per-request | Learned offline | High-volume traffic where you can afford to label accuracy per model |

Two of these are worth dwelling on.

**The stage router is the interesting design.** It does not read the prompt. It
reads what the agent has *been doing*: severe errors, repeated unproductive work,
or prolonged exploration push the turn toward the capable model; steady writes
and edits — especially once tests pass — favour the efficient one. Inconclusive
signals fall back to an LLM judge, then to a configured default. That is a
router built on trajectory telemetry rather than on the request, which makes it
the only one of the four that could not exist outside an agent loop.

**The escalation router is the stage router's honest cousin.** Start cheap,
promote on sustained difficulty, never demote. One-way promotion is a deliberate
simplification: demoting mid-task means handing a hard problem back to the model
that already failed at it.

**The prefill router is where the cost shows up.** Estimating query complexity
from the residual stream means you have already prefilled a model to make a
routing decision. That is defensible at volume and wasteful below it.

---

## 5. What it actually buys — two third-party measurements

Vendor benchmarks on vendor models are worth little. These two are not.

**LangChain**, on its internal deep-agents suite — 145 multi-turn agentic tasks
drawn from τ²-bench airline, the Berkeley Function Calling Leaderboard, FRAMES,
and Nexus, covering tool use, multi-step retrieval, filesystem operations, and
long-context summarisation — routed between Nemotron 3.5 Lightning and Claude
Opus 4.8 with the escalation router:

- **74% cost reduction** versus a frontier-only baseline, across five runs
- **7% of calls** reached the frontier model
- **~6-point accuracy tradeoff**

**Cognition**, running Switchyard's staged-routing methodology in Devin Desktop
against FrontierCode Main, routing between Opus 5 and Kimi K2.7:

- **50.6% accuracy at $3.11 mean cost**
- within **2.8 points** of Opus-5-only accuracy
- at roughly **28% lower mean cost**

Read those two together. The escalation result is a *cost* result — a 74% cut
that you pay for with six accuracy points. The staged result is a *frontier-parity*
result — near-frontier quality, modest savings. Same library, opposite operating
points. Which one you want is a product decision, and routing is the knob, not
the answer.

> **Lesson:** "routing saves money" is not a claim you can evaluate. Routing moves
> you along an accuracy-cost frontier. Pick the point first; then pick the router
> that reaches it.

---

## 6. The execution-layer model this assumes

Routing down only pays if there is somewhere good to route *to*. Nemotron 3.5
Lightning is NVIDIA's answer for that slot — the smallest member of the Nemotron 3
family, released the same day as Switchyard:

- **30B mixture-of-experts, 3B active** — capacity of a larger dense model at the
  compute cost of a small one
- **Harness-optimised training** — trained against agent harnesses (OpenClaw,
  Hermes Agent) rather than on chat transcripts, which is the point: the
  execution layer's job is tool calls, result validation, and subagent
  delegation, not conversation
- **Speculative decoding baked in** — multi-token prediction pretrained, plus
  DSpark and DFlash draft models for different concurrency regimes
- **NVFP4 and BF16 checkpoints**, same file from DGX Spark to data centre
- **OpenMDW-1.1** — weights, training data, and recipes released, so the model is
  fine-tunable rather than merely callable

Claimed result: leading accuracy at the highest output speed in its class on the
Artificial Analysis Intelligence Index, and 86% on PinchBench while completing
10,000 tasks 30% faster than Qwen3.6 35B at comparable accuracy.

> **Why it matters:** "harness-optimised training" is the shift worth noticing.
> A model trained to be a good execution-layer citizen is a different artifact
> from a model trained to be a good assistant, and the heterogeneous architecture
> only works when someone builds the former. See
> [Speculative Execution in the Agent Loop](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md)
> for the decoding-side mechanics.

---

## 7. Building it — the boundary that matters

Switchyard's structural decision is to separate the routing contract from the
provider:

```text
  application
      │  (unchanged; OpenAI / Anthropic / Responses API shape)
      ▼
 ┌─────────────────────┐
 │  router             │  reads signals → emits a *semantic model name*
 └─────────┬───────────┘
           │  "fast-executor" | "frontier-planner"
           ▼
 ┌─────────────────────┐
 │  target client      │  maps semantic name → provider endpoint + model ID
 └─────────┬───────────┘
           ▼
   provider (open / proprietary / self-hosted)
```

Routers emit *semantic names*; a target client maps those to endpoints. Swapping
a provider, moving an endpoint, or upgrading a model version touches the mapping,
not the routing logic. The router can also decline to make the call and hand the
decision back to the host application — so an existing agent runtime or gateway
keeps control of serving while reusing the routing contract.

The observability requirement is not optional. A routed system must record, per
call: **selected model, decision rationale, token usage, latency, and outcome.**
Without the rationale you cannot distinguish a bad model from a bad route, and
those have opposite fixes.

---

## 8. Where routing does not pay

- **Homogeneous workloads.** If one model wins every task group in your traffic,
  the router is pure overhead plus a new failure mode.
- **Low volume.** A judge-based router adds an inference call per decision.
  Below some traffic threshold the routing infrastructure — evaluation harness,
  per-model accuracy labels, target-client plumbing — costs more than the tokens
  it saves.
- **Tight latency budgets.** Classifier and judge routers sit on the critical
  path. A prefill router sits on it twice.
- **Low error tolerance.** A misroute sends a hard task to a weak model. If the
  cost of one wrong answer exceeds the savings across a thousand right ones,
  route everything to the frontier model and stop.
- **You have not measured per-task-group accuracy.** Routing without that table
  is guessing with extra steps.

---

## References

- [NVIDIA — Route AI Agent Workloads Across Models with NVIDIA NeMo Switchyard](https://developer.nvidia.com/blog/route-ai-agent-workloads-across-models-with-nvidia-nemo-switchyard/)
- [NVIDIA — Nemotron 3.5 Lightning Delivers Fast, Accurate Specialized Task Execution for Long-Running Agents](https://developer.nvidia.com/blog/nvidia-nemotron-3-5-lightning-delivers-fast-accurate-specialized-task-execution-for-long-running-agents/)
- [NVIDIA NeMo Switchyard — Source Repository](https://github.com/NVIDIA-NeMo/Switchyard)
