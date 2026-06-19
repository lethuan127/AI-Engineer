# Prompting Techniques Catalog — What Each One Is, and Whether It Still Earns Its Keep

> **Updated 2026-06-19.** This is the companion to [Prompting Best Practices — What Changed
> When Models Got Strong](Prompting%20Best%20Practices%20—%20What%20Changed%20When%20Models%20Got%20Strong.md).
> That note argues the *principle* (specify intent, don't prescribe reasoning). This note
> is the *catalog*: the 18 named techniques from the field's standard reference
> ([promptingguide.ai](https://www.promptingguide.ai/techniques)), each re-graded for the
> 2026 reasoning models. The uncomfortable truth running through it: **most of these were
> invented to give a weak model a crutch it no longer needs.** A 2022 paper that lifted
> accuracy 30 points can be a no-op — or a *regression* — on Opus 4.8 or GPT-5.5. So each
> entry gets a verdict, not just a definition. Treat this as a decision aid: reach for a
> technique only when the model actually fails without it.

---

## 1. The verdict legend

| Mark | Meaning |
|---|---|
| ✅ **Core** | Still earns its keep on strong models; use freely |
| ⚠️ **Situational** | Useful for a specific shape of task; don't apply by reflex |
| ⛔ **Mostly redundant** | Native reasoning absorbed it; explicit use often wastes tokens or *hurts* |
| 🏗️ **Now architecture** | Graduated from "a way to phrase a prompt" into a system/agent component (lives in the harness, not the prompt) |

---

## 2. The master table

| # | Technique | One-line: what it is | 2026 verdict |
|---|---|---|---|
| 1 | **Zero-shot** | Just ask; rely on the model's trained knowledge | ✅ Core — the default; try this *first* |
| 2 | **Few-shot** | Show 2–5 examples to fix format/tone/structure | ✅/⚠️ Core for *output shape*; ⚠️ can derail *reasoning* tasks |
| 3 | **Chain-of-Thought (CoT)** | "Think step by step" to expose intermediate reasoning | ⛔ Reasoning models do this natively; explicit CoT is redundant/contradictory |
| 4 | **Meta prompting** | Use the model to write or improve prompts | ⚠️ Useful as a tool, not a runtime trick (see APE) |
| 5 | **Self-consistency** | Sample many CoT paths, majority-vote the answer | ⛔ Models are consistent by default; mostly wasted compute |
| 6 | **Generate-knowledge** | Have the model state relevant facts before answering | ⛔ Folded into native reasoning; RAG handles real grounding |
| 7 | **Prompt chaining** | Split a task into sequential calls, output→input | ✅ Core — for *pipelines you must inspect/log*, not for reasoning |
| 8 | **Tree of Thoughts (ToT)** | Branch, explore, and backtrack over many reasoning paths | ⛔/🏗️ Native reasoning + agent search subsume most of it |
| 9 | **Retrieval-Augmented Generation (RAG)** | Inject retrieved external knowledge into context | 🏗️ Foundational *architecture*, not a prompt trick |
| 10 | **Automatic Reasoning & Tool-use (ART)** | Interleave reasoning with tool calls from a library | 🏗️ Became native tool use / the agent loop |
| 11 | **Automatic Prompt Engineer (APE)** | Search/optimize prompts automatically | ⚠️/🏗️ Now "prompt optimization" tooling and evals |
| 12 | **Active-Prompt** | Pick the *most informative* examples to annotate | ⚠️ Niche; matters when you curate a few-shot set at scale |
| 13 | **Directional Stimulus** | Add small hint/keyword cues to steer output | ⚠️ Subsumed by clear instructions + structured output |
| 14 | **Program-Aided LMs (PAL)** | Offload computation to generated code, not prose | 🏗️ Became the code-interpreter / tool the agent calls |
| 15 | **ReAct** | Reason → act (tool) → observe, in a loop | 🏗️ The blueprint of the modern agent; now the runtime, not a prompt |
| 16 | **Reflexion** | Self-critique, then retry with the critique in context | ⚠️/🏗️ Self-check survives in-prompt; full loops live in the harness |
| 17 | **Multimodal CoT** | Reasoning that spans text + images | ⛔/🏗️ Native multimodal reasoning; give a crop/zoom tool instead |
| 18 | **Graph prompting / Graph-of-Thoughts** | Model reasoning as a graph of interdependent thoughts | ⛔ Research-grade; rarely worth the orchestration cost |

> **Why it matters:** read the verdict column top-to-bottom and the story is unmistakable —
> the ⛔ rows are almost all *reasoning-elicitation* tricks (CoT, self-consistency,
> generate-knowledge, ToT, graph), and the 🏗️ rows are almost all *tool/grounding* tricks
> (RAG, ART, PAL, ReAct). The first group **moved into the model**; the second **moved into
> the system**. What's left as genuine *prompting* is a short list: ask clearly (zero-shot),
> show format (few-shot), and split pipelines you must inspect (chaining).

---

## 3. The four families, expanded

### A. Input shaping — what survives as pure prompting ✅

- **Zero-shot** is the default. Strong models solve most tasks from a clear, specific ask;
  every other technique is a *patch* you add only when zero-shot visibly fails.
- **Few-shot** is the most durable add-on, but its job narrowed: use it to lock **format,
  tone, and structure** (3–5 *canonical*, diverse examples in `<example>` tags). On pure
  *reasoning* tasks, examples can overwhelm or redirect the model's own chain — try
  zero-shot first there.
- **Prompt chaining** survives because some pipelines must be **inspectable**: draft →
  review → refine, each a separate call you can log, eval, or branch. This is control-flow
  engineering, not a reasoning hack.

### B. Reasoning elicitation — mostly absorbed by the model ⛔

CoT, self-consistency, generate-knowledge, tree-of-thoughts, and graph-of-thoughts were
all ways to *manufacture* reasoning a weak model wouldn't produce on its own. The 2026
models reason internally (Claude's *adaptive thinking* decides depth from an `effort`
knob and query complexity). Consequences:

- **Don't bolt "think step by step" onto everything** — it's redundant and can fight the
  native chain. Prefer "think *thoroughly*" (a goal) over a prescribed sequence.
- **Self-consistency / ToT / graph** buy little: you pay 5–20× the tokens to re-derive a
  consistency and search the model already does. Reserve search-style methods for the rare
  task with a genuinely huge, verifiable solution space — and even then, an *agent* that
  searches with tools usually beats a single mega-prompt.
- The one survivor from this family is **self-check** ("verify your answer against
  [criteria] before finishing") — cheap, and it reliably catches code/math errors.

> **Why it matters:** this is the single biggest token-saving edit available on a 2026
> prompt — *delete* the reasoning scaffolding and trust the model's native thinking,
> dialing depth with `effort` instead of prose.

### C. Tooling & grounding — graduated into architecture 🏗️

RAG, ART, PAL, and ReAct are no longer "prompting techniques" in any practical sense —
they are the **load-bearing structure of modern agents**:

- **RAG** is the canonical answer to grounding and hallucination; it's a retrieval system,
  not a sentence. (Its design questions — chunking, embeddings, re-ranking — live in the
  [RAG track](../4.%20RAG%20&%20Vector%20Databases/).)
- **ReAct** (reason → act → observe) is the *shape of the agent loop itself*. You don't
  prompt ReAct; you build a loop that does it.
- **PAL** became the code interpreter: hard arithmetic/logic is offloaded to executed code,
  not generated prose. **ART** became native tool use.

These connect to [The Agent Protocol Stack](../5.%20AI%20Agents%20&%20Tool%20Use/The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md)
and [Multi-Agent Orchestration](../5.%20AI%20Agents%20&%20Tool%20Use/Multi-Agent%20Orchestration%20in%20Production%20—%20Topologies,%20Token%20Economics,%20and%20Coordination%20Failure.md):
the technique didn't die, it moved up a layer.

### D. Self-improvement & auto-optimization ⚠️🏗️

- **Reflexion** (self-critique → retry) survives in two forms: a lightweight in-prompt
  self-check (⚠️ useful), and full critique-retry *loops* that belong in the harness with a
  real evaluator — never let the model grade its own work in a tight loop without an
  external signal. (See [agent harness best practices](../11.%20Harness%20Engineering/agent-harness-best-practices.md)
  and [Agentic Context Engineering](../5.%20AI%20Agents%20&%20Tool%20Use/Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md).)
- **APE / meta prompting** ("a model that writes prompts") is now **prompt-optimization
  tooling** wired to an eval set — the empirical, test-driven side of treating prompts as
  code. Use it offline to tune, not as a runtime wrapper.

---

## 4. Decision: which technique for which task

| If the task is… | Reach for | Skip |
|---|---|---|
| Anything, first attempt | **Zero-shot** + clear spec | everything else until it fails |
| Output must match a format/schema | **Few-shot** (or structured outputs) | CoT |
| Hard reasoning (math, analysis) | native thinking + **self-check** | CoT boilerplate, self-consistency |
| Needs facts outside the model | **RAG** (architecture) | generate-knowledge |
| Needs to act on the world | **ReAct loop / tool use** (architecture) | prompting "ReAct" by hand |
| Exact computation | **code execution (PAL-style)** | asking for arithmetic in prose |
| Multi-stage, must inspect steps | **prompt chaining** | one mega-prompt |
| Tuning a prompt at scale | **APE / evals** offline | hand-guessing magic words |

> **Mental model:** in 2026, choosing a "prompting technique" is mostly choosing *how
> little* to add. Start at zero-shot. Add a technique only as a patch for an observed
> failure — and check first whether the right fix is a **better spec**, a **tool**, or a
> **retrieval system** rather than a cleverer prompt. The catalog is a list of things you
> *might* need, not a checklist to apply.

---

## References

- [Prompt Engineering Guide — Techniques (the canonical catalog)](https://www.promptingguide.ai/techniques)
- [Wei et al. — Chain-of-Thought Prompting (2022)](https://arxiv.org/abs/2201.11903)
- [Wang et al. — Self-Consistency Improves CoT (2022)](https://arxiv.org/abs/2203.11171)
- [Yao et al. — Tree of Thoughts (2023)](https://arxiv.org/abs/2305.10601)
- [Yao et al. — ReAct: Reasoning + Acting (2022)](https://arxiv.org/abs/2210.03629)
- [Lewis et al. — Retrieval-Augmented Generation (2020)](https://arxiv.org/abs/2005.11401)
- [Gao et al. — PAL: Program-Aided Language Models (2022)](https://arxiv.org/abs/2211.10435)
- [Shinn et al. — Reflexion (2023)](https://arxiv.org/abs/2303.11366)
- [Zhou et al. — Automatic Prompt Engineer / APE (2022)](https://arxiv.org/abs/2211.01910)
- [Anthropic — Prompting best practices (current models)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
