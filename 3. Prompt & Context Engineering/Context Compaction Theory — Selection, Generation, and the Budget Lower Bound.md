# Context Compaction Theory — Selection, Generation, and the Budget Lower Bound

> **Source:** Tirmazi, Markelon, Bishop & Mitzenmacher, *Context Compaction Theory*
> (arXiv:2608.01326, 2 Aug 2026). Companion to
> [Context Window Management — Eviction, Compaction & Memory](./Context%20Window%20Management%20—%20Eviction%2C%20Compaction%20%26%20Memory.md),
> which covers *how* to compact. This note covers *what compaction can and cannot
> preserve, and how many bits it takes* — and it is the first paper to answer that
> question with a proof rather than a benchmark.

Every production agent compacts. Nobody could say what compaction costs. This paper
formalizes compaction as two games, proves the generation game is *exactly*
one-way communication complexity, and thereby imports fifty years of lower bounds
into harness design. The practical payoff is blunt: for some workloads you can now
prove no summarizer will ever work, and you should put the state in a tool instead
of hoping the summary carries it.

---

## 1. The structural fact that makes compaction hard

Compaction is committed **before the query arrives**. The harness decides what to
keep at 95% window occupancy; the user asks their question three turns later. The
compactor cannot condition on the query it is compacting for.

That single constraint is what turns compaction into a communication problem rather
than a retrieval problem. Retrieval sees the query and goes and gets the answer.
Compaction has to guess, in advance, which of the exponentially many future
questions the surviving bits must be able to answer.

> **Why it matters:** every intuition you have from RAG is wrong here. RAG is
> query-conditioned; compaction is not. A "smarter summarizer" cannot close a gap
> that is information-theoretic.

## 2. The two games

The paper carves all real compaction algorithms into two classes.

| | **Context Selection Game** (`SELECT`) | **Context Generation Game** (`GEN`) |
|---|---|---|
| Output | a subset `S ⊆ X` with `Σ s(xᵢ) ≤ B` | any message in `Σ^{≤B}` |
| May invent tokens | no | yes (a summary) |
| May use ordering as signal | no | yes |
| Output size | sum of kept item sizes | can encode `S` in fewer bits than `S` occupies |
| In practice | tool-result clearing, message truncation, token pruning | LLM summarization |

