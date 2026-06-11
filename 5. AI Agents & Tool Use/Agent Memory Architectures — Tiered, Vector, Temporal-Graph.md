# Agent Memory Architectures — Tiered, Vector, and Temporal-Graph

> **Updated 2026-06-11.** Protocols (MCP, A2A, AGENTS.md) tell an agent how to
> *connect*. **Memory** tells it what to *remember* once a task runs longer than
> one context window. In 2026 this stopped being "just stuff it in a vector DB"
> and split into three clear designs: **tiered memory** (the agent curates its
> own context), **vector/hybrid memory** (retrieve facts by similarity), and
> **temporal knowledge graphs** (track *when* a fact was true). This note
> explains the three, when to pick each, and the production gaps that still
> bite. It is the "what the agent remembers" half of agent engineering — see
> [The Agent Protocol Stack](The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md)
> for the "what the agent connects to" half.

---

## 1. Why memory is now its own layer

A single LLM call has no memory. Everything it "knows" must sit in the context
window. That works for one prompt. It breaks the moment an agent:

- runs a **20-step task** that overflows the window,
- comes back **tomorrow** and should remember today,
- serves **many users** and must not mix them up.

The naive fix — append everything to the prompt — fails twice. It costs too
many tokens, and a long messy context actually makes the model *worse* (it gets
distracted). So memory became a separate component with its own job: **store
the right things, and feed back only the few that matter for the current step.**

A useful frame, borrowed from the operating-system world:

```
   Context window  =  RAM   (small, fast, in front of the model right now)
   Memory store    =  Disk  (large, slow, searched on demand)
   The hard part   =  what to load from disk into RAM, and when
```

---

## 2. The three memory *types* (what you store)

Before the architectures, agree on *what* a memory is. The field settled on
three kinds:

| Type | Question it answers | Example |
|------|--------------------|---------|
| **Episodic** | *What happened?* | "Yesterday the user asked for a refund." |
| **Semantic** | *What is true?* | "The user prefers metric units." |
| **Procedural** | *How do we do this?* | "Our code review always checks tests first." |

A strong agent uses all three. Episodic = the log. Semantic = the facts and
preferences. Procedural = the learned workflows (this is the one most teams
forget, and it is where self-improvement lives).

---

## 3. Three architectures (how you store and retrieve)

### 3.1 Tiered memory — the agent curates itself (Letta / MemGPT)

Inspired by an OS. Memory is split into tiers and the **agent itself** decides
what moves between them:

```
┌─ Core memory ──────┐  always in context (identity, key facts). Small.
│                    │
├─ Recall memory ────┤  recent conversation history. Medium.
│                    │
└─ Archival memory ──┘  big external store, searched on demand. Large.
```

The model is given *tools* like `memory_insert` and `memory_search`, so it
writes and reads its own memory as part of thinking. **Best for:** single
long-running agents that need a stable "self" over days (assistants, copilots).
**Cost:** the model spends tokens and turns managing memory.

### 3.2 Vector / hybrid memory — retrieve by similarity (Mem0, LangMem)

Store each memory as text + an embedding. At each step, embed the current
situation and pull back the most similar memories. Modern systems are **hybrid**
— they fuse three signals instead of trusting one:

```
query ──► [ semantic similarity ]  ┐
      ──► [ BM25 keyword match   ]  ├─► fused score ─► top-k memories
      ──► [ entity match         ]  ┘
```

They also tag every memory with **scopes** (`user_id`, `agent_id`, `run_id`,
`org_id`) so retrieval stays inside the right user/session. Newer designs do
**entity-aware storage** — they extract who/what during write, so you get
graph-like linking without running a separate graph database. **Best for:**
multi-user products that need drop-in personalization. **Cost:** retrieval
quality is only as good as your scoping and ranking.

### 3.3 Temporal knowledge graph — track *when* a fact was true (Zep / Graphiti)

A flat vector store has one big weakness: it does not understand **change**. If
the user moved city, the old "lives in Hanoi" memory still matches well and
comes back *confidently wrong*. A temporal graph fixes this by storing facts as
edges with **validity windows**:

```
(User) ──lives_in──► (Hanoi)   valid 2024-01 → 2026-03   [expired]
(User) ──lives_in──► (Saigon)  valid 2026-03 → now       [current]
```

Now the agent can ask "where does the user live *now*?" and get the current
answer, while still being able to reason about history. This is why temporal
graphs win on update-heavy benchmarks: **Zep ~63.8% vs Mem0 ~49.0% on
LongMemEval** in the comparison below. **Best for:** long relationships where
facts change (CRM, health, finance). **Cost:** more moving parts to run.

---

## 4. How to choose (quick rule)

