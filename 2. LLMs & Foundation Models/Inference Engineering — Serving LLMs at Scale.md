# Inference Engineering — Serving LLMs at Scale

> The other notes in this track are about the *model*: fewer FLOPs per token
> ([Hybrid Mamba-Attention](Hybrid%20Mamba-Attention%20Models%20—%20Long-Context%20Efficiency%20for%20the%20Agent%20Era.md),
> [Sparse Attention](Sparse%20Attention%20—%20Long-Context%20Without%20Giving%20Up%20Recall.md)),
> a different decoding scheme
> ([Diffusion LLMs](Diffusion%20LLMs%20for%20the%20Agent%20Loop%20—%20Parallel%20Decoding%20and%20the%20Speed–Quality%20Pareto.md)),
> or spending more of it per request
> ([Test-Time Compute](Test-Time%20Compute%20—%20Spending%20Inference%20to%20Buy%20Reasoning.md)).
> This note is about the layer underneath all of them: given a fixed model,
> how do you actually run it for thousands of concurrent users without wasting
> the GPU it's sitting on? That is a systems-engineering problem, not a modeling
> one, and it has its own primitives, its own failure modes, and its own
> vendors.

Inference engineering is the discipline of serving trained model weights in
production — distinct from the ML engineering that produces those weights.
Training happens once (or periodically); inference runs on every request,
every second, forever, and its cost is what shows up on the cloud bill every
month. The job sits at the intersection of systems engineering and FinOps:
scheduling, memory management, and hardware utilization, with model quality
held fixed.

> **Why it matters:** a model that is 2% more accurate is a research result. A
> serving stack that is 2× more efficient is the same accuracy at half the
> GPU spend, or double the concurrent users on the same fleet. Past a certain
> scale, inference engineering has a bigger effect on unit economics than
> almost any modeling decision.

---

## 1. The metrics that define the problem

Three numbers, not one, describe inference quality — optimizing only for one
degrades the others:

| Metric | What it measures | Who feels it |
|---|---|---|
| **TTFT** (Time To First Token) | prompt processing (prefill) latency | perceived responsiveness — "is it stuck?" |
| **ITL** / **TPOT** (Inter-Token Latency / Time Per Output Token) | per-token decode latency | perceived streaming speed |
| **Throughput** (tokens/sec, requests/sec) | aggregate GPU output | cost per token, fleet size needed |

Prefill and decode have opposite bottleneck profiles, which is the single
fact that explains most of the architecture in this note: **prefill is
compute-bound** (the whole prompt is known, so it parallelizes across GPU
cores) and **decode is memory-bound** (one token at a time, dominated by
reading the KV cache and weights from HBM). A technique that helps one often
hurts the other.

---

## 2. Memory: KV cache as the scarce resource

Autoregressive decoding caches the key/value tensors of every prior token so
each new token doesn't recompute attention over the whole prefix. That cache
grows linearly with sequence length and batch size, and on a modern GPU it —
not model weights — is usually what runs out first.

**PagedAttention** (the vLLM paper) is the fix that made continuous batching
practical: instead of pre-allocating one contiguous KV buffer per request
(the OS-style bug this repeats: reserve for worst case, waste the rest),
it splits each sequence's cache into fixed-size blocks, allocates them
non-contiguously, and maps logical positions to physical blocks through a
page table — the same trick as OS virtual memory. Consequences:

- **Near-zero fragmentation waste**, vs. the 60–80% typically lost to
  over-reservation in naive contiguous allocation.
- **Prefix sharing**: requests with an identical prefix (a shared system
  prompt, few-shot examples, a RAG template) point at the *same* physical
  blocks — copy-on-write only where sequences diverge.
- The reported result: **2–4× throughput** over the contiguous-allocation
  systems that preceded it, at the same latency.

**RadixAttention** (SGLang) generalizes the same idea from "one prefix" to
**automatic reuse across a tree of overlapping prefixes**, indexed with a
radix tree and an LRU eviction policy — the natural shape for chat histories,
multi-turn agents, and few-shot templates where many requests share a common
ancestor but diverge at different points. This is *why* SGLang tends to win
specifically on shared-context workloads (chat, RAG, agent loops) even where
raw single-request throughput ties with vLLM.