Both are three-stage: the adversary fixes the item universe `X` and item sizes; the
compactor commits its output under budget `B`; then a query `q` arrives and is
scored `val ∈ [0,1]`, with `err = 1 − val`. Two query regimes — **stochastic**
(`(X,q) ~ µ`, known distribution) and **oblivious adversary** (worst case, but the
adversary does not see the compactor's output).

`GEN` is the honest model of an LLM summarizer, and the paper is careful about who
the "generator" is: it is *the condenser plus the LLM that later reads the compacted
context*. The summarization call is the encoder; the next inference is the decoder.
By construction `SELECT ⊆ GEN` — selection is the special case where the interpreter
just returns the retained set.

Granularity is deliberately left open: an item can be one tool result, one message,
one code symbol, or one token. Lossless compression of an individual item is folded
into `s(xᵢ)` and treated as an orthogonal black box.

## 3. Where the real agents land

The paper's survey (Table 1) classifies shipped systems. Every one falls in
`SELECT ∪ GEN`.

| System | Class | `SELECT` granularity | Mechanism |
|---|---|---|---|
| Codex | `GEN` | — | per-model token threshold, then whole-history LLM summarization |
| Gemini CLI | `GEN` | — | fires at a configurable % of window, emits a structured XML snapshot |
| Claude Code | `SELECT` + `GEN` | tool result | tiered: inline compression of large tool outputs first, LLM summary as fallback |
| OpenCode | `SELECT` + `GEN` | tool result | prunes old tool-call outputs, separate LLM summarization on overflow |
| OpenAI Assistants truncation | `SELECT` | message | `last_messages` (keep N most recent) or `auto` (drop middle) |
| LangChain `trim_messages` | `SELECT` | message | configurable drop policy, e.g. oldest-first |
| Aider repo map | `SELECT` | code symbol | PageRank-style symbol ranking, top-k under budget |
| LLMLingua / Selective Context | `SELECT` | token | delete low-information tokens; output is a sub-sequence |

The hybrids are the interesting entry: **cheap `SELECT` first, expensive `GEN` only
when the `SELECT` budget is exhausted**. That is the pattern worth copying, and it is
the same tiering Claude Code exposes as tool-result clearing before `/compact`.

Two design points the paper makes in passing and which are easy to under-rate:

- **Compaction is a property of the agent, not the model.** Codex's mechanism is
  independent of the underlying LLM. Swapping providers does not change the shape of
  the problem.
- **Compacted state is carried forward, not re-derived, because re-derivation is
  ruinous.** Their worked example: 800K tokens of history, a 100K-token
  re-summarization on a frontier model runs about $13 and roughly 26 minutes for a
  *single* query.

## 4. The equivalence, and what it buys you

**Theorem 1.** The Context Generation Game *is* one-way communication. Alice gets
the item universe `X`, Bob gets the query `q`, Alice sends one message of ≤ `B` bits.
The minimum compaction budget achieving error ≤ ε equals the randomized one-way
communication complexity `R→_{µ,ε}(Π_G)` of the induced problem — under both the
stochastic and the oblivious-adversary regimes.

The proof is a direct identification, not a reduction: a `GEN` algorithm and a
one-way protocol are literally the same pair of functions (`Cond` = Alice,
`Int` = Bob), with randomized `GEN` matching public-coin protocols.

**Corollary 2.** `SELECT` algorithms are exactly the one-way protocols whose message
identifies a subset and whose decoder reads only that subset. So any `SELECT` vs
`GEN` gap is a gap between subset-encoding protocols and unrestricted ones.

**Theorem 3 (separation).** Take `n = 2ᵏ` items each of size `log₂ n` bits, let `X`
be an arbitrary subset, and let the query ask for `X` itself. `GEN` answers with zero
error in **`n` bits** (send the indicator vector). Every zero-error `SELECT` needs
**`n log₂ n` bits** — zero error forces the selection map to be injective on the
power set, hence a bijection, hence some input retains everything. A `Θ(log n)`
separation, and it survives randomization.

> **Architectural takeaway:** summarization is not merely "lossier truncation." It is
> a strictly more expressive class. Truncating messages can be provably worse than
> summarizing them, at the same byte budget.

Two caveats the authors state plainly, and you should hold onto both:

- The equivalence is **information-theoretic, not computational**. An upper bound
  exhibits *some* `GEN` algorithm at that budget; it does not promise an LLM
  summarizer can compute it. **Lower bounds carry no such caveat** — they bind
  everyone.
- It applies to the stochastic and oblivious regimes only. Against an **adaptive**
  adversary who sees the compacted context before choosing the query, Theorem 1 does
  not hold.

## 5. The workloads that are provably uncompactable

This is the part that should change what you build.

Suppose the agent has recorded a repo's `N` third-party dependencies out of a
universe of `2ᵐ` package names, and the user later asks: *"do any of these appear in
this list of packages with known CVEs?"* That is **set disjointness** — a canonical
hard problem in communication complexity. Because compaction commits before the
query, the compacted context must determine the dependency set exactly, costing

```text
log₂( |U| choose N )  ≥  N · log₂(|U|/N)  =  Ω(N·m) bits
```

which is no better than storing the dependency list uncompressed.

And a Bloom filter does not save you. A filter with false-positive rate `ε` costs
`≈ 1.44 · N · log₂(1/ε)` bits, but disjointness against a target list `T` errs with
probability `1 − (1−ε)^{|T|}`, forcing `ε = O(δ/|T|)` and therefore `Ω(N log₂(|T|/δ))`
bits. With `|T|` as large as the universe, that is `Ω(N·m)` again — **even for
constant target error `δ`**.

> **Lesson:** exact-membership and set-intersection workloads do not belong in a
> summary at any budget. Put them behind a tool the agent can query, or persist them
> to a file it can re-read. This is the formal justification for the
> file-as-context / memory-tool pattern, not a stylistic preference.

## 6. The measurement: Anthropic's compaction endpoint on set membership

Appendix A turns the theory into a benchmark, and the result is unflattering by
design — the setup is deliberately *favorable*.

Setup: 15,000 URLs from the Malicious URLs dataset (~500K tokens; URLs share domains
and path structure, so the set compresses well), compaction threshold at 50K tokens,
Anthropic's compaction endpoint with Opus 4.8. The compaction prompt **states the
workload in advance** — "minimize the number of membership queries you answer
incorrectly, use whatever representation best achieves this" — which is the
equivalent of sizing a Bloom filter for a known workload. Then 200 membership
queries, half members and half non-members, each in a fresh request containing only
the compacted context. Three seeds.

| Run | Budget (Kbits) | False positive rate | False negative rate |
|---|---|---|---|
| Seed 42 | 14.3 | 0.04 | 0.97 |
| Seed 43 | 13.6 | 0.28 | 0.79 |
| Seed 44 | 14.8 | 0.48 | 0.63 |
| No compaction (control) | 7,280 | 0.00 | 0.04 |

Aggregate error across seeds: **0.505, 0.535, 0.555** — on the random-guess line, two
of three runs *worse* than a coin flip. A Bloom filter of the same ~14 Kbit size errs
on about a third of the queries. The uncompacted control errs on 0.02, so the loss is
attributable to compaction, not to the model's ability to answer.

The model, to its credit, says so. Seed 42's summary contains: *"I need to be honest
about a fundamental limitation … Any lossy summary will produce errors on membership
queries"* and *"Since I cannot reliably reconstruct exact membership, I will have to
guess based on whether a string 'looks like' it belongs to this kind of aggregated
set."*

The authors scope the claim carefully: this is one endpoint at one moment, not a
statement that compaction must always underperform a Bloom filter. Take it as a
calibration point, not a verdict on a vendor.

## 7. What to change in a harness

1. **Classify your own compactor.** `SELECT`, `GEN`, or hybrid — and at what
   granularity. If it is pure `SELECT` at message granularity, Theorem 3 says you may
   be paying a `log n` factor for nothing.
2. **Tier it.** Cheap `SELECT` (drop stale tool results) before expensive `GEN`
   (summarize). Claude Code and OpenCode already do this; most homegrown harnesses do
   not.
3. **Enumerate the query families your agent must answer post-compaction.** Anything
   that reduces to exact membership, equality, or disjointness gets a tool or a file,
   never a summary.
4. **Two escape hatches the paper names:** maintain a sketch *outside* the context
   and expose it as a tool, or place a sketch's raw state *inside* the context along
   with decoding instructions. Whether an LLM can reliably run a sketch's decode
   procedure in-context is stated as open.
5. **Assume repeated compaction is strictly worse.** Each pass runs on a prior pass's
   output and can only discard more. The paper models the single invocation as the
   *most favorable* case: if one compaction cannot preserve the answer, a session of
   many certainly cannot. Error growth across a compaction chain is unmodeled.
6. **Do not count on KV-cache tricks.** H2O/StreamingLLM-style eviction is
   unavailable to anyone on hosted inference or swapping between providers. The
   context you construct and send is the only lever most teams actually hold.

## 8. The safety corollary — compaction as a governance surface

The theory says compaction silently drops information. A separate result says one of
the things it drops is your policy.

*Governance Decay* (arXiv:2606.22528) introduces **ConstraintRot**, a benchmark of
long-horizon agent scenarios with deterministic tool-call grading, across seven model
families and 1,323 episodes. With the policy in full context, prohibited-action
violation is **0%**. After compaction it rises to **30%**, reaching **59%** for some
models. Conditioning on what happened to the constraint sharpens it further: when the
constraint survives the summary, violation stays at **0%**; when it is dropped,
violation hits **38%**. The failure is entirely mediated by whether the text survived.

Worse, this is attackable. Their **Compaction-Eviction Attack** plants adversarial
in-context content that biases the summarizer into omitting a legitimate policy;
optimized injections defeated every model evaluated. The mitigation is
embarrassingly simple and training-free — **Constraint Pinning**, which quarantines
governance constraints from lossy compaction — and it restores violation to 0%.

> **Architectural takeaway:** the compaction step is inside your trust boundary. Any
> constraint that must hold for the whole session belongs in a pinned region that the
> compactor structurally cannot touch — system prompt, a re-injected policy block, or
> a pre-tool-call hook — not in the conversation the summarizer is free to rewrite.
> See [8.1. Agent Containment & Control](../8.%20AI%20Safety%20%26%20Ethics/8.1.%20Agent%20Containment%20%26%20Control%20—%20Capping%20the%20Blast%20Radius.md).

## 9. The training-side response

If compaction is lossy and unavoidable, one answer is to stop treating the summarizer
as a fixed component and train through it. **CompactionRL** (arXiv:2607.05378) does
exactly that: it jointly optimizes task execution *and* summary generation with
token-level loss normalization and cross-trajectory generalized advantage estimation,
so the policy learns from compacted trajectories rather than in spite of them.

Reported gains on open models: GLM-4.5-Air (106B-A30B) reaches 66.8% Pass@1 on
SWE-bench Verified and 24.5% on Terminal-Bench 2.0 (+7.0 / +3.1 absolute);
GLM-4.7-Flash (30B-A3B) reaches 56.0% and 20.2% (+5.5 / +6.8). It is now in the RL
pipeline for GLM-5.2.

> **Why it matters:** it reframes the summary as a *learned action* with a reward,
> not a formatting step. Note this does not contradict §5 — training cannot beat an
> information-theoretic lower bound. It closes the gap between what a summarizer
> *does* produce and what the best `GEN` algorithm *could* produce at the same budget,
> which §6 shows is currently enormous.

---

## References

- [Context Compaction Theory (arXiv:2608.01326)](https://arxiv.org/abs/2608.01326)
- [Governance Decay — How Context Compaction Silently Erases Safety Constraints in Long-Horizon LLM Agents (arXiv:2606.22528)](https://arxiv.org/abs/2606.22528)
- [CompactionRL — Reinforcement Learning with Context Compaction for Long-Horizon Agents (arXiv:2607.05378)](https://arxiv.org/abs/2607.05378)
- [Anthropic — Compaction](https://platform.claude.com/docs/en/build-with-claude/compaction)
- [Anthropic — Context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing)
- [Anthropic Cookbook — Automatic context compaction](https://platform.claude.com/cookbook/tool-use-automatic-context-compaction)
