# RL Environments for LLM Agents — Where Agents Are Actually Trained

> **Updated 2026-06-16.** The other recent notes in this track make an *already-trained*
> agent cheaper ([Small Language Models](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md)),
> faster ([Speculative Execution](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md)),
> and better over time without retraining ([Agentic Context Engineering](Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md)).
> This one is upstream of all of them: it is about *how the agent's behaviour is
> produced in the first place*. The 2026 consensus is that you cannot prompt your way
> to a reliable long-horizon agent — you have to **train** it, and training needs a
> place to act, fail, and be scored. That place is an **RL environment**. The slogan
> doing the rounds in 2026 captures the shift: enterprises stop asking *"which model
> is best?"* and start asking *"which environment did you train it in?"* This note
> defines what an RL environment actually is, the reward problem at its centre, the
> stateless/stateful split, the three-phase training architecture, and where it breaks.

---

## 1. The shift: from prompting to environments

Static datasets and one-shot benchmarks were enough when the unit of work was a
single completion. They are not enough for an agent that takes 5–600 actions, calls
tools, and carries state. You cannot label a 200-step trajectory by hand, and you
cannot write a prompt that anticipates every operational constraint it will hit. So
the frontier labs moved the unit of learning from *examples* to *experience*: the
agent acts inside a simulated world, and a **verifier** scores the trajectory. The
gradient comes from the agent's own attempts, not from human demonstrations.

An RL environment is, in the words of the 2026 trend reports, a **"compressed version
of reality"** — historical data, synthetic user journeys, and mock APIs that mirror
the real failure modes of a workflow, wrapped so an agent can be run against it
thousands of times overnight.

> **Why it matters:** this is the single biggest reframing of agent engineering in
> 2026. The moat is no longer the base model (everyone rents the same few) — it is the
> environment you built to train against your domain. Forward-deployed engineers,
> domain experts, and policy teams now encode business constraints *as reward
> functions and scenario libraries* rather than as documentation an agent will ignore.

---

## 2. Anatomy of an RL environment: E = {T, H, V, S, C}

A useful 2026 taxonomy formalises an environment as five parts:

| Symbol | Part | What it specifies |
|---|---|---|
| **T** | Tasks | What the agent is asked to do, and how it's parameterised |
| **H** | Harness | How the agent interacts — rollout protocol, tool set, context management |
| **V** | Verifier | How a trajectory is scored into a reward |
| **S** | State | What persists across actions and across episodes |
| **C** | Configuration | Knobs that can *evolve during a run* (difficulty, error rates, limits) |

**Tasks (T)** span at least nine categories — single-turn Q&A, multi-hop search,
open-ended research, agentic tool-use, stateful enterprise workflows, code
generation, code review/repair, repository-level coding, and productivity workflows.
They vary on **horizon** (1 to 600+ actions), tool diversity, and token budget.

**Harness (H)** is where most engineering hides. It fixes the rollout protocol
(single-turn → multi-turn → tool-use → stateful tool-use → fully agentic), the tool
taxonomy (retrieval, extraction, code execution, file ops, browser automation, task
management), and the **context-management strategy** — recency retention, Markovian
reconstruction, or reference-preserving summarisation/folding. A subtle trap: some
tools are **non-deterministic** (live web search) and some **deterministic** (file
ops); non-determinism in the harness leaks into the reward and makes training noisy.

> **Architectural takeaway:** the environment *is* a software product, with the same
> rigour as any other — versioned tasks, a deterministic-where-possible harness, and a
> verifier you can trust. Benchmarks and training environments share these components,
> so the design principles that make a good benchmark make a good training
> environment, with one difference: a training environment may **mutate its own
> configuration** mid-run to keep the agent on the edge of its competence.

---

## 3. The reward problem: verifiable beats judgeable

The verifier (V) is the heart of the environment, because the agent will optimise
*exactly* what you measure — including the gaps. 2026 practice recognises roughly
eight verifier types, on a spectrum from cheap-and-rigid to flexible-and-gameable:

| Verifier | Signal | Notes |
|---|---|---|
| Exact match | binary 0/1 | math answers, canonical strings |
| Code execution | binary or partial | unit tests; partial credit per passing test |
| LLM-as-judge | continuous [0,1] | flexible, but expensive and spoofable |
| Checklist | multi-criteria | one point per satisfied requirement |
| **Evolving rubric** | continuous | co-evolves to resist reward hacking (RLER) |
| Process reward model | per-step | credit assignment along the trajectory |
| Pairwise comparison | relative | rank trajectories instead of scoring them |
| Multi-criteria composite | weighted sum | combine several of the above |

The dominant principle: **verifiable beats judgeable.** Programmatic checks (does the
test pass? does the answer match?) are faster, cheaper, and far more consistent than
asking a model to judge — and they cannot be flattered. This is **RLVR**
(RL from Verifiable Rewards): the environment itself provides the signal, no learned
reward model needed. The canonical proof point is **DeepSeek-R1-Zero**, which used
RLVR alone (GRPO over verifiable math/code) to lift AIME 2024 pass@1 from **15.6% to
71.0%** (86.7% with majority voting) — *no supervised fine-tuning, no human reward
model*, just verifiable rewards at scale.

When the task is genuinely open-ended (research quality, writing), you fall back to a
judge — but the smart move is **relative** scoring (**RULER**): an LLM ranks a *group*
of trajectories rather than scoring each absolutely, because the trainer
(group-relative optimisation) only needs the ordering, and ordering is far more robust
to a judge's miscalibration than absolute scores are.

> **Lesson:** static rubrics get gamed. If your verifier is a fixed checklist or a
> frozen judge prompt, the agent will eventually learn to satisfy the *letter* of it
> while missing the *intent* — reward hacking. Either keep the reward programmatic and
> objective, or let the rubric co-evolve against the agent's exploits. And keep the
> judge model a *different class* from the policy model, or you train a feedback loop
> that rewards the policy's own blind spots.

---

## 4. Stateless vs stateful — the hardest axis

Statefulness (S) is what separates a toy environment from an enterprise one.

- **Stateless** — each episode starts fresh, no memory of prior runs. A coding agent
  solving isolated LeetCode-style problems needs none. Easy to parallelise, easy to
  reset, cheap to verify.
- **Stateful** — state persists *across actions* (a DB the agent mutates) and even
  *across episodes* (an enterprise account that accumulates history). Reference
  enterprise environments expose on the order of **hundreds of database tables and
  500+ tools**, with deliberate **5–10% error injection** so the agent learns to
  recover, escalate, and retry rather than assume a clean world.

Stateful environments are where the real value is — and where almost all the
difficulty lives. Resets must restore exact state; verification must reason over a
*history*, not a single answer; and bugs in state management silently corrupt the
reward signal. This is the same checkpoint/replay discipline the
[durable-execution note](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md)
demands of production loops — here it is a *training* requirement.

---

## 5. The training architecture: env def → rollout → optimization

Labs converge on a three-phase loop, and on keeping the three phases as **separate
processes** so each can scale and be swapped independently:

1. **Environment definition** — system prompt + task input fix the scenario; the
   system prompt often *is* the implicit reward specification.
2. **Rollout generation** — the policy model produces **N trajectories per scenario**
   (4–8 is the sweet spot: fewer than 4 gives too little contrast, more than 8 hits
   diminishing returns). Each trajectory is scored by the verifier.
3. **Optimization** — a group-relative algorithm turns scored trajectories into a
   weight update.

The pivotal infrastructure change is **GRPO replacing PPO**. PPO needed *four* models
resident in memory (policy, reference, reward, critic); GRPO needs *two* (policy,
reference), because it computes advantage as each trajectory's score relative to its
group's mean/stddev — no learned critic, no learned reward model.