```
One agent, needs a stable self over days        → Tiered (Letta)
Many users, want fast drop-in personalization    → Hybrid vector (Mem0/LangMem)
Facts change over time, history matters          → Temporal graph (Zep/Graphiti)
Just a few turns, fits the window                → No memory layer. Don't add one.
```

The last line matters. Memory is infrastructure. If the task fits in context,
adding a memory store only adds latency, cost, and new failure modes.

---

## 5. Benchmarks — how memory is measured in 2026

Three benchmarks now define the field:

- **LoCoMo** — 1,540 questions over long conversations (single-hop, multi-hop,
  temporal). Tests basic recall.
- **LongMemEval** — 500 questions on **knowledge updates** and multi-session
  chats. This is the one that exposes the "stale fact" problem.
- **BEAM** — stresses systems at **1M and 10M tokens**. The most production-like.

A headline result: the best 2026 systems reach **~92.5 on LoCoMo** and
**~94.4 on LongMemEval** while using only **~6,900 tokens per query** — versus
**~26,000 tokens** for the dumb "stuff the whole history in" approach. So good
memory is not just more accurate, it is **~4× cheaper** per query. Temporal
reasoning improved most (+29.6 points), then multi-hop (+23.1).

---

## 6. Production gaps (still unsolved — design around them)

Even with good frameworks, these bite in real systems:

1. **Temporal abstraction** — accuracy still drops ~25% going from 1M → 10M
   tokens. Very long histories are not solved.
2. **Cross-session identity** — knowing two chats are the *same person* across
   devices or anonymous sessions is unreliable. Bad scoping = leaked memory.
3. **Memory staleness** — high-relevance memories become *confidently wrong*
   when the user's life changes. (This is the case temporal graphs target.)
4. **Eval gap** — general benchmarks do **not** predict your domain. You must
   build an eval on your own workload (healthcare, legal, retail).
5. **Privacy** — there is still no standard for inspecting, retaining, and
   **deleting** a user's memories. You own this; build a delete path early.

### A new failure mode: silent memory pollution

A 2026 finding worth flagging: background/long-running agents that write memory
while running can quietly **poison their own store** — a bad intermediate result
gets saved as a "fact" and corrupts every later step, with no error raised.
Lesson: **treat memory writes as untrusted.** Validate before you persist, mark
provenance, and prefer write paths the model cannot trigger by accident.

---

## 7. Practical takeaways

- **Pick by how facts behave, not by hype.** Stable self → tiered. Many users →
  hybrid vector. Changing facts → temporal graph.
- **Always scope writes** (`user_id`, `org_id`, `run_id`). Most "memory leaked
  to the wrong user" bugs are scoping bugs, not model bugs.
- **Store procedural memory, not just facts.** Saved workflows are where an
  agent gets better over time — see
  [5.1 Self improvement](../5.1%20Self%20improvement/).
- **Add a delete path on day one.** Privacy is your job, not the framework's.
- **Validate before you persist.** Untrusted writes cause silent pollution.
- **Don't add a memory layer you don't need.** If it fits the window, skip it.

> **Bigger picture:** memory + protocols are the two halves of agent
> engineering. Protocols decide *reach*; memory decides *continuity*. The glue
> between them — deciding what to load into context at each step — is
> **context engineering**; see [3. Prompt & Context Engineering](../3.%20Prompt%20%26%20Context%20Engineering/)
> and the harness notes in [11. Harness Engineering](../11.%20Harness%20Engineering/).

---

## References

- [State of AI Agent Memory 2026: Benchmarks, Architectures & Production Gaps (Mem0)](https://mem0.ai/blog/state-of-ai-agent-memory-2026) — LoCoMo/LongMemEval/BEAM, multi-signal retrieval, the five production gaps, token-cost numbers.
- [Best AI Agent Memory Frameworks in 2026: Compared and Ranked (Atlan)](https://atlan.com/know/best-ai-agent-memory-frameworks-2026/) — framework-by-framework architecture comparison (Letta tiered, Mem0 hybrid, Zep temporal graph), LongMemEval scores.
- [The 6 Best AI Agent Memory Frameworks You Should Try in 2026 (MachineLearningMastery)](https://machinelearningmastery.com/the-6-best-ai-agent-memory-frameworks-you-should-try-in-2026/) — practical picks and trade-offs.
- [Mind Your HEARTBEAT! Background Execution Enables Silent Memory Pollution (arXiv)](https://arxiv.org/pdf/2603.23064) — how long-running/background agents corrupt their own memory without raising errors.
- [Top Agentic Frameworks for Building Applications 2026 (JetBrains/PyCharm)](https://blog.jetbrains.com/pycharm/2026/06/top-agentic-frameworks-for-building-applications-2026/) — where memory sits inside the agent framework stack.
