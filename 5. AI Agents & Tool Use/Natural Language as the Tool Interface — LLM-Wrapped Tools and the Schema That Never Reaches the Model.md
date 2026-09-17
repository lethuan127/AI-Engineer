# Natural Language as the Tool Interface — LLM-Wrapped Tools and the Schema That Never Reaches the Model

> Source: HEART / Tool Primitives / ToolFace (arXiv 2609.01736, 2026-09-01). Companion to [Code Execution as the Tool-Calling Substrate](./Code%20Execution%20as%20the%20Tool-Calling%20Substrate%20—%20Programmatic%20Tool%20Calling.md) — the other proposal to stop putting JSON schemas in front of the model — and to [11.18. Tool Architecture — The Interface as a Behavioral Knob](../11.%20Harness%20Engineering/11.18.%20Tool%20Architecture%20%E2%80%94%20The%20Interface%20as%20a%20Behavioral%20Knob.md), which established that the interface moves behavior when capability is held fixed.

Every mainstream agent stack today puts a JSON Schema between the model and the world: the model emits an argument object, the runtime validates it, the function runs. This note covers a design that removes that contract entirely. Each tool is wrapped in its own LLM; the caller sends a sentence; the wrapper resolves the schema internally and returns a natural-language summary that the *next* wrapper reads as context. The raw schema never enters the orchestrator's prompt at all.

The reason to take it seriously is a single ablation number: strip the natural-language wrapper and hand the same orchestrator raw API schemas, and ToolBench average pass rate falls from **75.1 to 16.1**. That is not a tuning delta. It is the largest single-component effect reported anywhere in the tool-architecture literature so far, and it is worth understanding before deciding whether to believe it.

---

## 1. The move: the schema stops reaching the model

A **Tool Primitive** is an LLM-based wrapper around exactly one tool. It accepts a natural-language invocation request, resolves the schema internally, executes the function, and returns a structured result. Formally, given a registry of schema–function pairs `𝒯 = {(sᵢ, fᵢ)}`, a single shared base model `ℳ` is conditioned per-tool at inference time:

```text
𝒫ᵢ(x; c) = ℳ([sᵢ ; c ; x])

  sᵢ  the tool's schema — supplied to the wrapper, never to the caller
  c   optional upstream context (the previous primitive's result)
  x   the caller's natural-language request
```

All primitives share one base model. The per-tool specialization is entirely in what gets concatenated into the wrapper's prompt, which is why the design scales to a catalog of tens of thousands without training a model per tool.

Inside the wrapper, schema resolution is an explicit job list: extract the intended operation and described values, coerce types (string→integer, date normalization, unit conversion), match enums, apply required-field and range and format validation, fill defaults, and bind any `$step_j.<field>` reference to the upstream result.

The output contract is what makes chaining work:

```json
{ "status": "SUCCESS", "tool": "...", "bound_arguments": {...},
  "result": {...}, "summary": "natural-language rendering of the result" }

{ "status": "FAILURE", "tool": "...", "details": "...",
  "failure_type": "SCHEMA_RESOLUTION | CONSTRAINT_VIOLATION | RUNTIME_ERROR",
  "bound_arguments": {...} }
```

The `summary` field is the load-bearing part. It exists so a result can be passed as upstream context to the next primitive **without the orchestrator holding intermediate state**. Chaining is not JSON plumbing between typed values; it is one wrapper LLM reading another wrapper's prose.

Two rules keep this from becoming an uncontrolled mesh. A primitive must never call another tool, never modify the plan, and never retry silently — errors stay local and surface as a typed `FAILURE`. And the wrapper must not be handed a pre-built argument dictionary; argument binding is the wrapper's job, not the caller's.

> Architectural takeaway: the schema does not disappear — it moves. It stops being a contract the reasoning model must satisfy and becomes an implementation detail of a tiny per-tool model that has exactly one schema in its context. The orchestrator's context stops scaling with the size of the tool catalog.

## 2. The registry: 25,519 tools that are never enumerated

**ToolFace** is a central registry of hand-authored schema–function pairs. Composition:

