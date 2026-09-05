# Context as an Environment — Session State as an Executable Namespace

> **Source:** Lin, Ang, Zhu, Ding & Zhou, *Context as an Environment: Programmatic
> Context Management for Long-Horizon Agents* (arXiv:2608.21690, 21 Aug 2026).
> Companion to
> [Context Compaction Theory — Selection, Generation, and the Budget Lower Bound](./Context%20Compaction%20Theory%20—%20Selection%2C%20Generation%2C%20and%20the%20Budget%20Lower%20Bound.md),
> which proves what compaction cannot preserve, and
> [Context Window Management — Eviction, Compaction & Memory](./Context%20Window%20Management%20—%20Eviction%2C%20Compaction%20%26%20Memory.md),
> which covers the five levers. This note covers the design that tries to make the
> compaction question moot.

Compaction theory's conclusion was an instruction: for workloads that provably cannot
survive a summarizer, *put the state in a tool*. This paper is the systems answer to
that instruction taken to its limit. Instead of a tool that stores state beside the
prompt, the session **is** a program: an append-only Event Log plus a live Python
kernel whose namespace persists across model calls. Tool outputs bind to variables.
Only what the model explicitly prints enters the next prompt. Compaction stops being
a lossy decision made under time pressure and becomes a `print()` statement.

---

## 1. The commitment problem it dodges

Every compaction scheme commits before the query arrives. The harness decides what to
keep at 95% occupancy; the question that needs the discarded bytes shows up three
turns later. Summarizers and memory extractors both freeze a representation *ahead of
demand* — that is the whole source of the information-theoretic floor.

The escape is not a better summarizer. It is refusing to make the commitment at all:
keep everything losslessly outside the window, and make the *view* into it cheap,
programmatic, and re-derivable on demand.

| Approach | When the "what to keep" decision is made | Recoverable? |
|---|---|---|
| Truncation (`SELECT`) | At overflow, by policy | No — bytes are gone from the loop |
| Summarization (`GEN`) | At overflow, by a model | No — only what the prose happened to mention |
| Fixed memory extraction | At write time, by a schema | Only what the schema anticipated |
| Session Environment | Never — deferred to read time | Yes — the log is lossless |

> **Why it matters:** the first three rows are all *encoders* choosing a code before
> seeing the message. The fourth is a filesystem. You cannot beat a lower bound on
> encoding; you can decline to encode.

## 2. The three moves

### 2.1. An append-only Event Log

Every turn, tool result, and derived artifact is appended to a log that is never
rewritten. This is the same invariant a cache-efficient harness already needs — see
[11.8. Context Engineering in the Harness §2.1](../11.%20Harness%20Engineering/11.8.%20Context%20Engineering%20in%20the%20Harness.md)
— and the same one durable-execution designs need to replay a crashed loop, per
[7.3. Durable Execution for Agents](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md).
Here it earns a third job: it is the ground truth that makes eviction safe.

### 2.2. A persistent kernel with a typed namespace

A sandboxed Python kernel lives for the session and holds a typed namespace across
model calls. A 200K-token tool result becomes `results` — a variable — not 200K tokens
of serialized JSON re-sent on every subsequent turn.

```python
# Turn 7: the tool result lands in the namespace, not the prompt.
rows = db.query("...")            # 180K tokens of JSON, zero tokens in context
print(len(rows), rows[0].keys())  # 40 tokens in context

# Turn 12: the model needs a different slice. No re-fetch, no re-summarize.
print([r.id for r in rows if r.status == "failed"][:20])
```

This is the same substrate argument as
[Code Execution as the Tool-Calling Substrate](../5.%20AI%20Agents%20%26%20Tool%20Use/Code%20Execution%20as%20the%20Tool-Calling%20Substrate%20—%20Programmatic%20Tool%20Calling.md),
pushed one layer out. That note makes *tool invocation* programmatic. This makes
*session state* programmatic. The bet is identical and worth naming: context
management inherits the model's coding ability, which is the capability curve
improving fastest, rather than its summarization ability, which is not a skill anyone
is optimizing directly.

### 2.3. Projections, not serialization

The model writes code that searches, materializes, and transforms session state via
`exec`. Only explicitly printed output enters the working view for the next call. The
prompt becomes a *rendered projection* of state rather than a transcript of it — and
the projection is query-conditioned, because by the time the model prints, it knows
what it is looking for.

> **Architectural takeaway:** this converts compaction from one-way communication
> (encode now, decode later, no query) into ordinary retrieval (query now, fetch now).
> That is the whole trick. The lower bounds in compaction theory bind the first
> regime and say nothing about the second.

## 3. Eviction with an index, not a summary

The working view still has a budget, so stale spans still get evicted. The difference
is what eviction leaves behind: an **eviction index** of compact landmarks, each tied
to an exact Event Log address. The agent navigates *directly* to an evicted region
instead of searching the whole log.