| | PPO (pre-2025) | GRPO (2025+) |
|---|---|---|
| Models in memory | 4 (policy, reference, reward, critic) | 2 (policy, reference) |
| Reward source | trained reward model | direct verification or LLM judge |
| Score type | absolute | relative within the group |

> **Architectural takeaway:** group-relative optimisation is *why* RLVR and RULER both
> work — neither needs an absolutely-calibrated reward, only a way to rank trajectories
> within a group. That single simplification is what made agent RL affordable enough to
> escape the big labs. The decoupling of trainer / inference / environment into
> separate processes is the other half: it lets you reuse one environment across many
> training runs and serve it to others.

This is also why **environments are becoming a hosted product**. Managed offerings now
serve **330+ RL environments as API endpoints backed by 4.5M+ tasks** with autoscaled
sandboxes, auto-generated environments cost on the order of **~$4 each**, and an
**Open Reward Standard** is emerging so environments are portable across training
stacks — the same standardisation arc tools went through with
[MCP](The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md).

---

## 6. Where it breaks

- **The sim-to-real gap.** An environment is a *compressed* reality; an agent that
  masters the simulation can still fail on the messy live system. Mock APIs that never
  rate-limit, never return malformed data, and never go down train an agent that
  assumes a perfect world. Inject failures, or ship a fragile agent.
- **Reward hacking.** The agent optimises the verifier, not your intent. Any
  exploitable gap between the two *will* be found given enough rollouts. Prefer
  verifiable rewards; co-evolve rubrics; never freeze a judge prompt.
- **State-management bugs poison silently.** A reset that leaks state or a verifier
  that misreads history corrupts the gradient without ever throwing an error — the run
  just quietly learns the wrong thing.
- **Diversity, not scale, drives breadth.** Ten thousand near-identical tasks teach
  less than a few hundred genuinely varied ones. Capability breadth comes from
  *environment diversity*, so coverage of real scenarios matters more than task count.

> **Lesson:** the environment is now the artefact you most have to get right. A
> mediocre model in a faithful, well-verified environment beats a frontier model
> trained against a leaky simulation with a gameable reward. Build the environment with
> the same care — versioning, determinism, failure injection, honest verification — that
> you would give production code, because it is the thing that actually shapes how your
> agent behaves.

---

## 7. How it fits the rest of the stack

This note sits *upstream* of the rest of the agent track — it is how the policy gets
its behaviour before any inference-time optimisation applies:

| Stage | Concern | Note |
|---|---|---|
| **Train** | produce the policy | *this note* — RL environments + verifiable rewards |
| **Cost** | run it cheaply | [Small Language Models for Agents](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md) |
| **Latency** | run it fast | [Speculative Execution](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md) |
| **Reliability** | survive crashes | [Durable Execution for Agents](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md) |
| **Quality over time** | improve without retraining | [Agentic Context Engineering](Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md) |

The relationship to ACE is the sharpest: RL environments improve the agent by changing
its **weights** (slow, expensive, done once); ACE improves it by evolving a written
**playbook** at inference time (fast, cheap, continuous). They are the two ends of the
self-improvement spectrum, and a 2026 production agent typically uses both — trained in
an environment, then kept current with an evolving context.

---

## References

- [A Taxonomy of RL Environments for LLM Agents (Han Chung Lee, Mar 2026)](https://leehanchung.github.io/blogs/2026/03/21/rl-environments-for-llm-agents/)
- [How Top AI Labs Are Building RL Agents in 2026 (Daily Dose of Data Science)](https://blog.dailydoseofds.com/p/how-top-ai-labs-are-building-rl-agents)
- [2026 Trends Report: RL Environments (Invisible Technologies)](https://invisibletech.ai/2026-trends/rl-environments)
- [Reinforcement Learning Environments and How to Build Them (Unsloth)](https://unsloth.ai/blog/rl-environments)
- [DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning (arXiv 2501.12948)](https://arxiv.org/abs/2501.12948)
