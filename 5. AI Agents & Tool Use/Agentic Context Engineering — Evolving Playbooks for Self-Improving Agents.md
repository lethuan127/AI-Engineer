# Agentic Context Engineering — Evolving Playbooks for Self-Improving Agents

> **Updated 2026-06-13.** Most "self-improving agent" stories assume you change
> the *weights*: fine-tune, RLHF, distil. **Agentic Context Engineering (ACE)**
> — Stanford + SambaNova, ICLR 2026 — argues you can get most of the gain by
> improving the *context* instead. The agent keeps a written **playbook** of
> strategies and failure modes, and that playbook grows and refines itself from
> the agent's own execution feedback, with no labelled data and no retraining.
> The headline: a smaller open-source model running ACE matches a top
> proprietary production agent on the AppWorld leaderboard. This note explains
> the mechanism, why naive "let the model rewrite its own prompt" fails, and the
> numbers. It pairs with
> [Agent Memory Architectures](Agent%20Memory%20Architectures%20—%20Tiered%2C%20Vector%2C%20Temporal-Graph.md)
> (where the playbook lives) and
> [Context Engineering in the Harness](../11.%20Harness%20Engineering/11.8.%20Context%20Engineering%20in%20the%20Harness.md)
> (what the harness does to the context window).

---

## 1. The reframing — weights vs. context

There are two places an agent can store what it has learned:

| | **Weight space** | **Context space (ACE)** |
|---|---|---|
| What changes | Model parameters | The text the model reads each turn |
| How | Fine-tune / RL / distil | Append + edit a written playbook |
| Cost to update | GPU hours, a training run | A few extra LLM calls per task |
| Auditable? | No — opaque tensors | Yes — you can *read* what it learned |
| Reversible? | Re-train / roll back a checkpoint | Delete a bullet |
| Needs labels? | Usually | No — uses execution feedback |

ACE's claim is that for **agentic** and **domain-knowledge** tasks, most of what a
model lacks isn't capability — it's *context*: the API quirks, the house rules,
the "last time we did X it broke because Y." That knowledge is text. So write it
down, in a structured form the model can keep extending.

> **Why it matters:** context-space learning is *online*. The agent improves
> between task #3 and task #4, not between training run v1 and v2. And because the
> learned artifact is human-readable, you can inspect, edit, or veto it — a
> property no fine-tune gives you.

---

## 2. The two failure modes it's built to beat

Naive "let the agent maintain its own notes" almost always degrades. ACE is
designed around the two reasons why:

- **Brevity bias.** Every step that summarises the context to keep it short
  drops detail. Over many iterations the model optimises for a *concise* prompt,
  and concision quietly deletes the exact edge-case knowledge that was the point.
  A short, clean playbook is a *worse* playbook.
- **Context collapse.** If each update *rewrites the whole context*, errors
  compound. One bad rewrite drops a section; the next rewrite is now anchored on
  the damaged version. Detail erodes monotonically. The paper shows a single
  monolithic-rewrite agent collapsing from a rich context to a near-empty one in
  a handful of steps, with accuracy falling off the same cliff.

> **Architectural takeaway:** the enemy is the **full rewrite**. Any design where
> "update the context" means "regenerate the whole context with an LLM" inherits
> both failure modes. The fix is to never rewrite the whole thing.

---

## 3. The architecture — Generator, Reflector, Curator

ACE splits the work of learning across three roles so that no single LLM call
ever owns the whole context. This is the same instinct as separating *doing* from
*grading* from *bookkeeping*.

```text
        task / query
             │
             ▼
      ┌────────────┐   reasoning trace (what worked, what broke)
      │ Generator  │ ───────────────────────────────┐
      └────────────┘                                 ▼
             ▲                                 ┌────────────┐
             │ reads playbook                  │ Reflector  │  critiques trace,
             │                                 └─────┬──────┘  extracts lessons
      ┌──────┴───────┐                               │ (may iterate)
      │   PLAYBOOK    │ ◄── deterministic merge ──┐   ▼
      │ (itemized     │                           │ delta bullets
      │  bullets)     │                     ┌──────┴─────┐
      └───────────────┘                     │  Curator   │  distils lessons into
                                            └────────────┘  compact delta entries
```

- **Generator** runs the actual task using the current playbook, producing a
  reasoning trace that surfaces both the strategies that helped and the pitfalls
  it hit.
- **Reflector** critiques that trace and extracts concrete lessons — optionally
  refining them over a few iterations. This is the "what should we have known?"
  step.
- **Curator** distils those lessons into a small set of **delta** bullets and
  merges them into the playbook using **non-LLM, deterministic logic** — not a
  generative rewrite.

> **Why it matters:** the Curator's merge is plain code, not a model call. That
> single design choice is what kills context collapse — the bulk knowledge is
> never passed back through an LLM to be "rewritten," so it can't be silently
> corrupted. The LLM only ever *proposes small additions*.

---

## 4. The playbook — itemized bullets with counters

The context is not a prose blob. It's a list of **bullets**, each a small
self-contained unit, each with metadata:

```text
[id: a3f1 | helpful: 12 | harmful: 1]
  When calling the Spotify API, the `market` param is REQUIRED or it
  returns an empty list — not an error. Always set it.

[id: b8c2 | helpful: 5 | harmful: 0]
  Pattern: resolve the user's display-name to an internal id BEFORE
  any write call. Skipping this caused 3 failed runs.
```

- **Content** is one reusable unit: a strategy, a domain concept, or a common
  failure mode.
- **Metadata** is a unique id plus **helpful / harmful counters** tracking how
  often that bullet was associated with success or failure.

The counters are what make the playbook *self-pruning*: a bullet that keeps
correlating with failures earns a rising `harmful` count and can be demoted or
dropped, while battle-tested bullets accumulate `helpful` and stay.

---

## 5. Grow-and-refine — incremental, never wholesale

Updates are applied as **deltas**, not rewrites:

1. **Append** — bullets with new ids are added to the playbook.
2. **Update in place** — existing bullets are edited locally (e.g. increment a
   counter, sharpen the wording) without touching their neighbours.
3. **De-duplicate** — a pruning step compares bullets by **semantic embedding**
   and removes redundancy, so the playbook grows in coverage but not in bloat.

This is "grow-and-refine": the context expands to cover new situations, then
periodically compacts by merging near-duplicates — *not* by summarising away
detail. Because each step is localised, the rich knowledge from step 1 is still
verbatim-present at step 100.

> **Architectural takeaway:** this is exactly the discipline a good
> [AGENTS.md / memory file](The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md)
> wants but rarely gets when a human maintains it: append precise, itemized,
> de-duplicated lessons; never "tidy up" by rewriting the whole file from memory.
> ACE is the automated version of the manual habit.

---

## 6. The numbers

Base model is the open-source **DeepSeek-V3.1**; the proprietary comparison
point is **IBM CUGA**, a GPT-4.1-based production agent.

**AppWorld (agentic tasks)** — TGC = task goal completion, SGC = scenario goal
completion:

| Split | Metric | Gain over baseline |
|---|---|---|
| test-normal (offline) | 76.2% TGC / 64.3% SGC | +12.5 / +21.4 |
| test-challenge (offline) | 57.3% TGC / 39.6% SGC | +15.8 / +18.0 |
| test-challenge (online) | 66.0% TGC / 48.9% SGC | +24.5 / +27.3 |

On the AppWorld leaderboard this **matches the top-ranked production agent on the
overall average and surpasses it on the harder test-challenge split** — with a
smaller open-source model.

**Finance (domain knowledge):** FiNER 78.3% (+7.6), Formula 85.5% (+18.0),
average **81.9% (+12.8)**.

**Efficiency** — the part that makes it deployable:

- vs **GEPA** (a prompt-optimisation baseline): **82.3% lower adaptation latency**,
  **75.1% fewer rollouts**.
- vs **Dynamic Cheatsheet**: **91.5% lower adaptation latency**, **83.6% lower
  token-dollar cost**.

> **Why it matters:** the efficiency wins come from the same delta design. You're
> not re-running expensive whole-context optimisation each round — you append a
> few bullets. Self-improvement that's cheap enough to run *online*, per task,
> is a different operational animal from one that needs a batch optimisation job.

---

## 7. Where it fits, and where it breaks

**Reach for ACE-style context evolution when:**

- The gap is *knowledge*, not raw capability — brittle APIs, house rules,
  domain jargon, repeated-failure patterns the base model can't know.
- You want self-improvement you can **read and audit** (regulated domains,
  finance, anything where "why did it do that" must be answerable).
- Retraining is too slow or too expensive for how fast the task drifts.

**It breaks down when:**

- **The feedback signal is noisy or wrong.** Reflector lessons are only as good
  as the execution feedback. If success/failure is mislabelled, the playbook
  learns the wrong rules and the counters reinforce them.
- **The playbook out-grows the window.** Grow-and-refine bounds bloat but not
  forever; at some point retrieval over the playbook (treat it as
  [memory](Agent%20Memory%20Architectures%20—%20Tiered%2C%20Vector%2C%20Temporal-Graph.md))
  beats stuffing all of it in-context.
- **The missing ability is reasoning, not knowledge.** No amount of written
  playbook teaches a model to do math it fundamentally can't do. Context
  engineering fixes *what the model knows*, not *what it can compute* — that's
  the boundary with the
  [SLM-vs-LLM](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md)
  capability question.

> **Lesson:** "self-improving agent" is overloaded. ACE stakes out the cheap,
> auditable, online half — improve the *context*. Weight-space methods own the
> other half — improve the *capability*. They compose: tune the model for the
> skill, evolve the playbook for the knowledge.

---

## References

- [Zhang et al. — Agentic Context Engineering: Evolving Contexts for Self-Improving Language Models (arXiv 2510.04618)](https://arxiv.org/abs/2510.04618)
- [Full paper (HTML)](https://arxiv.org/html/2510.04618v1)
- [OpenReview — ACE (ICLR 2026)](https://openreview.net/forum?id=eC4ygDs02R)
- [Microsoft Research — Agentic Context Engineering publication page](https://www.microsoft.com/en-us/research/publication/agentic-context-engineering-evolving-contexts-for-self-improving-language-models/)
- [Hugging Face — Paper page (2510.04618)](https://huggingface.co/papers/2510.04618)
