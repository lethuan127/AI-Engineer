# Agent Reinforcement Trainer — RL Reward Engineering with ART and RULER

> **New 2026-07-06.** Companion to [RL Environments for LLM Agents](RL%20Environments%20for%20LLM%20Agents%20—%20Where%20Agents%20Are%20Actually%20Trained.md).
> That note answers *where* an agent is trained — the environment, harness, and
> verifier taxonomy. This one answers the two questions that decide whether the run
> actually works: **what runs the training loop** (the *trainer* — ART as the
> concrete 2026 example) and **what the reward signal actually is** (reward
> engineering — the craft of turning "did it do the job?" into a scalar the
> optimiser can chase). The reward is the part that eats the schedule: the model is
> rented, the algorithm (GRPO) is settled, but the reward function is bespoke to
> your task and it is where runs silently go wrong. The 2025–2026 shortcut —
> **RULER** — is to stop hand-writing rewards and let an LLM *rank* trajectories
> instead. This note covers the trainer, the reward design space, reward hacking,
> and when to reach for RULER versus a hand-crafted verifiable reward.

---

## 1. Reward engineering is the hard 80% of agent RL

Three things have to be true to train an agent with RL: a place to act (the
environment), an algorithm to update weights (GRPO), and a number that says how
well each attempt went (the reward). The first is a software product you build
once; the second is a solved commodity. The **reward** is the part that is unique
to your task, cannot be copied from anyone else, and determines everything the
agent learns — because **the agent optimises exactly the number you give it,
including the gaps between that number and what you meant.**

Reward engineering is the discipline of designing that number. Two named
sub-problems (from the RL literature) recur:

- **Reward engineering** — designing a reward function that *accurately reflects
  the desired outcome*. Getting the target right.
- **Reward shaping** — adding *intermediate* feedback so learning converges
  faster, without changing the true objective. Getting the *gradient* usable.

> **Why it matters:** you can rent the best base model and copy the exact GRPO
> config a lab published, and still get a worthless agent, because the one thing you
> cannot outsource is the definition of "good" for *your* task. The reward is the
> spec. A vague reward is a vague agent.

---

## 2. The trainer as a primitive — ART

Historically, running agent RL meant standing up the whole stack: an inference
server, a training loop, checkpoint plumbing, and the glue between your agent code
and the optimiser. A **trainer** collapses that into a library. **ART (Agent
Reinforcement Trainer)**, OpenPipe's open-source framework, is the reference shape
in 2026: it "improves agent reliability by allowing LLMs to learn from
experience," and its one job is to let you drop GRPO into an existing Python agent
without rebuilding the RL infrastructure.

Its defining design choice is a **client/server split**:

| Component | Runs where | Responsibility |
|---|---|---|
| **Client** | In your app | OpenAI-compatible; your agent calls it exactly like any LLM |
| **Server** | On a GPU (local or cloud) | Hides the inference + training half of the RL loop |

Because the client is OpenAI-compatible, the agent code you already wrote *is* the
rollout code — you do not port your agent into a training harness. The loop is four
steps:

1. **Inference** — your code runs the agent normally; every message is recorded
   into a **Trajectory**.
2. **Reward** — *your code* assigns a reward to each Trajectory. **This is the
   only step ART cannot do for you** — it is where reward engineering lives.
3. **Train** — the server runs a GRPO step over the scored trajectories and emits
   a new **LoRA** adapter.
4. **Repeat** — the new LoRA is loaded into vLLM and the next batch of rollouts
   runs against the improved policy.

Output is a **LoRA**, not a full fine-tune — cheap to store, cheap to swap.
Integrations reflect the "assemble, don't build" philosophy: vLLM for inference,
Unsloth for efficient training, and W&B / Langfuse / OpenPipe for the observability
you need to *see* whether the reward is doing what you think.

> **Architectural takeaway:** a trainer turns RL from an infra project into a
> function call, which moves the whole difficulty onto step 2. Once the trainer is
> a commodity, **the reward function is the only code that is yours** — and the only
> code that can sink the run.

---

## 3. The reward design space

