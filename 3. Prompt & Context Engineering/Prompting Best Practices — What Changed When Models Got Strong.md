# Prompting Best Practices — What Changed When Models Got Strong

> **Updated 2026-06-19.** Prompting in 2023 was a bag of *tricks to coax a weak model*:
> "let's think step by step," elaborate role-play, few-shot scaffolds, "I'll tip you
> $200." Most of those tricks are now **dead or actively harmful**. The 2026 models
> (Opus 4.8, Fable 5, GPT-5.5, Gemini 3.x) reason internally, follow instructions
> literally, and overtrigger on the pushy language we used to need. The skill did not
> disappear — it **moved**. The job is now: *specify intent precisely, structure the
> input, curate the context, and stop telling the model how to think.* This note is the
> durable core — what still works, what now backfires, and why — distilled from
> Anthropic's current prompting guidance and the 2026 reasoning-model literature. It
> pairs with [Prompt Caching](prompt-caching.md) (the *mechanics* of the prompt) and
> [Context Engineering in the Harness](../11.%20Harness%20Engineering/11.8.%20Context%20Engineering%20in%20the%20Harness.md)
> (the *systems* layer). This note is the *writing* layer.

---

## 1. The shift: from "how to think" to "what to produce"

The single principle that reorganizes everything below:

> **Prescribing the reasoning path hurts. Defining the goal and constraints helps.**
> Strong models already have a better internal plan than the one you'd hand-write. Your
> leverage is on the *spec* (what good output is) and the *context* (what facts it needs),
> not on the *procedure* (how to get there).

What changed, concretely:

| 2023 reflex | 2026 reality |
|---|---|
| "Let's think step by step" on everything | Reasoning models **think natively**; explicit CoT is redundant or contradicts internal reasoning |
| Stuff 8 few-shot examples | Examples can **redirect** internal reasoning; use 0 or a few *canonical* ones |
| "CRITICAL: you MUST use this tool!!!" | Models now **overtrigger** on pushy language — dial it back to "Use this tool when…" |
| Self-consistency / sample-and-vote | Models are consistent by default; voting is wasted compute |
| Anti-laziness nagging ("be thorough, don't be lazy") | Models are proactive now — nagging causes **over-engineering and overthinking** |
| Prefill the assistant turn to force format | Deprecated on Claude 4.6+; use **structured outputs** or a direct instruction |

> **Why it matters:** the failure mode flipped. In 2023 the risk was the model doing *too
> little*. In 2026 the risk is doing *too much* — spawning subagents you didn't ask for,
> over-engineering a one-line fix, thinking for 30 seconds on a trivial query. Modern
> prompting is as much about **removing** old scaffolding as adding new instructions.

---

## 2. The clarity core (this part never changed)

Everything else is optional; this is the floor. Strong models are *better* at following
clear instructions, which makes vague ones *more* costly, not less.

- **Be specific about the output and constraints.** "Create a dashboard" → "Create a
  dashboard with X, Y, Z; go beyond the basics." If you want above-and-beyond, *ask for
  it* — don't expect the model to infer ambition from a terse prompt.
- **State the *why*, not just the what.** "Never use ellipses" is weak. "This will be read
  by a text-to-speech engine, so never use ellipses" is strong — the model generalizes
  from the reason to cases you didn't enumerate. (This is also why our
  [CLAUDE.md rules](../11.%20Harness%20Engineering/11.3.%20Rules%20and%20Project%20Instructions.md)
  capture the *why*.)
- **Tell it what to do, not what not to do.** "Don't use markdown" → "Write in flowing
  prose paragraphs." Positive targets steer better than prohibitions.
- **Sequence with numbered steps** when order or completeness matters.
- **The golden rule:** show your prompt to a colleague with no context. If they'd be
  confused, the model will be too.
- **Give it a role** in one sentence ("You are a senior Python reviewer"). Cheap, real
  effect on tone and focus.

---

## 3. Structure the input

Unstructured "blob prompts" force the model to guess where instructions end and data
begins. Structure removes that ambiguity.