> **Architectural takeaway:** KV cache management is the inference-time
> analogue of the context-window economics in
> [Hybrid Mamba-Attention](Hybrid%20Mamba-Attention%20Models%20—%20Long-Context%20Efficiency%20for%20the%20Agent%20Era.md) —
> that note fixes the *asymptotic* cost of attention by changing the
> architecture; this layer fixes the *constant-factor* waste in how the
> cache for a fixed architecture is stored and shared.

---

## 3. Scheduling: continuous batching and chunked prefill

Static (request-level) batching waits for a full batch to *finish* before
accepting new requests — one long-running sequence in the batch stalls
everyone behind it, and GPU sits idle waiting for the next batch to fill.

**Continuous batching** (aka iteration-level scheduling) schedules at the
*token* level instead: after every decode step, any request that finished
leaves the batch and any queued request can join, filling the freed slot
immediately. Tail latency drops and GPU utilization rises because the batch
composition is never blocked on the slowest member.

**Chunked prefill** solves the problem continuous batching alone doesn't:
a long prompt's prefill is one large compute-bound step that, run whole,
blocks decode steps for every other in-flight request. Chunking splits that
prefill into pieces and interleaves them with other requests' decode steps,
so no single long prompt starves the rest of the batch of tokens.

```text
Static batching:            Continuous batching + chunked prefill:
[ r1 r2 r3 r4 ] → wait      [ r1  r2  chunk(r5) r3 ] → step
     (idle GPU while             [ r1  r4-done→r6  r2  r3 ] → step
      r3 still runs)                  (slots refill every step)
```

> **Lesson:** neither technique is model-specific — they're pure scheduling.
> That's why they're implemented once, in the serving framework, and every
> model that framework hosts benefits. This is the part of "inference
> engineering" that has nothing to do with ML at all; it's a job scheduler
> with attention-shaped work units.

---

## 4. Speculative decoding: buying decode-bound latency back

Decode is memory-bound — most of the GPU's compute sits idle while one token
at a time streams out. Speculative decoding spends that idle compute: a
cheap **draft** mechanism proposes several candidate tokens, and the full
model **verifies** all of them in a single parallel forward pass — closer
to a prefill-shaped (compute-bound, parallel) workload than a decode-shaped
one.

**EAGLE / EAGLE-2** is the dominant 2026 approach and a good illustration of
where the field converged: instead of a whole second draft *model*, a
lightweight autoregressive head predicts the next token from the target
model's own hidden-state features, then builds a **draft tree** (multiple
candidate continuations, not one linear guess) sized by confidence. The
target model verifies the *entire tree* in one pass using tree attention (a
structured mask so each candidate only attends along its own root-to-leaf
path), accepts the longest valid prefix, and resamples a correction token
from the residual distribution at the point of divergence — mathematically
identical output distribution to standard decoding, just fewer serial steps
to get there. EAGLE-2's dynamic (confidence-driven) tree reports **3–4×**
speedups over plain autoregressive decoding.

> **Why it matters:** speculative decoding is a *latency* trade, not a
> throughput one — it doesn't create free compute, it reallocates idle
> compute from the decode-bound regime into a verification pass. It pays off
> most when the draft's acceptance rate is high (predictable continuations:
> code, templated text) and least when the model is genuinely uncertain
> every token (open-ended creative generation) — the acceptance rate *is*
> the return on the technique.

This is a different speculation from
[Speculative Execution in the Agent Loop](../5.%20AI%20Agents%20&%20Tool%20Use/Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md):
that note predicts-and-verifies at the *tool-call* granularity inside an
agent harness; this one predicts-and-verifies at the *token* granularity
inside a single forward pass. Same predict/verify shape, two different
layers of the stack.

---

## 5. Quantization: trading precision for memory and speed

