# Speculative Execution in the Agent Loop — Hiding Latency with Predict-and-Verify

> **Updated 2026-06-15.** The other recent notes in this track optimise the agent
> loop on **cost** ([Small Language Models for Agents](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md))
> and **reliability** ([Durable Execution for Agents](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md)).
> This one is about **latency**. A five-step agent with 2-second tool calls takes
> 10+ seconds even when the model itself answers instantly — the wall-clock is
> spent *waiting*, not *thinking*. A 2026 line of work borrows the oldest trick in
> CPU design — **speculative execution** — and lifts it from instructions to agent
> actions: do likely-correct work *during the wait*, and verify it before you
> commit. This note explains the predict-and-verify pattern, its three concrete
> shapes (speculative planning, speculative tool calling, speculator/target), the
> correctness question that decides whether it is safe, and where it breaks.

---

## 1. Why the agent loop is latency-bound

An agent loop is **plan → call tool → observe → repeat**. Profile a real one and
the surprise is where the seconds go: not in model decode, but in the *gaps*
between steps — a tool call hitting a remote API, a code cell executing, a file
read, a human typing the next instruction. The model sits idle the whole time,
then the next step can't start until the observation lands.

This is **structurally identical** to a CPU stalling on a memory load. The fix is
the same one CPUs have used for thirty years: don't stall. Guess what comes next,
start working on the guess, and throw the work away if the guess was wrong. The
guess is cheap (idle silicon / idle GPU); the verification keeps you correct.

> **Why it matters:** latency is the number-one user complaint about agents, and
> you cannot fix it by buying a faster model — the model was never the
> bottleneck. The bottleneck is the *serialisation* of waits. Speculation attacks
> the serialisation directly, which is why it can cut perceived latency in half
> while leaving model quality untouched.

---

## 2. The core pattern: predict-and-verify

Every technique here is the same two-role idea borrowed from **speculative
decoding** (where a small draft model proposes tokens a large model verifies),
raised one level of abstraction from *tokens* to *actions*:

1. **Predict.** While the loop would otherwise block, a fast path proposes the
   likely next action(s) — a plan, a tool call, a whole next step.
2. **Execute speculatively.** Start the proposed work immediately, in parallel
   with the wait you were going to do anyway.
3. **Verify.** When the real observation (or a slower, authoritative model)
   arrives, check the speculation against it.
4. **Commit or roll back.** If the guess matches reality, you've already done the
   work — keep it, latency hidden. If not, discard it and fall back to the
   correct path. The discarded work cost only idle time.

The whole design lives or dies on **step 4 being cheap and correct**. If a wrong
guess can corrupt state or can't be cleanly undone, the trick is unsafe. If a
wrong guess just wastes some idle GPU time, it's free upside. Most of the
engineering is in keeping rollback cheap.

> **Architectural takeaway:** speculation never *improves* a correct answer — its
> ceiling is "exactly what the non-speculative agent would have done, but
> sooner." Treat it as a latency optimisation layered *under* your decision logic,
> never as a way to change decisions.

---

## 3. Three concrete shapes

The 2026 papers cluster into three designs, differing in *what* gets speculated
and *how* the wait is hidden.

### 3.1 Speculative planning — use the idle time to think ahead (IdleSpec)

The agent is waiting on a slow tool (code execution, a long retrieval). Instead of
idling, it **pre-plans the next step** against guessed observations:

- A **progressive** drafter plans assuming the *typical / expected* tool result.
- A **recovery** drafter plans for *unexpected or failed* outcomes.
- A learned distribution decides how much to sample from each, and is updated by
  posterior feedback once the real observation lands. The pre-computed candidates
  then seed the next reasoning step instead of starting cold.

This is speculation on the *reasoning*, not the side effects, so it is inherently
safe — the worst case is wasted draft tokens. On GAIA/FRAMES it lifts accuracy
~5% over a no-idle baseline (the extra thinking is pure bonus), and on
long-horizon code tasks (MLE-Bench) it gains up to ~9% because the idle windows
there are large.

### 3.2 Speculative tool calling — fire safe calls before you're sure (async I/O)

Here the agent issues **tool calls before the input is fully settled** — e.g.
while the user is still talking, or while an upstream call is in flight. The
enabling distinction is a **safety classification of every tool**:

| Tool class | Example | Speculation policy |
|---|---|---|
| **Safe** (read-only) | search, file read, GET, lookup | Execute speculatively on partial info — re-running or discarding is harmless |
| **Unsafe** (state-modifying) | payment, write, send, POST | **Hold** until a *commit point* — the real input is final |

The loop is **event-driven**: streaming inputs and tool responses are injected
into the model's context the moment they arrive, and generation is *interruptible*
(halt mid-stream, splice in the new fact, continue). When new information
invalidates an in-flight speculative call, the agent **overwrites it (same call
ID) or cancels it (REMOVE id)**, and any dependent tasks cascade-cancel. Reported
speedups: **1.6–2.2×** on small open models (Qwen2.5-3B, Llama-3.2-3B) across
tool-calling benchmarks.