| | Summary-based compaction | Eviction index |
|---|---|---|
| Residue in context | Prose recap | Landmark + log address |
| Recovery of exact bytes | Impossible | `O(1)` seek |
| Cost of being wrong about relevance | Permanent loss | One extra read |
| Failure mode | Silent omission | Latency |

That last row is the one to internalize. Summarization's failure mode is a quiet
wrong answer; addressed eviction's failure mode is a slower right one. For anything
with a governance or correctness constraint, trading correctness failures for latency
failures is close to always the right trade.

Compare the memory-tier framing in
[Agent Memory Architectures — Tiered, Vector, Temporal-Graph](../5.%20AI%20Agents%20%26%20Tool%20Use/Agent%20Memory%20Architectures%20—%20Tiered%2C%20Vector%2C%20Temporal-Graph.md):
a vector store also recovers evicted content, but by *similarity*, which can miss. An
address cannot miss. Semantic recall and addressed recall are different guarantees and
a serious harness wants both.

## 4. The neighbours, and what separates them

Three concurrent designs attack the same problem from different angles. The axis that
actually separates them is **who decides, and whether the discarded bytes survive**.

| Design | Mechanism | Decision maker | Lossless? |
|---|---|---|---|
| Harness compaction (Codex, Claude Code) | Threshold fires, model summarizes | Harness policy | No |
| ACM (arXiv:2607.23809) | Purpose-built context-editing tools; offload to external memory, query on demand | The model, autonomously | Yes |
| Session Environment (Scroll) | Executable namespace + Event Log + eviction index | The model, by writing code | Yes |

ACM and Scroll agree on the important thing — the model should decide when and what to
compress, because a fixed threshold is misaligned with where its reasoning currently
is — and disagree on the interface. ACM gives the model *tools* for context editing.
Scroll gives it a *language*. The tool interface is easier to bolt onto a shipped
harness; the language interface composes better, because transformations the tool
designer never anticipated are just code the model writes.

> **Lesson:** the trend line across all three is the same. Context management is
> migrating from harness policy into model behavior. Threshold-triggered compaction is
> going to look like manual memory management does now.

## 5. The reported numbers, and how to read them

With Qwen3.8-Max as the backbone: 94.8% on `LongMemEval_S`; 73.1% on `BEAM_10M`,
+5.1 points over the best published memory system; 86.7% on `LOCA_256K`, +37.4 points
over the best published long-horizon agent.

The gap sizes are the signal, not the absolute scores. A 5-point win on a memory
benchmark is a better memory system. A 37-point win on a long-horizon benchmark is not
a better version of the same thing — it says the incumbent approach was structurally
losing information those tasks needed, which is exactly what the compaction lower
bounds predict for tasks with an exact-recall component. Treat the single-backbone
evaluation as the obvious caveat: none of this is demonstrated to transfer across
model families yet.

## 6. What this costs

Nothing here is free, and the costs are all in the harness, not the model.

| Cost | Detail |
|---|---|
| A sandbox on the critical path | A persistent kernel per session is now a stateful, long-lived, untrusted-code-executing dependency. See [8.4. The Agent Containment Toolchain](../8.%20AI%20Safety%20%26%20Ethics/8.4.%20The%20Agent%20Containment%20Toolchain%20—%20Sandbox%2C%20Runtime%2C%20and%20Egress%20Proxy.md). |
| Session affinity | The namespace is in-process state. Stateless request routing, the thing MCP just spent a spec cycle buying, does not apply to the kernel. |
| Storage that only grows | Lossless means lossless. The Event Log is now a retention-policy and data-residency question. |
| A new failure surface | The model can write code that corrupts its own namespace. Compaction cannot. |
| Latency variance | Recovering an evicted span is a round trip the summary-based design never makes. |

> **Why it matters:** every one of these is a *systems* cost paid to remove an
> *information-theoretic* cost. That is usually a good trade, because systems costs
> respond to engineering and lower bounds do not — but it is a trade, and a harness
> that cannot host a persistent sandbox cannot make it.

## 7. What to steal today

You do not need the full design to get most of the benefit. In rough order of
effort-to-payoff:

1. **Bind large tool results to handles.** Return `{id, shape, preview}` from any tool
   whose output can exceed a few thousand tokens, and add a `fetch(id, slice)` tool.
   This is the single highest-leverage change and needs no kernel.
2. **Make eviction addressed, not summarized.** When you drop a span, leave a landmark
   with a retrievable ID. Even a filesystem path counts.
3. **Keep the log append-only and separate from the prompt.** The prompt is a view. If
   your harness cannot state which bytes are ground truth and which are a rendering of
   it, this design is not available to you yet.
4. **Let the model trigger compaction.** Expose it as a tool the model can call, rather
   than a threshold that fires underneath it.
5. **Only then reach for a persistent kernel.** It is the largest operational step and
   the one that most needs the containment story to already be in place.

---

## References

- [Context as an Environment: Programmatic Context Management for Long-Horizon Agents](https://arxiv.org/abs/2608.21690)
- [ACM: Agentic Context Management for Long Horizon Tasks](https://arxiv.org/abs/2607.23809)