Lowering numerical precision (FP16 → FP8 → INT4) shrinks the memory
footprint of both weights and KV cache and speeds up the memory-bound decode
phase — each precision step down reports roughly **30–50%** latency
improvement. The cost is quality: quantization error is a per-token
approximation, and it **compounds over long sequences**, which is why
quantized long-context serving needs more careful calibration (and why the
first thing to check when a quantized model "seems fine" is a *long* eval,
not a short one). FP8 has become close to a free lunch on modern
accelerators (native hardware support, minimal measured quality loss on most
tasks); INT4 is a real quality/cost tradeoff decision, not a default.

---

## 6. Parallelism: spreading one model across many GPUs

When a model doesn't fit — or shouldn't run — on a single GPU:

| Strategy | Splits | Best for | Cost |
|---|---|---|---|
| **Tensor Parallelism (TP)** | each layer's matrices, across GPUs | dense models too large for one GPU | needs fast interconnect (NVLink) — an all-reduce every layer |
| **Expert Parallelism (EP)** | individual experts in an MoE, one (or a few) per GPU | large MoE models (most 2026 frontier models) | scales better with *limited* interconnect bandwidth than TP does, since only routed tokens cross GPUs |

MoE serving is now the common case, not the exception, which is why EP
tuning — not just TP — is a first-class serving decision in 2026 stacks.

---

## 7. Disaggregation: stop forcing one GPU to do two jobs

Prefill (compute-bound, parallel) and decode (memory-bound, sequential) want
opposite things from hardware and batching policy. Running both phases on
the same GPU means one phase's batch is always compromising the other's.

**Disaggregated serving** splits them onto separate worker pools — a prefill
pool tuned for compute throughput, a decode pool tuned for memory bandwidth
and batch depth — and transfers the computed KV cache between them over
RDMA / NVLink once prefill finishes. **NVIDIA Dynamo** is the reference
implementation of this pattern in 2026: it sits *above* vLLM or SGLang as an
orchestration layer (it doesn't replace their kernels, it routes work between
disaggregated pools of them) and reports up to **30× throughput** on
DeepSeek-R1 671B on GB200 NVL72, and **>2×** on Llama 70B on Hopper, versus
co-located prefill+decode on the same GPUs.

```text
Co-located (one GPU pool):         Disaggregated:
  [ prefill + decode interleaved ]   [ prefill pool ] --KV cache (RDMA)--> [ decode pool ]
  compute and memory contend          each pool tuned + scaled independently
```

> **Architectural takeaway:** disaggregation is what "inference engineering"
> looks like once you stop treating a GPU as one resource and start treating
> compute-bound and memory-bound work as two resources that happen to share
> silicon. It's the serving-layer version of separating read and write paths
> in a database — same data, different access pattern, different tuning.

---

## 8. The 2026 framework landscape

Continuous batching, paged KV caching, and FP8 quantization are table
stakes now — every serving framework worth considering has them. The real
differentiator is the *primary* optimization each one is built around:

| Framework | Core trick | Wins on | Cost |
|---|---|---|---|
| **vLLM** | PagedAttention | broad hardware support (NVIDIA, AMD, TPU); the default choice absent a specific reason otherwise | not the fastest on any single axis |
| **SGLang** | RadixAttention (prefix-tree KV reuse) | shared-context workloads — chat, RAG, agent loops (~29% over vLLM when context overlaps) | less advantage on single-shot, non-overlapping requests |
| **TensorRT-LLM** | ahead-of-time compiled CUDA engines | peak throughput on NVIDIA hardware (15–30% over vLLM); Blackwell-class GPUs | NVIDIA-only; ~tens of minutes of engine compilation per model, so it fits stable model / long-lived deployments, not rapid iteration |
| **NVIDIA Dynamo** | disaggregated prefill/decode orchestration, above vLLM/SGLang | very large-scale, latency-sensitive reasoning-model serving | added operational complexity (KV transport, two pools to run and scale) — worth it past a scale where co-location's contention dominates |

> **Lesson:** picking a framework is picking which workload shape you're
> betting on, not which one is "best." A team serving one stable model at
> huge scale on NVIDIA hardware wants TensorRT-LLM (or Dynamo on top of it);
> a team serving many models, iterating weekly, on mixed hardware wants
> vLLM; a team whose traffic is dominated by shared context (chat, agents)
> gets a specific, measurable win from SGLang.