> **Why it matters:** the safe/unsafe split is the whole safety argument. You only
> ever speculate work that is *idempotent and side-effect-free*; anything that
> touches the world waits for certainty. This is the same instinct as a database
> letting reads run speculatively but never committing a write until the
> transaction is sure.

### 3.3 Speculator / target — a lossless two-model framework

Generalise speculative decoding fully: a **fast speculator** proposes the next
action; a **slower, authoritative target** independently verifies it.

- Only actions the target *agrees with* execute; a mismatch falls back to the
  target's own choice.
- This makes the framework **lossless** — by construction it cannot do worse than
  running the target alone, because the target keeps final authority over every
  action.
- Speedups of **2–5×** when speculator and target agree often, degrading
  *gracefully* (not catastrophically) as agreement drops.

The natural speculator is exactly the **SLM** from the heterogeneous-architecture
note: a cheap specialist guesses, the frontier model verifies. The two
optimisations compose — small models for speed, the big model for the correctness
guarantee.

---

## 4. The correctness question — what makes it safe

Speculation is only as safe as its rollback. Three properties separate a sound
implementation from a dangerous one:

1. **Side-effect isolation.** Never speculatively run anything that mutates
   external state. Partition tools into safe/unsafe (§3.2) and gate unsafe calls
   behind a commit point. A speculatively-sent email cannot be un-sent.
2. **A real verification step.** The guess must be checked against ground truth
   (the actual observation) or an authoritative model *before* commit — not
   assumed correct. Skip this and you've just built a faster way to be wrong.
3. **Cheap, total rollback.** Discarding a wrong speculation must restore the
   exact pre-speculation state, including cascading cancellation of any dependent
   in-flight work. Same-ID overwrite and REMOVE-id semantics exist for this.

> **Architectural takeaway:** speculation and **durable execution** are two halves
> of the same discipline — both demand that the loop's state be checkpointable and
> restorable. If you've already built deterministic replay and checkpoints for
> crash-recovery, you have most of the machinery rollback needs. Build the
> [durable loop](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md)
> first; speculation rides on top of it.

---

## 5. Where it helps, where it breaks

**Speculation pays off when:**

- **Idle windows are long.** Big payoff on slow tools — code execution, long
  retrieval, multi-second APIs. Negligible on sub-100ms calls (nothing to hide).
- **Outcomes are predictable.** For coding agents, file reads almost always
  succeed; for API agents, most calls return 200. High speculation-accuracy means
  most guesses commit.
- **The workload is read-heavy.** Lots of safe, idempotent tool calls to
  speculate; few irreversible writes to block on.

**Speculation hurts or fails when:**

- **Inputs drift unpredictably.** On naturalistic speech with disfluencies,
  corrections, and mid-sentence intent changes, accuracy collapses — one paper
  found a majority of real human-instruction samples unusable, and some models
  fell into *degenerate loops* of repeated actions. Synthetic benchmarks
  flatter this technique; real conversation punishes it.
- **Side effects dominate.** A write-heavy workflow has little to speculate
  safely; you spend complexity for almost no hidden latency.
- **Rollback is expensive or partial.** If discarding a guess leaks state or
  orphans dependent work, a low hit-rate makes the agent *slower and buggier*
  than the simple serial loop.

> **Lesson:** measure your hit rate before you ship. Speculation is a bet — each
> correct guess hides latency, each wrong one burns idle compute and risks a bad
> rollback. Below some agreement threshold the bet is negative-EV and the honest
> serial loop wins.

---

## 6. How it fits the rest of the stack

Speculative execution is the **performance** layer of the same agent loop the
other notes optimise on other axes:

| Concern | Technique | Note |
|---|---|---|
| **Cost** | SLM workers, frontier consultant | [Small Language Models for Agents](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md) |
| **Reliability** | Checkpoint + deterministic replay | [Durable Execution for Agents](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md) |
| **Latency** | Predict-and-verify speculation | *this note* |
| **Quality over time** | Evolving playbook | [Agentic Context Engineering](Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md) |

They reinforce each other: the SLM is the natural cheap **speculator**, the
frontier model the **verifier**; durable-execution checkpoints are the rollback
substrate; and none of them change the agent's *decisions* — they only make the
same decisions cheaper, safer, faster, or better-informed. Build the correct
serial loop first, then layer speculation under it as a measured latency win — not
as a shortcut that trades correctness for speed.

---

## References

- [Yang et al. — IdleSpec: Exploiting Idle Time via Speculative Planning for LLM Agents (arXiv 2605.22154)](https://arxiv.org/abs/2605.22154)
- [Speculative Interaction Agents: Building Real-Time Agents with Asynchronous I/O and Speculative Tool Calling (arXiv 2605.13360)](https://arxiv.org/abs/2605.13360)
- [Speculative Actions: A Lossless Framework for Faster Agentic Systems (arXiv 2510.04371)](https://arxiv.org/abs/2510.04371)
- [Requesty — 5 AI Agent Techniques That Just Dropped This Week (May 2026)](https://www.requesty.ai/blog/ai-agent-techniques-may-2026-self-evolving-managed-compiled)
- [Leviathan et al. — Fast Inference from Transformers via Speculative Decoding (arXiv 2211.17192)](https://arxiv.org/abs/2211.17192)
