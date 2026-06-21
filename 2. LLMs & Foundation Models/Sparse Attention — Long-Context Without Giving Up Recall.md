# Sparse Attention — Long-Context Without Giving Up Recall

> **Updated 2026-06-21.** Its sibling note,
> [Hybrid Mamba-Attention](Hybrid%20Mamba-Attention%20Models%20—%20Long-Context%20Efficiency%20for%20the%20Agent%20Era.md),
> kills the quadratic attention tax by *replacing* most attention layers with a
> linear-time recurrent mixer — and pays for it in recall, because a fixed-size state
> is a lossy summary. This note is the **other fork in the 2026 road**: keep softmax
> attention exactly as it is, but stop computing it over *every* token. Attend to a
> small, *selected* subset per query instead. The bet is opposite to Mamba's — that the
> needle in a 200K-token haystack is still needed *exactly*, and the cheap move is not
> to discard the haystack but to *find the needle fast and attend to it precisely*. The
> demonstration that put this in production: **DeepSeek-V3.2** shipped DeepSeek Sparse
> Attention (DSA), cut its API price **50%+**, and reports quality **on par** with its
> dense predecessor. This note explains why attention is already mostly wasted compute,
> the three ways the field makes it sparse, the DSA mechanism in detail, why sparsity
> has to be *trained in* and not bolted on, and how the sparse-vs-linear choice should
> fall out for an agent.

---

## 1. The fork: replace attention, or prune it

Both notes start from the same problem — self-attention is **O(n²)** in context length
`n`, and the KV cache grows linearly and unbounded, so a long agent session is ruinous
to serve. They diverge on the fix:

| | **Linear / SSM** ([Mamba note](Hybrid%20Mamba-Attention%20Models%20—%20Long-Context%20Efficiency%20for%20the%20Agent%20Era.md)) | **Sparse attention** (*this note*) |
|---|---|---|
| Move | *Replace* attention with a recurrent mixer | *Keep* softmax attention, read fewer tokens |
| State | Fixed-size recurrent summary | Full KV kept; only a top-k subset is read |
| Recall | Lossy — weak at exact in-context retrieval | Preserved — the right token can be selected from anywhere |
| New cost | None (no selection step) | A cheap *selector* that can miss the needle |
| Cost shape | O(n) | O(k·n), k ≪ n — near-linear |

> **Architectural takeaway:** linear attention bets the exact token *won't be needed*;
> sparse attention bets you can *cheaply locate* the exact token and attend to it. For
> an agent whose job is "find and quote the one clause in this log," that difference is
> the whole ballgame — which is why the two approaches are converging in the *same*
> 2026 models rather than one winning outright.

---

## 2. Why this works: attention is already sparse

Sparse attention is not an approximation imposed from outside — it exploits a property
the model already has. After softmax, attention weight is **highly concentrated**: for
any given query, a handful of tokens get almost all the weight and the long tail is
near-zero. Dense attention still *computes* that entire tail — it multiplies every query
against every key, then discards 99% of the result as ~0.

So the dense computation is mostly wasted. If you could know *in advance* which few
tokens will matter to this query, you could skip the rest with little quality loss. That
"if you could know in advance" is the entire engineering problem: you need a **selector**
that is far cheaper than attention itself but accurate enough to keep the tokens that
matter. Get the selector right and you keep softmax's exact recall while paying for only
the tokens that earn their place.

---

## 3. Three ways to make attention sparse

The methods differ in *who decides* which tokens a query may see.

| Family | Who selects | Example | Tradeoff |
|---|---|---|---|
| **Fixed pattern** | The layout, not the content | sliding window + global/sink tokens | Cheapest, fully static; blind to relevance — discards old context by *position* |
| **Block-routed** | A learned router over token *blocks* | **MoBA** (Moonshot/Kimi) | Coarse-grained but trainable; MoE-style "where to attend" decision |
| **Learned top-k** | A lightweight per-token *indexer* | **NSA**, **DSA** (DeepSeek) | Finest-grained; can pull a relevant token from anywhere, but the indexer is a new failure point |

- **Fixed-pattern** (sliding window, attention sinks) is the oldest and is everywhere as
  one *ingredient* — Arcee Trinity and others alternate local sliding-window layers with
  a minority of global layers. Its flaw is structural: it throws away distant context by
  position, so a fact 100K tokens back is simply unreachable in the windowed layers.

- **MoBA — Mixture of Block Attention** (Moonshot AI, deployed in Kimi) applies the
  Mixture-of-Experts idea to attention itself: partition the context into blocks, and a
  learned router picks which *blocks* each query attends to. Crucially it can **slide
  between full and sparse** attention, so you can run it dense where quality demands and
  sparse where length demands, with one trained model.