Before RULER, step 2 meant a hand-crafted reward, and the choices there are the
substance of reward engineering. Four axes matter.

**Outcome vs process.** An *outcome* reward scores only the final result (did the
task get solved?). A *process* reward scores intermediate behaviour (did it plan,
call the right tool, produce parseable output?). Outcome rewards are honest but
sparse; process rewards are dense but gameable.

**Sparse vs dense.** Sparse rewards fire rarely (one signal at the end); dense
rewards fire often (a signal per step). Sparse is more stable and less hackable but
gives the optimiser little to grip early; dense accelerates early learning but
invites shortcuts.

| Reward shape | Signal density | Strength | Failure mode |
|---|---|---|---|
| Pure outcome (sparse) | one 0/1 at the end | honest, hard to game | little early gradient; slow to start |
| Staged / shaped | dense, per milestone | fast early learning | agent games the milestones |
| Composite (outcome + process) | mixed | best of both *if weighted right* | degenerate policy if process dominates |

**The dominance rule.** When you combine an outcome reward with process rewards,
the **outcome term must dominate**. If an intermediate metric is weighted too
heavily, the agent converges to a *degenerate policy* — it maximises the easy
sub-reward (short, well-formatted, tool-happy) and stops caring whether the task is
actually solved.

**Scale-dependence.** Reward strategy is not universal — it depends on model size.
The 2026 "comprehensive recipe" for long-horizon tool-using agents found that
**smaller models benefit from staged rewards and extra exploration, while larger
models converge efficiently on simpler dense rewards.** Copying a big lab's dense
reward onto a small model can starve it of the scaffolding it needed.

> **Lesson:** reward shaping is a loaded gun pointed at your intent. Every dense
> sub-reward you add is a new surface the agent can exploit instead of doing the
> real work. Add process rewards only when the sparse outcome reward will not train,
> keep the outcome term dominant, and delete shaping terms the moment the agent can
> stand without them.

---

## 4. Reward hacking — the failure that looks like success

Reward hacking is when the agent finds an unintended shortcut that maximises the
number without achieving the goal. Its signature is deceptive: **the reward curve
goes up fast**, which reads as a great run, while the actual behaviour degrades.
The tell in practice is a **rapid but unstable reward climb paired with collapsing
response length** — the agent has found a superficial pattern (a format trick, a
sub-reward loophole) rather than learning to reason. Fully dense and piecewise-dense
rewards are the usual culprits.

Mitigations, in rough order of reliability:

- **Prefer verifiable rewards.** A programmatic check — unit test passes, answer
  matches, invariant holds — cannot be flattered. This is RLVR, the signal behind
  DeepSeek-R1-Zero's math jump (see the [RL Environments note](RL%20Environments%20for%20LLM%20Agents%20—%20Where%20Agents%20Are%20Actually%20Trained.md)).
- **Keep the outcome term dominant** so loophole sub-rewards can't outvote the real
  goal.
- **Don't freeze a judge or a checklist.** A static rubric is a fixed exploit
  target; either keep the reward objective, or let the rubric co-evolve against the
  agent's discovered exploits.
- **Watch length and stability, not just the reward number.** A reward that spikes
  while outputs shrink is hacking, not learning.

> **Why it matters:** the reward curve is the metric you will be tempted to trust,
> and it is exactly the metric a hacking agent makes look best. Judge a run by
> held-out task success, not by the training reward.

---

## 5. RULER — skip reward engineering by ranking, not scoring

The expensive part of section 3–4 is writing and defending a bespoke reward per
task. **RULER (Relative Universal LLM-Elicited Rewards)** is the 2025 move that
sidesteps it: use an LLM-as-judge to **rank a group of trajectories** instead of
hand-defining a reward. No labelled data, no hand-crafted reward function, no human
feedback.

Mechanically it fits GRPO exactly. GRPO already runs *N* trajectories per scenario;
RULER takes that group, deduplicates the shared prefix (the identical system
prompt), and sends the *N* differing suffixes to a judge with a ranking rubric. The
judge assigns each trajectory a score in **[0, 1]** by goal achievement, and those
scores are used **directly** as the GRPO rewards.

