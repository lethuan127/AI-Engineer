# Code Execution as the Tool-Calling Substrate — Programmatic Tool Calling

> **Source:** Anthropic's programmatic-tool-calling and code-execution-tool
> docs, the "Code execution with MCP" and "Advanced tool use" engineering
> posts, and the Claude API changelog entry for `code_execution_20260120`
> (2026-06-18). Companion to
> [The Agent Protocol Stack](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md)
> and [11.7. Tools and MCP](../11.%20Harness%20Engineering/11.7.%20Tools%20and%20MCP.md).

---

## 1. The shift: from one tool call per turn to code that orchestrates tools

The default tool-use loop is one inference pass per tool call. Claude emits a
`tool_use` block, the harness runs it, the full result is appended to the
context window, and the model is invoked again to read it and decide the next
call. Two costs grow with the number of tools touched:

- **Inference overhead.** A five-step workflow is five separate model passes,
  each re-reading the whole transcript so far. Latency and output tokens scale
  with the step count.
- **Context pollution.** Every intermediate result lands in context whether or
  not the model needs it. Analyzing a 10 MB log for one error pattern drags the
  whole file through the window even though only a summary is wanted. This is
  the same context-rot pressure that
  [compaction and memory](../3.%20Prompt%20&%20Context%20Engineering/Context%20Window%20Management%20—%20Eviction,%20Compaction%20&%20Memory.md)
  exist to fight — except here the bloat is self-inflicted by the tool loop.

**Programmatic tool calling** inverts the loop: instead of returning each tool
result to the model, the model writes code (in a sandboxed
[code-execution](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool)
container) that calls the tools, processes the intermediate data, and returns
only the distilled result to context. The tools become callable functions
inside a runtime, not round-trips through the model.

> **Architectural takeaway:** the unit of agent action moves from "one tool
> call" to "one program that calls many tools." The model reasons over the
> *plan and the filtered output*, not over every byte every tool emits.

## 2. How it works

The model is handed tool definitions as a code API. Inside the container it can
loop, branch, filter, and aggregate across many tool calls before any result
re-enters the context window.

```python
# Conceptual: check budget compliance for 20 employees.
# Traditional loop = 20 model passes + thousands of expense line items in context.
over_budget = []
for emp in get_employees(team="eng"):          # tool call
    spend = get_expenses(emp.id, quarter="Q2") # tool call, returns ~KBs each
    if sum(e.amount for e in spend) > emp.limit:
        over_budget.append(emp.name)
return over_budget                              # only this list reaches Claude
```

The 20 lookups and the raw expense rows never touch the model's context — only
the final list of names does. The model writes this once, the runtime executes
it, and a single pass reads the result. Parallel calls and retries live in the
code, not in the transcript.

Constraints worth knowing before adopting it:

| Constraint | Detail |
|---|---|
| Requires code execution | Programmatic tool calling is layered on the code-execution tool; it cannot run without a sandbox. |
| Tool version floor | `code_execution_20260120` is the **minimum** tool version (see §4). |
| Not ZDR-eligible | The feature is excluded from Zero Data Retention; data follows the standard retention policy. |
| Sandbox discipline | Tool-calling code runs arbitrary logic — resource limits, network policy, and credential isolation are mandatory, not optional. |

## 3. The MCP variant: tools as a code API, loaded on demand

The same idea applied to [MCP](./MCP.md) servers is "code execution with MCP."
Instead of injecting every server's full tool schema into context up front, the
harness exposes each tool as a file in a generated TypeScript tree
(`./servers/<server>/<tool>.ts`) and lets the agent discover and import only
what a task needs. Two mechanics do the work:

- **Progressive disclosure.** The agent lists `./servers/` and reads a tool's
  definition on demand rather than loading all definitions at startup. Token
  cost of "having" a tool drops to near zero until it is actually used — the
  filesystem version of the
  [tool-search tool](./tool-search-tool.md) idea.
- **Filter before context.** Intermediate results are reduced in the runtime.
  A query that returns 10,000 rows is filtered to the 5 the agent cares about
  *before* anything reaches the model.

Anthropic's reference example — a Google Drive → Salesforce sync — drops from
**150,000 tokens to 2,000 tokens (≈98.7% reduction)** by moving the
fetch-transform-write loop into code instead of round-tripping each record
through the model.

## 4. What `code_execution_20260120` changed (2026-06-18)

On 2026-06-18 the Python, TypeScript, Go, Java, Ruby, PHP, and C# SDKs all
shipped support for the `code_execution_20260120` tool version. Two things
matter for builders:

1. **REPL state persistence.** Variables, imports, and intermediate objects
   survive across executions within a session instead of being recomputed each
   call. The container behaves like a long-lived notebook kernel, so a later
   step can reference an earlier step's results without re-fetching them.
2. **It is the floor for programmatic tool calling.** Earlier code-execution
   tool versions cannot do programmatic tool calling at all; this version is the
   minimum. Adoption is a one-line change — set the tool `type` to
   `code_execution_20260120`, no beta header — and it is available on Claude
   Fable 5, Mythos 5, Opus 4.5+, and Sonnet 4.5+.

> **Why it matters:** persistent REPL state is what makes multi-step
> orchestration cheap. Without it, every program starts from a cold container
> and re-pays for setup and re-fetches; with it, the code-execution container
> becomes durable working memory that sits *outside* the context window.

Code execution is also billed as free when paired with web search or web fetch
(`web_search_20260209` / `web_fetch_20260209` or later), which is why "dynamic
filtering" of search results is now the default-recommended retrieval path.

## 5. The numbers

From Anthropic's own benchmarks for dynamic filtering (programmatic processing
of search results before they hit context):

| Benchmark | Model | Baseline | With filtering |
|---|---|---|---|
| BrowseComp (accuracy) | Sonnet 4.6 | 33.3% | 46.6% |
| BrowseComp (accuracy) | Opus 4.6 | 45.3% | 61.6% |
| DeepSearchQA (F1) | Sonnet 4.6 | 52.6% | 59.4% |
| DeepSearchQA (F1) | Opus 4.6 | 69.8% | 77.3% |

Across both, the approach averaged **+11% accuracy on 24% fewer input tokens** —
the rare case where the cheaper path is also the more accurate one, because
less irrelevant context means less to get distracted by.

## 6. When to reach for it — and when not

| Use programmatic tool calling when… | Stick to plain tool use when… |
|---|---|
| A task fans out over many calls (per-row, per-file, per-employee). | The task is a single tool call or two. |
| Tool outputs are large but the useful slice is small. | Outputs are already small and worth showing the model. |
| You want filtering/aggregation logic the model shouldn't re-read each step. | You *want* the model to see each intermediate result and reason on it. |
| Latency from sequential round-trips dominates. | The orchestration logic itself needs model judgment at each step. |

The trade-off is operational, not conceptual: you are now running
model-authored code, so the sandbox, resource limits, network egress policy,
and credential isolation become load-bearing. This is the same decoupling logic
behind self-hosted sandboxes — keep the brain (model) away from the credentials
the hands (code) touch. Done right, it is the most effective single lever on
both token cost and tail latency in tool-heavy agents.

## References

- [Anthropic — Programmatic Tool Calling](https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling)
- [Anthropic — Code Execution Tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool)
- [Anthropic — Claude API Release Notes](https://platform.claude.com/docs/en/release-notes/api)
- [Anthropic Engineering — Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp)
- [Anthropic Engineering — Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use)
- [Anthropic — Improved Web Search with Dynamic Filtering](https://claude.com/blog/improved-web-search-with-dynamic-filtering)