- **XML tags** (`<instructions>`, `<context>`, `<example>`, `<input>`). Claude was trained
  on them, so they parse cleanly; for other models, Markdown headers do the same job. Use
  **consistent, descriptive** names and nest when there's a hierarchy
  (`<document index="1">` inside `<documents>`).
- **Order matters in long context.** Put long documents and data **at the top**, your
  query and instructions **at the bottom**. Anthropic measures up to **+30%** on complex
  multi-doc tasks from this alone.
- **Ground long-doc answers in quotes.** Ask the model to first extract relevant quotes
  into `<quotes>` tags, then answer from those. It cuts through noise and reduces
  hallucination.
- **Match prompt style to desired output.** Want prose, not bullets? Write the prompt in
  prose. Drop markdown from the prompt to reduce markdown in the reply.

---

## 4. Examples — fewer, sharper, and not always

Few-shot is still "one of the most reliable ways to steer format, tone, and structure" —
**but the calculus changed for reasoning models.**

- **Do:** use 3–5 examples when you need a specific *format/structure/tone*; make them
  **relevant** (mirror the real case), **diverse** (cover edge cases without teaching a
  spurious pattern), and **wrapped** in `<example>` tags.
- **Don't:** "stuff a laundry list of edge cases." Curate a few *canonical* ones —
  examples are "the pictures worth a thousand words," but the wrong pictures mislead.
- **Reasoning-model caveat:** on hard *reasoning* tasks, examples can *overwhelm or
  redirect* the model's own reasoning. If a task is about *thinking* (math, analysis),
  try **zero-shot with a sharp spec first**; reserve examples for *output shaping*.

---

## 5. Reasoning / thinking models — let them think

The 2026 models do most multi-step reasoning internally (Claude's *adaptive thinking*
decides when and how much to think based on an `effort` setting and query complexity).

- **Prefer general direction over a prescribed plan.** "Think thoroughly about X" beats a
  hand-written 7-step procedure — the model's reasoning routinely exceeds what you'd
  script.
- **Self-check still works.** "Before finishing, verify your answer against [criteria]"
  reliably catches errors, especially in code and math.
- **Show reasoning *style* via examples,** not rules: put `<thinking>` blocks in your
  few-shot examples and the model generalizes the pattern.
- **Tame overthinking.** High-effort models over-explore. If responses are slow or
  bloated, lower `effort`, or add: *"choose an approach and commit; don't revisit unless
  new information contradicts it."*
- **Word choice:** with thinking *off*, some Claude models are sensitive to the literal
  word "think" — use "consider," "evaluate," "reason through" to avoid accidental
  triggering.

> **Why it matters:** the highest-ROI edit on a 2026 prompt is often a *deletion* — remove
> the CoT boilerplate and the "you MUST be thorough" nags. They fight the model's trained
> behavior and waste tokens.

---

## 6. From prompting to context engineering

As models got strong, leverage shifted from *the sentence you write* to *the tokens you
put in the window*. Anthropic frames context engineering as "curating and maintaining the
optimal set of tokens during inference" — and it's **iterative**, not one-shot.

- **Find the right altitude for system prompts.** Not brittle hardcoded logic; not vague
  hand-waving. Aim for *"specific enough to guide behavior, flexible enough to give the
  model strong heuristics."*
- **Smallest set of high-signal tokens.** More context is not better. **Context rot** is
  real: every model has a finite *attention budget*, and quality degrades as the window
  fills with low-signal text — at every window size, not just small ones.
- **Just-in-time over pre-loading.** Keep lightweight references (file paths, queries,
  links) and let the agent *fetch* what it needs at runtime, instead of dumping
  everything upfront. Trades a little speed for a lot of context efficiency.
- **For long-horizon work:** *compaction* (summarize history, keep architectural
  decisions / open bugs, drop redundant tool output), *structured note-taking* (persist
  state to files outside the window), and *subagents* that return ~1–2k-token distilled
  summaries. (See [Multi-Agent Orchestration](../5.%20AI%20Agents%20&%20Tool%20Use/Multi-Agent%20Orchestration%20in%20Production%20—%20Topologies,%20Token%20Economics,%20and%20Coordination%20Failure.md)
  and [ACE](../5.%20AI%20Agents%20&%20Tool%20Use/Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md).)