| Source | Count | What it contributes |
|---|---|---|
| ToolBench | 16,464 | Live APIs across 49 functional categories |
| ACEBench | 4,538 | Bilingual APIs, 8 domains / 68 sub-categories |
| NESTFUL (coding) | 4,348 | Coding tools |
| τ²-Bench | 68 | Retail, airline, telecom |
| Hand-authored | 54 | Form filling, button clicking, page analysis |
| NESTFUL (math) | 40 | Mathematical reasoning tools |
| BFCLv4 | 7 | Web search (2), memory (5) |

Tools are pulled at inference time by "semantic search over tool schema descriptors." That sentence is the *entire* stated retrieval mechanism. No top-k, no embedding model, no index type, no reranker, no retrieval recall or precision, no latency or storage accounting for the index itself. For a design whose central claim is that you can hold 25k tools without enumerating them, this is the thinnest load-bearing component in the paper.

> Why it matters: the retrieval layer is where this architecture will actually fail in production, and it is the one layer the paper does not measure. If semantic search over descriptors misses the right tool, the Planner never learns the tool exists — there is no fallback to enumeration, because enumeration is the thing being eliminated.

## 3. Four roles, one 8B backbone

HEART runs Planning → Routing → Execution → Verification, with all four roles served by the same Qwen3-8B by default.

| Role | Input → Output | The one thing it is not allowed to do |
|---|---|---|
| **Planner** | `(query, context) → sufficient/insufficient`, then an ordered plan `Π = (π₁…π_K)` | Emit argument *values* — plan steps carry only `tool_hint`, `objective`, `dependencies` |
| **Router** | `(step, context) → (natural-language request, execution hyperparameters)` | Invent a value not grounded in context; override the Planner's tool choice; emit a schema-compliant argument dict |
| **Tool Primitive** | `(request, upstream context) → SUCCESS/FAILURE + summary` | Call another tool, re-plan, or self-recover |
| **Verifier** | `(result, step, schema) → pass/fail` on four independent criteria | — (any single criterion failing fails the step) |

On `insufficient`, the Planner emits exactly one targeted clarification question to the user and loops. The Router additionally carries per-step execution hyperparameters — `retry` ∈ [1,5] ("higher values for safety- or finance-critical actions"), `priority`, `timeout_s` (default 30) — which is a nice detail: risk tolerance is a per-step routing decision, not a global harness setting.

The Verifier's four criteria are worth copying regardless of whether you adopt the rest:

1. **Task completion** — does the result satisfy the step's stated objective?
2. **Argument consistency** — are the bound arguments consistent with user intent *and* schema constraints?
3. **Execution validity** — no runtime error, return conforms to the output schema.
4. **Constraint satisfaction** — rate limits, access permissions, business rules.