Two insights make this sound rather than a hack:

1. **Ranking is easier than absolute scoring.** Seen side by side, an LLM judge can
   spot which trajectory is better far more reliably than it can put a calibrated
   number on one trajectory in isolation.
2. **GRPO only needs *within-group* comparability.** GRPO normalises scores by each
   group's mean and stddev, so absolute values are irrelevant — only the ordering
   inside a group matters, and ordering is exactly what a judge is good at.

The results are the surprising part. RULER-trained models **beat the best prompted
frontier model on all 4 launch tasks** (while being smaller and cheaper), and
**matched or beat hand-crafted reward functions on 3 of 4** — while cutting reward
development time by roughly **2–3×**. A general, automatic reward that ties bespoke
engineering is a strong default.

**Limits.** It is still an LLM judge, with the judge's costs and biases: group size
should stay around **4–8** (bigger groups confuse the judge), rankings get noisy
with very small groups, and API cost scales with group size and judge capability.
And it inherits the golden rule of judges — keep the judge a *different* model class
from the policy, or you train the policy's own blind spots back into it.

---

## 6. Which reward should you build?

| Situation | Use |
|---|---|
| Task has a programmatic check (tests, exact match, invariant) | **Hand-crafted verifiable reward (RLVR).** Cheapest, un-gameable, fastest signal. |
| Open-ended quality (research, writing, multi-step judgement), no clean check | **RULER.** Skip bespoke reward design; let the judge rank. |
| Verifiable core + fuzzy quality layer | **Hybrid:** verifiable outcome reward (dominant) + RULER or a rubric for the quality margin. |
| Small model that won't start learning on a sparse reward | Add **staged shaping** — then remove it once the model can stand on the outcome reward. |

> **Architectural takeaway:** the 2026 default flipped. You no longer start by
> hand-crafting a reward; you start by asking *"is there a cheap verifiable check?"*
> If yes, use it. If no, reach for RULER before you spend a week engineering a reward
> that a ranking judge would have matched. Hand-crafted rewards are now the exception
> you justify, not the default you assume.

---

## 7. How it fits the stack

This note pairs with the [RL Environments note](RL%20Environments%20for%20LLM%20Agents%20—%20Where%20Agents%20Are%20Actually%20Trained.md):
that one builds the world and the verifier; this one runs the loop over it and
designs the scalar the verifier emits.

| Piece | Concern | Where |
|---|---|---|
| Environment / verifier | *where* the agent acts and how a trajectory is checked | [RL Environments for LLM Agents](RL%20Environments%20for%20LLM%20Agents%20—%20Where%20Agents%20Are%20Actually%20Trained.md) |
| **Trainer + reward** | *what runs the loop* and *what the reward is* | *this note* (ART, RULER, reward design) |
| Run it cheaply | inference cost after training | [Small Language Models for Agents](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md) |
| Improve without retraining | inference-time self-improvement | [Agentic Context Engineering](Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md) |

The through-line with GRPO is why both the environment note and this one keep
returning to *group-relative* optimisation: because GRPO scores trajectories
relative to their group, neither RLVR nor RULER needs an absolutely-calibrated
reward — a verifiable check or a ranking judge is enough. That single property is
what made reward engineering tractable outside the frontier labs.

---

## References

- [OpenPipe/ART — Agent Reinforcement Trainer (README)](https://raw.githubusercontent.com/OpenPipe/ART/main/README.md)
- [OpenPipe ART — RULER documentation](https://art.openpipe.ai/fundamentals/ruler)
- [Comprehensive Overview of Reward Engineering and Shaping in Advancing RL (arXiv 2408.10215)](https://arxiv.org/abs/2408.10215)
- [Demystifying Reinforcement Learning for Long-Horizon Tool-Using Agents — A Comprehensive Recipe (arXiv 2603.21972)](https://arxiv.org/abs/2603.21972)
- [DeepSeek-R1 — Incentivizing Reasoning Capability in LLMs via Reinforcement Learning (arXiv 2501.12948)](https://arxiv.org/abs/2501.12948)
