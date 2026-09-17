# Orchestration Below the API Line — When the Router Ships as a Model

> Companion to [Model Routing in the Agent Loop — Per-Step Model Selection](./Model%20Routing%20in%20the%20Agent%20Loop%20—%20Per-Step%20Model%20Selection.md),
> [Small Language Models for Agents — The Heterogeneous Architecture](./Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md),
> and [Multi-Agent Orchestration in Production](./Multi-Agent%20Orchestration%20in%20Production%20—%20Topologies,%20Token%20Economics,%20and%20Coordination%20Failure.md).
> Source: [Sakana AI — Introducing Fugu Max and Fugu Ultra v2](https://sakana.ai/fugu-max-release/) (2026-09-11).

The routing note treats model selection as something you build: signals you read,
a policy you write, a semantic-name boundary you own. Sakana's 2026-09-11 release
is the other answer — the router is trained, the pool is somebody else's, and the
whole thing is served as `model: "fugu-max"` behind an OpenAI-compatible chat
endpoint. One line in your config, no orchestration code, and the fan-out is
invisible.

That is not a packaging detail. Moving orchestration below the API line changes
what you can observe, what you can pin, and what a benchmark result means. The
capability claim is real and worth taking seriously; the operational bill is paid
in places that do not show up in a price-per-token table.

---

## 1. What "orchestrator model" actually means

Fugu is not an ensemble, a mixture-of-experts, or a gateway with a routing rule.
Per the technical report, the Fugu models are *themselves language models trained
to understand user queries and dynamically devise agentic scaffolds to solve
them* — trained via a mix of large-scale fine-tuning, evolutionary algorithms,
and RL. The scaffold is generated per query. The pool of agents it dispatches to
is open-weight and specialist models, swappable by the vendor.

So the layering is:

```text
  your harness            sessions, tools, permissions, durable state
       │  one chat-completions call
       ▼
  orchestrator model      reads the query → devises a scaffold → dispatches
       │  (invisible)
       ▼
  agent pool              open-weight + specialist models, vendor-managed
```

> Architectural takeaway: this is a *second* orchestrator, sitting underneath the
> one in your harness. Neither knows the other exists. Your loop sees a single
> completion with a single latency and a single token count; the orchestrator
> sees a query with no knowledge of your session, tools, or prior turns.

## 2. The claim that carries the release

The cost-efficiency numbers are the headline, but the load-bearing claim is the
footnote: **Fugu Ultra v2 reaches its scores without Fable 5, Fable 5.1, or
GPT-6 Astra in its pool.** If orchestration over open and specialist models
reaches frontier-adjacent output without any frontier model in the mix, then
"which lab do you depend on" becomes a tunable rather than a bet.

| | Fugu Max | Fugu Ultra v2 |
|---|---|---|
| Optimizes for | Cost-performance frontier | Peak capability on multi-step work |
| Price (per 1M in / out) | $2 / $6 | $5 / $30 |
| Claimed position | Best overall on six benchmarks incl. Terminal Bench 2.1, GPQA-D, AA-LCR, AutomationBench; expands the Pareto frontier on 7 of 10 | Best or joint-best on five of eight; top-2 on seven of eight |
| Notable margin | Output price stated as 40–60% below Sonnet 5, GPT-5.6 Terra, Kimi K3 | Chartography 48.3 vs Opus 5 27.3 and Fable 5 29.5; DeepSWE 74.3 |
| Frontier models in pool | Yes | **No** (Fable 5 / 5.1 / GPT-6 Astra excluded) |

Two caveats before this table is used for anything. `SWEFish` is Sakana's own
internal benchmark, so its appearance in both "best overall" lists is a vendor
measurement on vendor-selected tasks. And every number here is a measurement of a
*configuration* — see §4.

## 3. What you give up, stated plainly

The routing note's §7 sets a non-negotiable: log per call the selected model, the
decision rationale, token usage, latency, and outcome, because *without the
rationale you cannot distinguish a bad model from a bad route, and those have
opposite fixes.* Buying the orchestrator deletes the first two fields.

| Property | Router you own | Orchestrator you buy |
|---|---|---|
| Per-step model selection | Logged, replayable | Not exposed |
| Route rationale | Yours to emit | None |
| Cost attribution | Per target model | One blended rate |
| Model pinning | Exact model IDs | A brand name over a moving pool |
| Latency shape | Sum of steps you chose | Opaque; scaffold depth is per-query |
| Prefix-cache economics | Yours to engineer | Not yours to control |
| Data path | Providers you picked | Every provider in the pool |
| Failure triage | "Bad model" vs "bad route" | Indistinguishable |

The last row is the expensive one. When output quality regresses, a self-built
router gives you a table to look at. An orchestrator gives you a support ticket.

> Why it matters: the debugging loop for a routed system is *inspect the
> rationale, fix the policy*. Below the API line there is no rationale and no
> policy. Your only control surface is the prompt and the model string.

## 4. Non-stationarity is the real cost

A conventional model string is a pin: `gpt-6-astra` means the same weights in
October as in September, and when it does not, the vendor ships a new string. An
orchestrator model string pins the *orchestrator*, not the system. Sakana's own
framing — "a swappable pool of agents guarantees supply chain resilience by
design" — is precisely a statement that the pool changes, because that is the
feature.

Sakana is unusually explicit about this: Ultra v2's training cutoff is given as
`20260828`, and the pool exclusions are stated in a chart footnote. Read that as
the tell. Pool composition is a *result-determining parameter* that is disclosed
in prose rather than returned in an API field.

Practical consequences:

- **Benchmarks expire.** A September eval of an orchestrator describes a
  September pool. Re-run evals on a schedule, not on upgrade.
- **Regression has no diff.** When behaviour shifts and your prompt did not
  change, there is nothing to bisect.
- **Reproducibility for audit is unavailable.** If you owe someone an explanation
  of how a decision was produced, "an undisclosed pool of models, composition as
  of an unstated date" is not an answer. This rules the pattern out of regulated
  paths before performance is even discussed — see
  [8.5. The Tool-Authorization Plane](../8.%20AI%20Safety%20%26%20Ethics/8.5.%20The%20Tool-Authorization%20Plane%20—%20Write%20Scope%2C%20Attribution%2C%20and%20Audit.md).
- **You traded N vendor relationships for one.** Pool diversity is a hedge held
  by the orchestrator vendor, not by you. Your concentration risk did not drop;
  it moved and got harder to see.

## 5. Where it composes, and where it does not

The honest fit is **as a leaf**, not as a layer that replaces anything:

- 🟢 **Good fit.** High-volume, stateless, quality-tolerant request/response work
  where the cost curve dominates: bulk classification, extraction, summarization,
  first-pass drafting. You want a Pareto point, not a specific model.
- 🟡 **Conditional.** A subagent inside your own orchestrator, given a
  self-contained task with a verifiable output. The nested-orchestrator problem
  is survivable when the inner scaffold's result can be checked — postcondition
  verification, per
  [Tool-Call Reliability](./Tool-Call%20Reliability%20—%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md).
- 🔴 **Bad fit.** Anything that needs per-step control: long-running sessions with
  compaction, tool-permission gating, prefix-cache engineering, mid-turn
  steering, or an audit trail. All of these assume you know which model ran.

> Lesson: the orchestrator competes with *your model choice*, not with your
> harness. Teams that read it as "we don't need an agent framework now" are
> confusing the thing that picks the model with the thing that runs the loop.

## 6. The decision, compressed

| Situation | Do this |
|---|---|
| One model wins your whole traffic mix | Route everything to it; skip both |
| Measured per-task-group accuracy gaps, need attribution and pinning | Build the router |
| Measured gaps, cost-dominated, stateless, audit-free | Buy the orchestrator |
| Haven't measured per-task-group accuracy | Measure first — both options are guessing without it |
| Regulated or audited decision path | Neither; pin an exact model |

The prerequisite is the same as in the routing note and gets skipped just as
often: without a per-task-group accuracy table for your own traffic, you cannot
tell whether a 40–60% output-price cut is a saving or a quality cut you have not
noticed yet.

---

## References

- [Sakana AI — Introducing Fugu Max and Fugu Ultra v2: Orchestrating the Pareto Frontier](https://sakana.ai/fugu-max-release/)
- [Sakana AI — Sakana Fugu Technical Report (arXiv:2606.21228)](https://arxiv.org/abs/2606.21228)
- [NVIDIA — Route AI Agent Workloads Across Models with NVIDIA NeMo Switchyard](https://developer.nvidia.com/blog/route-ai-agent-workloads-across-models-with-nvidia-nemo-switchyard/)
