# Context Window Management — Eviction, Compaction & Memory

> **One idea to remember:** the context window is **RAM, not a hard drive** — small, finite, and
> rivalrous. A long-running agent will overflow it. The fix is to manage it like an OS manages memory:
> **page content in** when it's needed and **evict it out** (to external storage) when it's not — keeping
> only high-signal tokens in front of the model.

## 1. Why the window needs managing

Every LLM call is stateless, and the window is finite (e.g. ~200K tokens). A long agent run keeps
piling content into it — conversation turns, tool results, retrieved memory, file reads — until it
**overflows**. Worse, long before overflow a bloated window **dilutes attention** ("context rot") and
you **pay for every token, every turn**. So "it still fits" ≠ "it should stay." Managing the window is
the central job of context engineering.

## 2. The five levers (keep the window under budget)

To stay under budget you have five moves, best-first:

1. **Don't add it** — high-signal tokens only; never dump raw data the model doesn't need now.
2. **Isolate** — quarantine heavy work in a **subagent's own context**; only its distilled result
   returns to the main window. The strongest "don't add it": the bulk never enters the main thread.
3. **Fetch on demand** (retrieve) instead of pre-loading — pull only the relevant slice. *(the "in")*
4. **Evict / page out** — move stale content **out** to external storage. *(the "out" — §3)*
5. **Compact** — summarize many turns into a few. *(lossy "out" — §4)*

Levers 1–3 keep content from entering the main window; 4–5 remove what's already there. This note
focuses on the "out" direction — eviction and compaction — plus isolation (the prevention play) and the
Claude features that implement them.

**Context isolation (subagents).** Instead of cleaning up *after* heavy work bloats the window, you keep
it out entirely: spawn a subagent that does the work (read 50 files, run a noisy search) in its **own
separate context**, and it returns only the **answer** to the parent. The parent never sees the
intermediate tokens. It's eviction's opposite — *prevention by quarantine* — and it composes with the
rest (a subagent can itself evict/compact internally).

## 3. Eviction / paging-out

**Eviction = removing content from the window and saving it to external storage**, so the window stays
under budget. It's the inverse of retrieval (paging in). Together they manage a finite window the way an
OS swaps between RAM and disk.

- **Window = RAM** — small, fast, the only thing the model can directly see.
- **External store = disk** — large, but must be paged *in* to use.

How it works:

```
1. Trigger      window nears its limit (e.g. 80% full) → "memory pressure"
2. Pick victims low-value / stale content (old tool outputs, resolved sub-tasks, early turns)
3. Persist      summarize + write it to external storage   ← don't just delete; keep the gist
4. Drop         remove it from the window → back under budget
5. Page in      later, if needed, retrieve it again (the "in" direction)
```