---

## 7. Prompting agents (tool use)

Agent prompts have their own failure modes because the model now *acts*, not just writes.

| Goal | Prompt move |
|---|---|
| Make it **act**, not advise | "Change this function" — not "Can you suggest changes?" (the literal model will only suggest) |
| Control **autonomy** | Add `<default_to_action>` (act first) or `<do_not_act_before_instructions>` (research first) |
| **Parallelize** tool calls | "If calls are independent, make them in parallel" → ~100% parallel; "sequentially" to slow down |
| **Don't over-delegate** | Models over-spawn subagents — specify when subagents are vs aren't warranted |
| Stay **safe** on irreversible acts | Spell out: confirm before delete / force-push / external posts; never `--no-verify` as a shortcut |
| Avoid **over-engineering** | "Only make changes directly requested; no extra abstractions, no defensive code for impossible cases" |
| Avoid **hard-coding to tests** | "Solve the general problem; tests verify correctness, they don't define the solution" |
| Minimize **hallucination** | `<investigate_before_answering>`: never claim anything about a file you haven't opened |

> **Why it matters:** these all encode the same lesson as the whole note — modern agents
> err toward *too much*. Good agent prompts are mostly **guardrails on eagerness**, plus a
> clear statement of what "done" and "in-scope" mean.

---

## 8. Treat prompts as code

The meta-discipline that makes all of the above stick:

1. **Start minimal, add by failure.** Begin with the shortest prompt on the best model,
   then add an instruction *only* when you observe a real failure mode — the same "every
   rule is earned" ratchet as [harness best practices](../11.%20Harness%20Engineering/agent-harness-best-practices.md).
2. **Iterate empirically.** Prompting is test-driven, not guess-the-magic-words. Keep a
   small eval set; measure changes; don't ship vibes.
3. **Re-tune per model.** Each upgrade removes weaknesses *and* adds eagerness. A prompt
   tuned to fight Sonnet 4.5's laziness will make Opus 4.8 overtrigger. Re-test on every
   model bump and **delete** what's now redundant.
4. **Prefer the feature over the prompt.** Need strict JSON? Use *structured outputs*, not
   prefill or pleading. Need a hard thinking cap? Use `effort`/`max_tokens`. The platform
   often solves cleanly what a prompt solves fragilely.

---

## 9. One-screen checklist

```text
SPEC      □ specific output + constraints   □ stated the WHY   □ positive ("do X" not "don't Y")
STRUCTURE □ XML/markdown sections           □ long data top, query bottom   □ quotes for long docs
EXAMPLES  □ 0 for pure reasoning            □ 3–5 canonical for format   □ wrapped in <example>
THINKING  □ "think thoroughly" not a script □ self-check step   □ effort tuned, no CoT boilerplate
AGENTS    □ explicit act-vs-advise          □ scope/over-eng guardrails   □ safety on irreversible acts
PROCESS   □ start minimal, add by failure   □ small eval set   □ re-tune per model   □ feature > prompt
DELETE    □ removed "MUST!!!", anti-laziness nags, redundant few-shot, prefill hacks
```

---

## References

- [Anthropic — Prompting best practices (current models)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Use XML tags to structure your prompts](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags)
- [Every AI Prompting Technique That Works on Reasoning Models (2026)](https://karozieminski.substack.com/p/ai-prompting-techniques-reasoning-models-2026)
- [The Evolution of Prompt Engineering to Context Design in 2026 — SDG Group](https://www.sdggroup.com/en/insights/blog/the-evolution-of-prompt-engineering-to-context-design-in-2026)
- [Prompt engineering techniques: Top 6 for 2026 — K2view](https://www.k2view.com/blog/prompt-engineering-techniques/)
- [The Ultimate Guide to Prompt Engineering in 2026 — Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)