- **Learned top-k** (NSA, DSA) is the 2026 frontier and the rest of this note. A small
  *indexer* scores every past token's relevance to the current query, the top-k are
  selected, and full attention runs only over those k. Selection is content-based and
  global — unlike a window, it can reach a token anywhere in the sequence.

---

## 4. DeepSeek Sparse Attention (DSA) — the production proof point

DSA, shipped in **DeepSeek-V3.2** (V3.2-Exp released 2025-09-29; full tech report Dec
2025), is the cleanest worked example because DeepSeek published the mechanism, the
numbers, *and* the price cut. It sits on top of **Multi-head Latent Attention (MLA)** —
DeepSeek's KV-cache compression (≈70 KB/token vs MHA's ≈4 MB) — and adds a selection
stage in front of it.

```text
query token t
   │
   ▼
┌──────────────────────────────┐   Stage 1 — Lightning Indexer (cheap, FP8)
│ score every past token s vs t │   lightweight ReLU-gated dot products,
│   → relevance(t, s)           │   a few indexer heads, sub-attention cost
└──────────────────────────────┘
   │  pick top-k (k ≈ 2048)
   ▼
┌──────────────────────────────┐   Stage 2 — full MLA attention,
│ attend over the k selected    │   but only over the selected subset
│ tokens only                   │
└──────────────────────────────┘
   │
   ▼
 output
```

- **Stage 1 — the lightning indexer.** A deliberately cheap scorer (FP8, ReLU-gated dot
  products, a small number of heads) computes how relevant each cached token is to the
  current query. It still reads all S tokens, but at a fraction of attention's
  bytes-per-token, so the read is bandwidth-cheap.
- **Stage 2 — sparse MLA attention.** Only the **top-k ≈ 2048** tokens proceed to full
  attention. Everything else is skipped.

The complexity shifts from **O(L²)** to roughly **O(k·L)** with k fixed — near-linear in
context length. Concrete figures DeepSeek and independent analyses report:

- **~1.5× prefill speedup** at 131K tokens on H100, and roughly **5× less data loaded
  per decode step** at that length (decode reads become near-constant, not linear, in
  context length).
- **API prices dropped 50%+**, effective immediately — long-context output at roughly
  **$0.42 per million tokens**. The efficiency win is passed straight to the bill.
- **Quality on par with V3.1-Terminus** across public benchmarks; the high-compute
  variant reaches gold-medal IMO/IOI performance. Sparsity here is not a quality
  *sacrifice* — it is removing wasted compute.

> **Why it matters:** this is the first time fine-grained, content-selected sparse
> attention shipped at frontier scale with a *published price cut attached*. Long context
> stopped being a spec-sheet number and became materially cheaper to serve. For the cost
> model of an agent — which lives or dies on context length — that 50% is the headline,
> not the FLOP count.

---

## 5. Sparsity must be trained in, not bolted on

The tempting shortcut is to take a dense-trained model and prune its attention at
inference (evict "unimportant" KV entries, attend to a heuristic window). It mostly
fails: a model trained to expect *full* attention degrades when you yank tokens out from
under it, because its weights encode an expectation the inference path no longer honours.

The 2025–2026 lesson, made explicit by **Native Sparse Attention (NSA)**, is that
sparsity has to be **natively trainable** — the selection mechanism is part of the model
and differentiable end-to-end, so the model *learns around* its own sparse pattern. NSA
combines three branches, gated together:

1. **Compressed tokens** — coarse-grained summaries of blocks, for cheap global context.
2. **Selected tokens** — fine-grained, content-chosen tokens, for precision.
3. **Sliding window** — recent tokens, for local fluency.

Pretrained *with* NSA from the start, the model **matches or exceeds full attention** on
general, long-context, and reasoning benchmarks while delivering large speedups across
**decoding, forward, and backward** passes on 64K sequences — and it is **hardware-aligned**
(custom Triton kernels), because naïve sparse attention is *slower* than dense on a GPU
due to irregular memory access. DSA reaches the same end differently: it initialises from
dense V3.1 and *continues training* with the sparse pattern (a dense→sparse warmup), so
the indexer learns to mimic dense attention's choices before the model leans on it.

> **Lesson:** the selector is a *learned component of the model*, not a post-hoc filter.
> This is why you cannot retrofit DSA-style efficiency onto an arbitrary open-weight model
> by changing serving config — and why the efficiency comes bundled with a *new
> training-time cost*, not a free inference toggle.

---

## 6. The selector is the new ceiling

Sparse attention relocates the risk. Dense attention can always see everything, so it
never misses a token for *structural* reasons; sparse attention can. The indexer/router
becomes the load-bearing failure point:

- **A miss is unrecoverable.** If the relevant token isn't in the top-k, Stage-2
  attention cannot attend to it — the needle is silently dropped. This is the exact
  analogue of the **verifier-is-the-ceiling** problem in
  [Test-Time Compute](Test-Time%20Compute%20—%20Spending%20Inference%20to%20Buy%20Reasoning.md):
  a cheap selector decides what the expensive stage even gets to see.
- **It cuts compute, not necessarily memory.** DSA still *stores* the full KV; it reads
  less of it. The bandwidth and FLOP win is real, but unless paired with KV compression
  (MLA) or eviction, the memory footprint of the cache is not what shrinks. Contrast
  linear attention, where the *state* itself is bounded.
- **Top-k hurts broad-aggregation tasks more than needle tasks.** "Summarise everything
  said about X across 300K tokens" wants many weakly-relevant tokens; a fixed k=2048
  starves it. Needle-retrieval, which wants *one* token, is exactly where top-k shines.
- **Kernels and tooling lag.** The speedup is only real with hardware-aligned kernels;
  the gap between "the paper's kernel" and "your serving stack" is where claimed
  speedups evaporate.

> **Architectural takeaway:** sparse attention buys cheap long context *if* the selector
> finds what matters. Validate recall on *your* task and *your* context positions — a
> published needle-in-haystack score with a favourable k does not tell you what happens
> when your needle sits just outside the selected set.

---

## 7. How it fits the stack

Sparse attention is one more lever in the per-token economics this track keeps mapping —
the *recall-preserving* sibling of linear attention:

| Lever | Question it answers | Note |
|---|---|---|
| **Read fewer tokens, keep recall** | "long context cheap, without losing the needle" | *this note* — sparse attention |
| **Replace attention with a state** | "long context cheap, accept lossy recall" | [Hybrid Mamba-Attention](Hybrid%20Mamba-Attention%20Models%20—%20Long-Context%20Efficiency%20for%20the%20Agent%20Era.md) |
| **Beat the per-token latency floor** | "decode faster than autoregression" | [Diffusion LLMs](Diffusion%20LLMs%20for%20the%20Agent%20Loop%20—%20Parallel%20Decoding%20and%20the%20Speed–Quality%20Pareto.md) |
| **Spend more to think** | "make this *answer* better" | [Test-Time Compute](Test-Time%20Compute%20—%20Spending%20Inference%20to%20Buy%20Reasoning.md) |
| **Right-size the model** | "don't pay frontier prices for easy work" | [Small Language Models for Agents](../5.%20AI%20Agents%20&%20Tool%20Use/Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md) |

For the harness builder the practical reading is:

- **Long context gets cheaper *and* keeps recall.** Unlike a pure linear/SSM hybrid, a
  sparse-attention model is the safer bet when the agent must quote an exact fact from
  deep in a long context. It raises — but does not remove — the threshold at which you
  must reach for [RAG](../4.%20RAG%20&%20Vector%20Databases/RAG%20Architectures.md): the
  model's own indexer is now doing a coarse retrieval *inside* attention.
- **The 50% price signal is the real one.** Cheaper long-context inference feeds straight
  into the heterogeneous cost model — it makes "keep the working set resident" affordable
  where chunk-and-retrieve was once mandatory.
- **More affordable window ≠ less context discipline.** The selector buys cheap rope; it
  does not decide what to put on it. Deliberate
  [context engineering](../5.%20AI%20Agents%20&%20Tool%20Use/Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md)
  still governs whether the right token is even *in* the haystack to be selected.

The settled 2026 skeleton is not "sparse vs linear" — it is **both, composed**:
sparse-or-linear sequence mixing for the bulk, a minority of full-attention checkpoints
for precision, MLA/GQA to shrink the KV, and a sparse MoE for capacity. Sparse attention
is the piece that lets you go long *without* trading away the one thing attention was
always best at.

---

## References

- [DeepSeek-AI — DeepSeek-V3.2: Pushing the Frontier of Open Large Language Models (arXiv 2512.02556)](https://arxiv.org/abs/2512.02556)
- [DeepSeek API — Introducing DeepSeek-V3.2-Exp (DSA, 50%+ price cut)](https://api-docs.deepseek.com/news/news250929)
- [Tensor Economics — DeepSeek Sparse Attention from First Principles](https://www.tensoreconomics.com/p/deepseek-sparse-attention-from-first)
- [Yuan et al. — Native Sparse Attention: Hardware-Aligned and Natively Trainable Sparse Attention (arXiv 2502.11089)](https://arxiv.org/abs/2502.11089)
- [Lu et al. — MoBA: Mixture of Block Attention for Long-Context LLMs (arXiv 2502.13189)](https://arxiv.org/abs/2502.13189)
- [Sebastian Raschka — A Dream of Spring for Open-Weight LLMs: 10 Architectures from Jan-Feb 2026](https://magazine.sebastianraschka.com/p/a-dream-of-spring-for-open-weight)