**Evict ≠ delete.** The good pattern is **summarize-then-evict**: distill ("read schema.sql: migration
alters table Y") into a small note that *stays*, and move the bulky verbatim *out*. Eviction is lossy
compression to disk, not destruction — the content is still retrievable.

**Concrete implementation — "offloading."** LangChain's deep-agents do exactly this: when a tool input
or result exceeds ~20K tokens, it's written to the **filesystem** and replaced in the window with a
**file pointer + a short preview**; the agent re-reads or searches it on demand. The preview is the gist
that stays; the pointer is how it pages back in — summarize-then-evict by another name. (Note:
offloading targets large *tool I/O* specifically; eviction in general can also drop old conversation
turns — see compaction, §4.)

Concrete trace:

```
Window budget 200K. Agent on a long migration task:
  read 3 large files (tool results)   → 150K
  run tests (big log)                 → 185K   ← near limit
  [memory pressure]
  evict: raw file contents not needed now
     → save summary "schema.sql: tables X,Y; migration alters Y"  (to a memory file)
     → drop the 30K of raw file text from the window             → 120K
  …continue…
  later needs the schema again
     → page IN: read the memory file (or re-read schema.sql)
```

The 30K raw file leaves the window (gist kept); space freed; re-fetched only if needed.

## 4. Compaction — eviction by summary

When the **conversation itself** (not just tool results) grows too long, **compaction** replaces a span
of turns with a summary. It's eviction where the "persist" step is a summary of the dialogue.

- **Keep:** decisions made, unresolved bugs, constraints, key implementation details, open threads.
- **Drop:** redundant tool outputs, resolved detours, verbatim chatter.

Compaction is what lets an agent run for hundreds of turns inside a fixed window — the early history
becomes a paragraph, the recent turns stay verbatim.

## 5. How to do it today (Claude-first)

Two API features combine to *be* page-out, plus compaction:

| Mechanism | Role | What it does |
|-----------|------|--------------|
| **Memory tool** (`memory_20250818`) | **persist** | the agent writes important state to `/memories` files (client-side), so knowledge survives when context is cleared |
| **Context editing** (`context-management` beta) | **evict** | automatically **clears stale tool results** from the window when it fills |
| **Compaction** | **summarize** | server-side summarization of a long conversation into a compact form |

The loop in one line: **memory tool saves it, context editing drops it, retrieval brings it back.** That
trio is hierarchical / agentic recall in practice — the agent manages a bounded window instead of
drowning in it. Anthropic reports large gains from pairing memory + context-editing on long agentic
runs (e.g. big token reductions over many-turn tasks).

> Provider-neutral note: the window-budget problem is universal — every model has a finite context. The
> *mechanisms* differ (Claude exposes memory tool + context editing + compaction; on other stacks you
> implement eviction in your own harness: track token count, summarize/flush old turns to a store,
> retrieve on demand). The pattern — RAM/disk paging — is the same everywhere.

### Claude Code naming (user-facing)

The API features above surface in **Claude Code** under different, day-to-day names. Claude Code's
automatic order is telling: **clear old tool outputs first, then summarize** the conversation.

| Concept (this note) | Claude Code feature |
|---------------------|---------------------|
| **Eviction** of tool outputs | **"tool result clearing"** (a **context editing** strategy) — old tool outputs cleared first as the window fills |
| **Offloading** (persist + re-read) | no named feature — the **file-as-context** pattern + **memory tool**: write the output to a file, page it back with `Read` |
| **Compaction** | **`/compact`** (manual) · **auto-compact** (automatic, ~13K-token buffer) · `PreCompact`/`PostCompact` hooks · **`/clear`** for a hard reset |
| **Isolation** (lever 2) | **subagents** (the Task/Agent tool) — separate context, returns only the result |
| **Long-term memory** | **`CLAUDE.md` + auto-memory**, and the **memory tool** |

> Note one difference: LangChain *offloading* keeps an automatic **pointer + preview** so the content
> stays addressable; Claude Code's *tool result clearing* **removes** the old result (the model re-runs
> the tool or re-reads the file if it needs it again). Same goal, different bookkeeping.

## 6. Eviction vs forgetting — don't confuse them

| | **Eviction / page-out** (this note) | **Forgetting** (long-term memory) |
|---|---|---|
| Scope | the **active window** (working memory) | the **long-term store** |
| Meaning | move out of view, **keep retrievable** | **permanently remove** low-value memory |
| Question | "is this needed *right now*?" | "does this deserve to exist *at all*?" |

Eviction manages *what's in front of the model this turn*; forgetting manages *what stays in the store
long-term*. Evicted content is still on disk; forgotten content is gone. (Memory lifecycle —
capture/store/recall/forget — is covered in the AI-Enterprise *System Memory* note.)

## References

- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing)
- [Anthropic — Compaction](https://platform.claude.com/docs/en/build-with-claude/compaction)
- [Anthropic — Memory tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)
- [Anthropic — How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)
- [MemGPT — Towards LLMs as Operating Systems](https://arxiv.org/abs/2310.08560)
- [LangChain — Deep agents: context engineering (offloading, isolation)](https://docs.langchain.com/oss/python/deepagents/context-engineering)