On failure, actionable feedback (the paper's own example: `wrong argument type for card_id: expected int, received str`) is appended to context and the **entire plan is re-planned**, not just the failed step. Budget `B = 3`; on exhaustion the system returns a failure report rather than a best-effort answer.

That whole-plan re-planning choice is defensible — a step failure is often evidence the decomposition was wrong — but it means a late failure discards all upstream work, and the paper does not report the cost of that.

## 4. The ablation is the note

Every other number here is a benchmark delta over baselines that were not tuned for these tasks. The ablation is the part that constrains design.

| Variant | ToolBench Pass | ToolBench Win | NESTFUL Full Acc | NESTFUL Win |
|---|---|---|---|---|
| **HEART (full)** | **75.1** | **75.7** | **0.44** | **0.75** |
| w/o Router | 62.4 | 67.3 | 0.28 | 0.52 |
| w/o Planner | 57.2 | 64.1 | 0.26 | 0.51 |
| w/o Verifier | 47.6 | 49.6 | 0.15 | 0.33 |
| **w/o ToolFace & Tool Primitives** | **16.1** | **27.9** | **0.06** | **0.06** |

The last row exposes raw API schemas directly to the Router. Removing the orchestration roles costs 13–28 points; removing the natural-language interface costs 59.

Re-planning budget saturates fast — `B=0` reproduces the no-Verifier row exactly (47.6), `B=2` reaches 65.9, `B=3` reaches 75.1, and `B=5` adds 0.2. Three rounds is the whole benefit.

> Lesson: the two components that matter are the interface and the feedback loop. Planner and Router are refinements. If you are borrowing one idea from this paper, borrow the Verifier — a typed pass/fail with actionable feedback and a bounded re-plan budget is cheap to add to an existing stack and accounts for the second-largest effect measured.

The one thing the ablation cannot tell you: **ToolFace and Tool Primitives are removed together as a single variant.** So "retrieval instead of full-catalog enumeration" and "natural-language wrapper instead of raw schema" are confounded. The 75.1 → 16.1 collapse is attributable to the pair, not to either one. Given that the baseline condition is dumping schemas from a 25k catalog at an 8B model, a large part of that gap is plausibly context pressure rather than interface design — and the paper does not separate them.

## 5. What it costs

The headline economics are real but narrower than "85% cheaper" suggests.

| Axis | HEART (Qwen3-8B) | Best commercial baseline | Read |
|---|---|---|---|
| τ²-Bench Retail Pass4 | 0.73 | 0.60 (Claude-4.6-Sonnet) | Gap widens with k — the design buys *repeatability*, not peak accuracy |
| Tokens / task (Retail) | 21,684 | ~7,153 | **~3× more tokens.** Four LLM roles plus one LLM per tool call |
| API cost / task (Retail) | $0.0152 | $0.1073 | Cheaper only because the backbone is $0.18/$0.70 per 1M vs $2.50/$15.00 |
| Latency (Retail) | 18.72 s | 14.12 s | Slower than every baseline in every domain |

The cost win is a **model-price arbitrage, not an efficiency win**: three times the tokens at a twentieth of the price. Swap the backbone to GPT-5.4 across all four roles and per-task Retail cost goes to $0.30684 — twice the frontier baseline — for four points of Pass1. The design's economics depend entirely on a small model being adequate for schema resolution, which is exactly the [SLM-first heterogeneous architecture](./Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md) applied one level down, at the tool boundary.

The hybrid config (frontier Planner/Router/Verifier, 8B primitives) lands at $0.19666 and is the paper's argument that the two layers scale independently. That is the practically interesting configuration and it gets one table.

Two costs the authors name, and one they measure but do not name:

- **Manual schema curation.** All 25,519 schemas are hand-authored "to ensure interface quality." Extending to a new domain is curation work, not integration work. There is no code or registry release.
- **Token consumption.** Explicitly flagged: "practitioners with stricter latency budgets may need to consolidate roles."
- **Per-primitive inference latency is never isolated.** The wall-clock overhead is visible in the tables but is nowhere decomposed into "cost of running an LLM per tool call." For a design that adds a model invocation to every single tool call, that is the number a reader most needs.

## 6. The security claim, read carefully

Under ToolHijacker-style prompt injection at the tool-selection stage, attack success rate is reported as **0.0%** for HEART against 66.0–82.2% for the three frontier baselines. The stated mechanism is structural: tool schemas live in ToolFace and are invoked through primitives, "never appearing in the LLM's input prompt," so the poisoned-tool-description vector is eliminated by construction.

The mechanism is sound as far as it goes, and the scope is narrow in a way the number does not advertise:

- The threat model is **tool-selection-stage injection only**. The paper says so: "broader threat models, such as compromised tool outputs, remain to be studied."
- Compromised tool *output* is the vector this architecture arguably worsens, not improves. A primitive's `summary` is free-form prose generated from a tool result and fed directly into the next primitive's context. That is a natural-language channel between two LLMs with no schema constraining it — the exact shape that [Tool-Call Reliability](./Tool-Call%20Reliability%20—%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md) and [8.1. Agent Containment & Control](../8.%20AI%20Safety%20%26%20Ethics/8.1.%20Agent%20Containment%20%26%20Control%20—%20Capping%20the%20Blast%20Radius.md) treat as untrusted input.
- HEART's own no-attack accuracy in that table is reported as "–", so the injection result has no clean-condition control alongside it.

> Why it matters: "0% ASR by construction" is a claim about *where schemas live*, not about whether the agent can be steered. Moving the tool description out of the orchestrator's prompt closes one door and installs a prose pipe between every pair of chained tools.

## 7. Three substrates, one axis

The repo now has three distinct answers to "what does the model emit when it wants a tool to run."

| Substrate | Model emits | Context cost scales with | Buys | Pays |
|---|---|---|---|---|
| **JSON schema** (mainstream) | A validated argument object | Number of tools exposed | Determinism, auditability, mature tooling | Context pressure at scale; brittle multi-step type mismatch |
| **[Code execution](./Code%20Execution%20as%20the%20Tool-Calling%20Substrate%20—%20Programmatic%20Tool%20Calling.md)** | A program that calls many tools | Size of the API surface imported | ~40% fewer steps, ~56% fewer tokens, filtering before context | A sandbox, and a model good enough to write correct code |
| **Natural language** (this note) | A sentence per tool call | Nothing — schemas never enter the prompt | Catalog scale; repeatability under repeated attempts | ~3× tokens, an LLM per call, hand-authored schemas, an unmeasured retrieval layer |

Note that two of the three eliminate the schema from the model's context, by opposite means: code execution replaces enumeration with an importable API surface the model reads on demand; tool primitives replace it with retrieval plus delegation. Both are betting that the reasoning model should not be holding the tool catalog. The disagreement is whether the intermediate representation should be code (typed, deterministic, composable) or prose (untyped, model-mediated, tolerant of schema mismatch).

## 8. What to take now, what to wait for

**Take now:**

1. **The Verifier pattern.** Four independent criteria, typed feedback, bounded re-plan budget, saturating at three rounds. Drops into any existing stack; second-largest measured effect; no architectural commitment.
2. **The plan/argument split.** A planner that emits objectives and tool hints but no values, with argument resolution as a separate stage, is a clean separation whether or not the resolution stage is an LLM.
3. **Per-step execution hyperparameters.** Retry count as a function of how consequential the step is — rather than one global retry policy — is the right shape.

**Wait for:**

1. **A retrieval ablation.** Until ToolFace and Tool Primitives are ablated separately, the 59-point gap is unattributed.
2. **A per-call latency decomposition.** Adding a model invocation to every tool call is the entire design; its cost is the entire question.
3. **Replication above 8B, and outside curated registries.** All schemas are hand-authored by the authors. The result is that agents do well against tools whose interfaces were written for them.

A caution on citation hygiene: the paper has several internal inconsistencies — §4.2 states BFCLv4 web-search overall as 84.0% where Table 5 says 86.00; §4.5 attributes the 0.0% ASR to the *ablated* variant rather than to HEART; one Table 12 row has a non-monotone Pass₃ > Pass₂; and the "+51.5% in Telecom" figure is a relative gain (0.50 vs 0.33) where surrounding deltas are percentage points. Quote the tables, not the prose.

> Architectural takeaway: the interesting claim is not that this framework beats GPT-5.4 by six points. It is that an 8B model with the right interface beats frontier models at *executing* rather than recommending — 84% vs 20–24% task completion on the 50 real-world tasks — and that the interface, not the orchestration, is where the effect lives. If that replicates, the tool layer is a bigger lever than the model choice, which is the same conclusion [11.18](../11.%20Harness%20Engineering/11.18.%20Tool%20Architecture%20%E2%80%94%20The%20Interface%20as%20a%20Behavioral%20Knob.md) reached from a controlled experiment and [11.14](../11.%20Harness%20Engineering/11.14.%20Tuning%20the%20Harness%2C%20Not%20the%20Model%20%E2%80%94%20The%20Harness%20as%20an%20Optimization%20Surface.md) reached from first principles.

---

## References

- [arXiv — Harness Engineering in LLM Tool Use via Agent-Native Reusable Tool Primitives](https://arxiv.org/abs/2609.01736)
- [arXiv — The Devil Is in the Interface: Evaluating How Tool Architecture Shapes Coding Agent Behavior](https://arxiv.org/abs/2608.11386)
- [Anthropic — Code Execution with MCP: Building More Efficient Agents](https://www.anthropic.com/engineering/code-execution-with-mcp)