Every framework above assumes the same silicon: a GPU where decode is
memory-bound because weights and KV cache live in HBM and every token pays
the round-trip to fetch them. **OpenAI's Ultrafast tier for GPT-5.6 Sol**
(2026-08-13, built on Cerebras' Wafer-Scale Engine) is the clearest 2026
demonstration that this bottleneck is a hardware choice, not a law: keeping
weights in ~44GB of on-chip SRAM instead of off-chip HBM removes the
data-movement cost that PagedAttention, continuous batching, and
speculative decoding all exist to work around, and reports **~750 tok/s**
against a ~53 tok/s GPU baseline for the same model — roughly 14×, at
unchanged quality. The tradeoff is the mirror image of TensorRT-LLM's:
wafer-scale silicon is scarcer and pricier per chip than commodity GPUs,
so it targets the same niche as Dynamo — the tail of requests where
latency is worth paying for — not general-purpose fleet serving.

> **Architectural takeaway:** every technique in §2–§5 is optimizing
> *around* the HBM round-trip. Wafer-scale SRAM is the one lever that
> removes the round-trip instead — worth knowing about specifically because
> it changes which problem you're solving: not "schedule and cache better"
> but "put the weights somewhere the bottleneck doesn't exist."

---

## 9. How it fits the stack

| Lever | Layer | Note |
|---|---|---|
| **Serve the fixed model efficiently** | systems/scheduling | *this note* |
| **Make the model cheaper per token** | architecture | [Hybrid Mamba-Attention](Hybrid%20Mamba-Attention%20Models%20—%20Long-Context%20Efficiency%20for%20the%20Agent%20Era.md), [Sparse Attention](Sparse%20Attention%20—%20Long-Context%20Without%20Giving%20Up%20Recall.md) |
| **Make the model faster per token** | decoding scheme | [Diffusion LLMs for the Agent Loop](Diffusion%20LLMs%20for%20the%20Agent%20Loop%20—%20Parallel%20Decoding%20and%20the%20Speed–Quality%20Pareto.md) |
| **Spend more inference to get a better answer** | request-time policy | [Test-Time Compute](Test-Time%20Compute%20—%20Spending%20Inference%20to%20Buy%20Reasoning.md) |
| **Hide latency at the tool-call level** | agent harness | [Speculative Execution in the Agent Loop](../5.%20AI%20Agents%20&%20Tool%20Use/Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md) |

A production system composes all five: a serving stack (this note) hosts a
model chosen for its architecture-level cost profile, decoded with whatever
scheme fits the latency/quality point, given a test-time compute budget
sized to the request, inside an agent harness that hides its own latency on
top. None of these layers substitute for the others — inference engineering
is the floor the other four stand on.

---

## References

- [Pragmatic Engineer — What is inference engineering?](https://newsletter.pragmaticengineer.com/p/what-is-inference-engineering)
- [Kwon et al. — Efficient Memory Management for Large Language Model Serving with PagedAttention (arXiv 2309.06180)](https://arxiv.org/abs/2309.06180)
- [Zheng et al. — SGLang: Efficient Execution of Structured Language Model Programs (arXiv 2312.07104)](https://arxiv.org/abs/2312.07104)
- [Li et al. — EAGLE-2: Faster Inference of Language Models with Dynamic Draft Trees (arXiv 2406.16858)](https://arxiv.org/abs/2406.16858)
- [NVIDIA — Introducing NVIDIA Dynamo, A Low-Latency Distributed Inference Framework for Scaling Reasoning AI Models](https://developer.nvidia.com/blog/introducing-nvidia-dynamo-a-low-latency-distributed-inference-framework-for-scaling-reasoning-ai-models)
- [Cerebras — Accelerating GPT-5.6 Sol Ultrafast with OpenAI](https://www.cerebras.ai/blog/accelerating-gpt-5-6-sol-ultrafast-with-openai)
