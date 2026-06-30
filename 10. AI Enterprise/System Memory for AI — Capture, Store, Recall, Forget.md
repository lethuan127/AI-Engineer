# System Memory for AI — Capture, Store, Recall, Forget (Claude-first)

> Deep-dive companion to *Centralized Knowledge for AI — Comprehensive* (this folder), expanding the
> **system memory / agent-authored** pillar: what the AI learns and reuses across sessions. Researched
> Claude-first; facts current as of mid-2026.

---

## 1. What "memory" is — and the four operations

The model is **stateless** (P1): it keeps nothing between calls. *Memory* is how state persists anyway —
everything the agent should carry forward must be written somewhere and pulled back into context later.

Memory comes in types (cognitive analogy — see the glossary in *Semantic-Layer MCP — Design*):

- **Episodic** — what happened (conversation history).
- **Semantic** — facts the agent distilled ("the deploy command is X"; user preferences).
- **Procedural** — how-to (skills, workflows). Their *storage* is detailed in the comprehensive doc's
  §9; their *memory lifecycle* (capture/recall/forget) is covered here alongside the others.
- **Scoped** — context bound to a workspace/project.

And it has a **lifecycle** of four operations — the spine of this doc:

```
Capture  →  Store  →  Recall  →  Forget
(what to    (where /   (back into   (decay,
 remember)   how)       context)     resolve, prune)
```

Plus a cross-cutting fifth — **Maintain** (§7): keeping the surviving memory *true* over time. It's not
a stage in the per-item flow but an ongoing discipline across the whole store, so it gets its own
section after Forget.

The tension under all of it: **context is finite and rivalrous** (P6). More memory is only useful if you
can recall the *right* part without drowning the window — which is why Store and Recall are design
choices, not afterthoughts.

### The types behave differently across the lifecycle

The four operations (§3–6) play out **differently per type** — episodic, semantic, and procedural
memory are captured, stored, recalled, and forgotten in distinct ways. This matrix is the map; the
later sections go deep on each operation (mostly through the semantic lens — read across this table for
the others).

| Type | Capture | Store | Recall | Forget |
|------|---------|-------|--------|--------|
| **Episodic** *(what happened)* | mostly **automatic** — transcripts logged; the work is **distillation** (end-of-session summary of decisions/events, not raw turns) | raw `*.jsonl` transcripts + distilled summaries; claude.ai auto-synthesizes ~24h | retrieve relevant **past sessions** by time/topic ("what did we decide last week?") | age out / summarize verbatim; keep the summary, drop the raw |
| **Semantic** *(facts)* | **deliberate** — on correction/decision/explicit; extract **atomic, non-derivable** facts | `CLAUDE.md` + atomic notes, or KG / memory tool | load index → topic on demand, or query | resolve contradictions, dedup, prune stale (the hard case: stale high-relevance facts) |
| **Procedural** *(how-to)* | **codify a repeatable procedure** — a successful multi-step task → save as skill/command/workflow | files in `.claude/` (`SKILL.md`, commands, workflows) → **git** | **progressive disclosure** — description matches the task → load the body on invoke | deprecate / version via git; remove obsolete |
| **Scoped** *(project)* | bind any of the above to a workspace/space | project `CLAUDE.md` / Cowork space `memory/` | auto-loaded **only** for that project | per-project lifecycle; siloed by design |

Two cross-cutting truths: **episodic is high-volume and auto-captured** (so the work is summarizing and
*retrieving*, not deciding what to log), while **procedural is low-volume and deliberately authored**
(you *write* a skill; you don't "remember" it) and **stored as executable files, not prose**.

---

## 2. Where memory lives — by product (the ground truth)

Memory storage is **product-specific**. This decides whether it centralizes at all.

| Surface | Conversation history | Learned memory | Centralizes? |
|---------|----------------------|----------------|--------------|
| **claude.ai** chat | server-managed (Anthropic's servers); ~24h auto-synthesis | server-managed, **siloed** per project | ❌ can't point at a shared store or read on disk |
| **Claude Code** | **local files** — `~/.claude/projects/<id>/*.jsonl` transcripts | **local files** — `CLAUDE.md` (managed/user/project/local) + auto-memory under `~/.claude/projects/<id>/memory/` (`MEMORY.md` index) | ✅ it's files |
| **Cowork** | **local files** — `~/Library/Application Support/Claude/local-agent-mode-sessions/.../local_<sessionId>.json` | **local files** — `…/local-agent-mode-sessions/.../spaces/<spaceId>/memory/` (per *space* = project); separate from chat memory | ◐ local, but in **app-data**, not your repo |

> **claude.ai's memory is the exception** — server-locked and siloed. The agentic surfaces (Code,
> Cowork) keep memory as **local files**, so they ride the same synced-folder / git path as documents
> (P7: agent-authored knowledge is just files or calls). To *centralize* memory, you work with the
> file-based surfaces, not the chat app — but note **where** the files sit differs (next).

### Exact locations on disk (Claude Code)

The whole agent-authored pillar — memory *and* the procedural/output knowledge alongside it — is just
files in known places (verified on a live machine). Learned facts and procedural knowledge live in
`.claude/`; raw episodic history lives under `~/.claude/projects/`.

| Type | Location | Format | Centralizes via |
|------|----------|--------|-----------------|
| **Conversation history** *(episodic)* | `~/.claude/projects/<project-id>/*.jsonl` (session transcripts) | JSONL | machine-local (synced folder) |
| **Learned facts** *(semantic)* | **user:** `~/.claude/CLAUDE.md` · **project:** `./CLAUDE.md` or `./.claude/CLAUDE.md` · **local:** `./CLAUDE.local.md` · **enterprise:** `/Library/Application Support/ClaudeCode/CLAUDE.md` · **auto-memory:** `~/.claude/projects/<project-id>/memory/` (`MEMORY.md` index + topic files) | markdown | project → **git**; user/auto-memory → machine-local |
| **Skills** *(procedural)* | **project:** `./.claude/skills/<name>/SKILL.md` · **user:** `~/.claude/skills/<name>/SKILL.md` · **plugins:** `~/.claude/plugins/` | folder = `SKILL.md` (YAML frontmatter) + scripts | project → **git**; plugin marketplace |
| **Commands / subagents / hooks / workflows** *(procedural)* | `./.claude/commands/*.md` · `./.claude/agents/*.md` · `./.claude/settings.json` (+ `.claude/hooks/`) · `./.claude/workflows/` (+ ad-hoc scripts under the session dir) | markdown / JSON / scripts | project `.claude/` → **git** |
| **Artifacts / outputs** | the working dir / connected folders (Cowork "delivers files directly to your file system") | any | **save into Documents** (Drive / git) → becomes pillar 1 |

**The pattern:** **project-level `.claude/` is version-controlled in the repo → git centralizes it**
(skills, commands, agents, workflows, project `CLAUDE.md` — shared by every teammate and AI tool).
**User-level `~/.claude/`** is machine-local — centralize via a synced folder / dotfiles repo. The
**claude.ai** variants (chat memory, the Artifacts panel) are server-locked — the exception.

### Exact locations on disk (Cowork)

Cowork stores almost everything **inside its app-data directory** — *not* in `~/.claude/` and *not* at a
connected folder's project root. The directory name depends on the build: the **consumer build uses
`Claude`**, the **enterprise / "Claude Desktop on 3P" build uses `Claude-3p`**. (If you can't find
`Claude-3p`, you're on the consumer build — look in `Claude`.) Paths below are **verified on a live
consumer install** (macOS); the `…` after `local-agent-mode-sessions/` is `<accountId>/<deviceId>/`.

| Type | Cowork location (consumer build) | Status |
|------|----------------------------------|--------|
| **App-data dir** | `~/Library/Application Support/Claude/` (macOS) · `%LOCALAPPDATA%\Claude\` (Win) — enterprise/3P: `Claude-3p` | ✅ verified |
| **Conversation history** | `…/Claude/local-agent-mode-sessions/<acct>/<id>/local_<sessionId>.json` (+ per-session dirs) | ✅ verified |
| **Learned memory** | `…/local-agent-mode-sessions/<acct>/<id>/spaces/<spaceId>/memory/` — **per Cowork *space* (= project)**; markdown, empty until written | ✅ verified |
| **Spaces (projects)** | `…/local-agent-mode-sessions/<acct>/<id>/spaces/` + `spaces.json` | ✅ verified |
| **Skills** | `…/local-agent-mode-sessions/skills-plugin/<id>/` (+ `~/.claude/skills/` shared with Claude Code) | ◐ verified dir; `~/.claude/skills/` is likely/third-party |
| **Plugins / MCP connectors** | `…/Claude/Claude Extensions/` + `extensions-installations.json` (enterprise: `cowork_plugins/`; org plugins `/Library/Application Support/Claude/org-plugins/`) | ✅ verified |
| **Artifacts / outputs** | `~/Claude/` (legacy `~/Documents/Claude/`) + user-chosen connected folders | ✅ confirmed (docs) |
| **Sandbox VM** | `…/Claude/vm_bundles/`, `claude-code-vm/` | ◐ dir names verified; internal layout undocumented |
| **Logs** | `~/Library/Logs/Claude/coworkd.log`, `cowork_vm_swift.log`, `cowork_vm_node.log` | ✅ verified |

> **Key difference from Claude Code.** Code's *project* `CLAUDE.md` lives in your repo → **git-native**,
> centralizes for free. **Cowork's memory is app-managed local files** under app-data
> (`…/Claude/local-agent-mode-sessions/.../spaces/<spaceId>/memory/`) → local but **not in your git
> repo**; to centralize/version it you sync or export that memory dir. (Cowork memory is *per-space* —
> a space = a project. Earlier drafts said a connected-folder project-root `CLAUDE.md`; that was a
> third-party claim — verified reality is the per-space `memory/` dir inside app-data.)

Procedural knowledge (skills/workflows) and artifacts are detailed in the comprehensive doc's §9 —
listed in both tables only so all of pillar 2's storage is in one place.

---

## 3. Capture — what to remember

The hardest part isn't storing; it's deciding **what's worth storing**. Anthropic's guidance is blunt:
defaults are only a starting point — *the usefulness of what lands in memory depends on the guidance you
give the agent.*

**Capture only what is durable, reusable, and non-derivable:**

- ✅ Stable facts, decisions, user preferences, conventions, hard-won lessons, unresolved threads.
- ❌ Noise, one-off details, and anything **derivable from the code, the docs, or git history** — don't
  duplicate what another source already owns (P2). If asked to "remember" something derivable, store the
  *non-obvious why*, not the fact.

  > **Example.** "Remember we use Postgres 16." The *version* is derivable — it's in `docker-compose.yml`
  > / the DB itself — so storing it just creates a copy that goes stale when the source changes. What's
  > **not** in any file is the reason: store *"pinned to 16, not 17, because extension X isn't
  > 17-compatible yet."* Heuristic: **memory should hold what you can't `grep`** — if you could recover
  > it by reading the repo, running a query, or checking git, keep the *reasoning* you couldn't recover,
  > not the fact.

**When to write** (write events, not every turn):

- End of a task (what was done, what's pending).
- On a correction or confirmed preference ("always use X").
- On an explicit "remember this."
- On an architectural decision (preserve the *why*).

**How to write — extract then consolidate** (the Mem0 pattern): turn raw messages into **atomic facts**
(one fact per unit), optionally as entity/relation triples, then consolidate against what's already
stored (update or merge, don't blindly append). Atomicity is what makes later recall and conflict
resolution tractable.

Categories help retrieval and review — e.g. `user` / `feedback` / `project` / `reference` (the Claude
Code auto-memory convention).

### Capture by type

Everything above is **semantic** capture (facts). The other types are captured differently:

- **Episodic** *(what happened)* — capture is mostly **automatic** (transcripts are logged); the real
  work is **distillation**, not collection. At the end of a session/task, write a *short summary* —
  decisions made, what was done, open threads — **not** the full transcript. Hoarding raw turns is
  noise; the summary is the memory. (This is what claude.ai's ~24h synthesis does automatically.)
- **Procedural** *(how-to)* — capture means **codifying a repeatable procedure**: when a multi-step task
  succeeds and will recur, save it as a **skill / command / workflow** (a file in `.claude/`, see §2).
  Trigger: repetition, or an explicit "save this as a workflow." You don't "remember" a procedure — you
  *write* it, as executable files, learning-by-doing → codified how-to.
- **Scoped** *(project)* — tag any captured memory to a workspace/space when it must **not** leak across
  contexts (a project-specific convention belongs in that project's memory, not your global one).

> Rule of thumb per type: **semantic = decide what's worth a fact; episodic = decide what to summarize;
> procedural = decide what to codify.** Different judgment calls, same goal — keep what's durable and
> reusable, drop the rest.

---

## 4. Store — where and how

Three ways to centralize learned memory (plus native, which doesn't centralize):

| Approach | Mechanism | Best when |
|----------|-----------|-----------|
| **File-based (default)** | memory folder in a synced location / git (`CLAUDE.md` + atomic notes + `MEMORY.md` index) | small-to-medium, mostly stable, human readability + zero infra matter |
| **MCP memory server** | a queryable store — Knowledge Graph Memory (JSONL entities/relations/observations), or a Mem0-style service; `mcp-memory-service` adds remote MCP for claude.ai | memory is large, structured/queryable, or needs concurrent writes |
| **API memory tool** | Anthropic's `memory_20250818` + context editing: client-side files the *runtime* drives (can point at the synced folder) | an agent runtime authors the memory; keep the window lean via context editing |

**File vs MCP server — the core mechanic** (retrieval vs load-into-context):

| Dimension | File-based (synced folder) | MCP memory server |
|-----------|----------------------------|-------------------|
| Cost | whole memory re-sent **every turn** (prompt caching softens a stable prefix ~90%) | tool schemas + query **results** only; flat as memory grows |
| Context | guaranteed present, but large memory dilutes attention and overflows | stays lean; scales; risk: missed if not queried |
| Latency | zero per-lookup (bigger prefill) | a tool round-trip (+ network if remote) |
| Infra | none — just the sync client | a process you run (host, uptime, auth) |
| Concurrency | conflict-copies possible | single write authority |
| Transparency | human-readable, git-friendly | JSONL/graph, less human-friendly |

**Structure choices:** *atomic-fact-per-file + index* (transparent, git-diffable, easy to revise) ·
*knowledge graph* (entities/relations/observations — good for connected facts and precise related-fact
queries) · *hierarchical files* (summaries on top, detail below — good for scale).

### Store by type

The three approaches above are for **semantic** memory. The others store differently:

- **Episodic** — **append-only logs + a summaries layer.** Raw transcripts (`*.jsonl`) are bulky and
  write-once; keep them as an archive, and store the **distilled summaries** in the queryable layer
  (file or vector store). You query summaries, not raw turns.
- **Procedural** — **executable files in git**, not prose memory: `SKILL.md` + scripts, commands,
  workflows under `.claude/` (see §2). Version-controlled code, not a memory store — so it gets code
  review, not memory maintenance.
- **Scoped** — **namespaced per project**: project `CLAUDE.md` / Cowork space `memory/`. Same mechanisms
  as above, but partitioned so one project's memory never bleeds into another.

> So only **semantic** memory really faces the "file vs MCP-server" choice. Episodic is logs+summaries,
> procedural is code-in-git, scoped is any of these partitioned by project.

---

## 5. Recall — getting it back into context

Recall is the **discovery problem again** (same as documents): the two modes are **load-into-context**
vs **retrieve-on-demand**, and the answer at scale is progressive/hierarchical.

- **Load-into-context** — file-based memory is read every turn. Simple, zero-latency, *guaranteed
  present* — but it competes for the window and eventually overflows (P6). (*Classic RAG* is the other
  passive mode: it retrieves automatically **before every answer**, whether or not it's needed.)
- **Progressive disclosure** — load a small **index first**, fetch detail on demand. Claude Code does
  exactly this: it loads the **first 200 lines / 25 KB of `MEMORY.md`**, and topic files load only when
  relevant. Can be **passive** (the harness fetches, not the model). Index = table of contents; notes =
  chapters.
- **Retrieve-on-demand (active retrieval)** — **the model decides when** to query memory and pulls only
  what it needs (Self-RAG / FLARE style, or a retrieval tool the agent calls) — *not* the
  retrieve-before-every-answer of classic RAG. Benchmarks (Mem0) show retrieval beats dumping full
  history into context.
- **Hierarchical / agentic recall** — retrieve-on-demand **plus window management**: a small
  **in-context tier** + a large **archival tier**; the agent fetches in **and evicts / pages out** to
  stay within budget (MemGPT/Letta — "LLM as an OS").

> **Progressive disclosure ≠ hierarchical agentic recall** (they look alike — both layer + fetch on
> demand). The difference: **progressive disclosure is a content-layering *pattern*** (overview → detail)
> and can be **passive**; **hierarchical agentic recall is a tiered-memory *architecture*** where the
> **agent itself** pages memory in/out via tools. Concretely:
> - *Progressive disclosure (passive):* Claude Code auto-loads the `MEMORY.md` index every session; a
>   topic file like `deploy.md` loads **only when the task mentions deploys** — no decision by the model,
>   the harness does it. (Same as a Skill: name+description always loaded, body loaded on match.)
> - *Hierarchical agentic recall (active):* a MemGPT-style agent **calls** `archival_search("Q3 launch
>   retro")`, reads the result into its window, and later **evicts** it to make room — the *model* decides
>   each page-in/page-out.
>
> So progressive disclosure is a **technique**; hierarchical agentic recall is an **architecture that
> *uses* it**. You can have the first without the second (auto-index), not really the reverse.

> **Retrieve-on-demand ≠ hierarchical agentic recall** — and the difference is *not* "who decides."
> **Both are agent-decided** (the model chooses when to fetch — that's what "on-demand" means). The
> **only** differentiator: hierarchical recall also **evicts / pages out** and manages a bounded, tiered
> window; retrieve-on-demand only fetches **in**. (Both differ from *classic RAG*, which retrieves
> automatically before every answer — that's the passive one.)
>
> | | Classic RAG | Retrieve-on-demand (active) | Hierarchical agentic recall |
> |---|---|---|---|
> | Who triggers the fetch | the pipeline, every turn | **the model** | **the model** |
> | Fetches **in** on demand | ✗ (always) | ✅ | ✅ |
> | **Evicts / pages out** | ✗ | ✗ | ✅ |

> Rule: **small, stable memory → load it; large or growing memory → index + retrieve.** It's the same
> "human-maintained index vs machine-maintained index" trade-off as document discovery.

**Is hierarchical agentic recall still necessary?** Mostly **no, for typical agents** — because the
platform absorbed half of it. MemGPT had two ideas: **(1) self-managed window eviction/paging** and
**(2) a searchable archival store with retrieval.** Claude's context editing + compaction (and
Deepagents' offloading) now do **(1) automatically**, so you no longer hand-build the eviction machinery
— that's the half that made hierarchical recall feel essential.

What native eviction does **not** give you (the half that's still opt-in):

- **Relevance-based recall over everything seen** — eviction clears *old* results; offloading leaves a
  pointer to *one file*. Neither is "search my whole history for the decision about X."
- **Cross-session / long-horizon memory** — context editing/compaction are *within a conversation*.
- **Precise old detail** — compaction *summarizes* (lossy); an archival store keeps detail retrievable.
- **Agent-driven *what to pull back in*** + self-editing memory blocks.

So: **the "out" direction is now native (don't build it); the "find the right thing back, across time,
by relevance" direction is opt-in** — add an archival tier only when memory must outlive the session, is
too big to re-read by pointer, or must be found by meaning.

| Your situation | What you need |
|----------------|---------------|
| Single session, outputs re-readable as files, summary is fine | **native eviction + compaction** — nothing to build |
| Long session, occasionally re-read a known artifact | **native offloading** (pointer + re-read) — already most of "hierarchical recall" |
| Cross-session memory · find old detail *by meaning* · corpus ≫ window | **add an archival retrieval tier** (MCP memory server / vector store) — *this* is when full hierarchical recall earns its keep |

### Recall by type

The load-vs-retrieve modes above apply mainly to **semantic** memory. The others recall by different
keys:

- **Episodic** — recall by **recency + topic**: load the latest session summary by default, *search*
  older episodes when the task references the past ("what did we decide last week?"). Time is the
  primary index.
- **Semantic** — load index → topic on demand, or query (the modes above).
- **Procedural** — recall by **description match** (this *is* progressive disclosure): only the skill's
  name + one-line description sit in context; the body loads when the task matches. The agent "recalls"
  a procedure by recognizing *when* to use it, not by reading all skills every turn.
- **Scoped** — recalled **only within its project**: a space's memory auto-loads for that space and is
  invisible elsewhere (siloing as a feature).

> **Tip — package shared *facts* as a skill, too.** Semantic memory doesn't have to be always-loaded
> (`CLAUDE.md`) or grep'd. Wrap a large shared glossary as a **skill** (`SKILL.md` router + per-topic
> `references/*.md`) so it recalls via **progressive disclosure** — the description loads always, a
> specific definition file only when that term appears. You then get the *procedural* recall pattern for
> *semantic* knowledge: lean context, scales with the glossary, and ships org-wide as a plugin. Worth it
> once definitions are many; for a few, `CLAUDE.md` is simpler. (See the Rollout Plan's
> `company-definitions` skill.)

---

## 6. Forget — prune, decay, deprecate

Memory **rots** without pruning: duplicates and low-value clutter accumulate, the window fills, and
recall degrades. Forgetting is a first-class operation, not neglect. (*Keeping the surviving memory
**true** — staleness, contradictions, the signals that drive it — is the separate discipline of
§7 Maintain.*)

- **Forgetting taxonomy** — *time-based* (age out old entries), *frequency-based* (drop never-retrieved
  ones), *importance-based* (keep semantically valuable, prune the rest).
- **Update vs forget** — *update* resolves a **conflict** (new info contradicts old → reconcile, don't
  keep both); *forget* removes outdated/low-value entries. The Mem0 design makes the update phase
  explicit: detect conflicts and resolve on write.
- **The hard problem:** decay handles *low-relevance* clutter, but **staleness in high-relevance facts**
  (the user changed jobs; the canonical command changed) is genuinely hard — these don't look stale, so
  they need contradiction detection on write and periodic review.
- **Dedup** atomic facts so the same thing isn't stored five ways.

> Why file-based + git helps here: every memory is a **diffable, revertible, reviewable** unit — stale
> facts are edited in a PR, contradictions show up in review, history is auditable. Atomic-fact-per-file
> makes update/forget surgical.

### Forget by type

Forgetting looks different per type — and one of them isn't "forgetting" at all:

- **Episodic** — **time-based decay is the default and the most aggressive**: summarize, then drop the
  raw transcript; later, age the summaries too. It's the highest-volume type, so it needs the most
  pruning — keep the gist, discard the verbatim.
- **Semantic** — **importance- and contradiction-based**: resolve conflicts (don't keep both), dedup,
  prune stale facts. The hard case lives here — *stale high-relevance facts* that don't look stale.
- **Procedural** — **not decay, but deprecation**: a wrong or obsolete skill/workflow is a **bug to fix
  or version**, not clutter to age out. Remove/supersede it via git (code lifecycle). Procedures don't
  expire on a timer — they're retired deliberately.
- **Scoped** — **forget with the project**: when a workspace/space is done, its scoped memory can be
  archived or deleted **wholesale**, cleanly, because it was partitioned from the start.

> The asymmetry to remember: **episodic forgets by default** (decay), **semantic forgets by judgment**
> (conflict/staleness), **procedural is never forgotten passively** (it's maintained like code).

---

## 7. Maintain — keep memory true

Forgetting (§6) removes what you don't want. **Maintenance keeps what remains *correct*** — and it's
the harder problem, because the most dangerous memory looks perfectly healthy. Three parts: the **hard
case** (what makes maintenance hard), the **defenses** (how to fix it), and the **feedback channels**
(how you learn there's something to fix at all).

### The hard case — stale high-relevance facts

**Why "stale high-relevance facts" are the hard case.** The trouble is that **every automatic
forgetting heuristic is designed to *keep* them**:

| Heuristic | drops things that are… | …so a stale **high-relevance** fact is |
|-----------|------------------------|----------------------------------------|
| time-based | old | **kept** (it's core, not aged out) |
| frequency-based | rarely used | **kept** (it's used a lot) |
| importance-based | low-value | **kept** (it's important) |

A *low*-relevance stale fact is harmless and easy to prune; a *high*-relevance one is harmful and
**invisible to pruning** — it's still confidently stated, still retrieved, still "fits." Example: *"prod
DB is Postgres 14"* after the upgrade to 16 — the agent keeps writing migrations for 14, confidently,
forever. The staleness is only detectable **from outside the fact**, so the only real defenses are:

1. **Contradiction detection on write** — new info conflicts with a stored fact → **reconcile, don't
   keep both** (Mem0's update phase).
2. **Periodic re-verification** — re-check high-relevance facts against the source (re-read the config,
   re-confirm with the user).
3. **Don't memorize the volatile fact at all** — versions, job titles, team roles are *lookup-able*;
   storing them invites this rot. Keep the *why*, re-derive the *what* — **"memory should hold what you
   can't `grep`"** (§3). A fact you re-derive can't go stale.

### Maintenance feedback channels — knowing *what* to update

The defenses above say *how* to fix staleness; this says **how you learn there's something to fix**.
Maintenance is only as good as its **signal sources** — and most teams wire up just one (a human
reports a problem). That single channel is **reactive** and **catches only what someone bothers to
report** — which is exactly the blind spot for the stale-high-relevance fact, since it still "looks
right" and nobody complains. Coverage comes from spanning two axes:

- **Origin** — who/what produces the signal: *human · agent-online* (during a live answer) *·
  agent-offline* (batch audit) *· system/telemetry · external source.*
- **Timing** — **reactive** (fires *after* a problem manifests) vs **proactive** (goes looking
  *before* anyone hits it).

**Sorted most → least effective** — where "effective" = catches the *dangerous* failures (especially the
stale-high-relevance blind spot), **prevents before it ships** where possible, high coverage, low human
cost. The purely **indirect** channels (telemetry, peer learning) rank last — useful for direction but
blind to the hard case. (**End-user reports** are no longer a standalone channel: they're folded into
**offline feedback** with the world-change feed, since both are human/world signals collected outside
the live loop.)

| Rank | Channel | Origin | R/P | Why this effective | What it catches |
|------|---------|--------|-----|--------------------|-----------------|
| **1** | **Eval / regression test suite** | system | **proactive (gate)** | the only one that catches a bad edit **before it ships** — prevention, not cleanup | A golden-question set runs on every write; a regression blocks the merge. |
| **2** | **Scheduled re-verification** *(incl. schema/contract drift)* | agent/system + external | **proactive** | the **true fix for the hard case** — re-checks against the source before a query collides, covering both fact *values* and the data *contract* | Re-checks high-relevance **fact values** (re-read config, re-confirm with owner) **and diffs the data contract** — a renamed table / dropped field that would silently break stored queries/definitions. |
| **3** | **Offline LLM-as-judge audit** | agent-offline | **proactive** | broad proactive sweep of the **whole store**, not one answer | A critic agent reads the store for contradictions, gaps, ambiguity, dead language. *(§9 "periodic sanitization.")* |
| **4** | **Offline feedback** | human + external | event-driven + reactive | bundles the world's biggest staleness source with the highest-trust report on one **offline** path (signals collected *outside* the live agent loop) | **(a)** the world changed (rename, reorg, policy/price shift, new entity), ingested from an authoritative source — memory **follows reality** instead of lagging it; **(b)** a person reports a wrong/missing fact — high-trust but slow, partial, and blind to what "looks right." |
| **5** | **Agent online feedback** | agent-online | reactive | automatic + real-time + structured; high signal, zero human effort | The agent flags its own trouble mid-answer: self-contradiction (live source ≠ stored fact) or an in-chat correction. |
| **6** | **Answer-outcome / quality feedback** | human/system | reactive | measures **quality of use**, not volume — catches "used a lot **and** wrong" | Ratings (👍/👎) or downstream outcomes, traced to the fact/skill behind the answer. |
| **7** | **Usage / telemetry metrics** | system | reactive | directs effort, but only *after* use; can't see correctness | Load frequency, hit/miss, failure/over-delegation → fill gaps, fix high-use+high-fail, retire never-used. |
| **8** | **Cross-store / peer learning** | external/org | event-driven | improves quality but doesn't catch *your own* staleness | A better fact in a sibling store propagates (promote to a shared `common/` layer). |

> **The leverage is in the proactive + event-driven channels at the top (ranks 1–4).** They catch
> problems *before* they surface or ship — the only way to reach the stale-high-relevance fact, invisible
> to every reactive channel until it has already produced wrong answers. Most teams wire only the
> reactive bottom (the user-report half of offline feedback, telemetry); the value is at the top.

**This ranking is a *prior*, not an answer — re-rank it by four questions about your actual memory.**
The order above optimizes for generic effectiveness; a real deployment reshuffles it once you know what
the memory is *made of* and what you can actually build. (It's re-ranking, not numeric weighting — each
question *promotes* the channels that fit your case.) The same channel can swing from near-bottom to top:

| # | Question about your memory | What it promotes | Why |
|---|----------------------------|------------------|-----|
| **1** | **What content dominates it?** | time-sensitive world-state → **change-event feed**; a live data source → **re-verification** (values + contract); a large prose store → **offline audit** | the biggest staleness source is whatever your memory is *mostly about* — track *that* kind of change first |
| **2** | **Is a live ground-truth source in the loop?** | **agent-online feedback** + **scheduled re-verification** | if the agent already queries an authoritative source each turn, contradiction-detection (live ≠ stored) fires naturally and often |
| **3** | **Who introduces the errors — your writers, or the world?** | *bad edits* (internal) → **eval gate + offline audit**; *external drift* (the world moves) → **change-event feed + re-verification** | distinct from Q1: Q1 is what the memory is *about*; this is *where wrongness comes from*. Stable content authored carelessly still needs the gate. |
| **4** | **What can you actually build?** | only channels whose inputs + infra exist — CI for the **eval gate**, an authoritative event source for the **change-event feed**, telemetry plumbing for **usage metrics** | effectiveness is moot if it's infeasible; a channel you can't source or run ranks *out*, however high its generic rank |

> **Worked example.** A retail-analytics memory whose facts are mostly *time-sensitive business state*
> (store/banner changes, renames) querying a live warehouse each answer: Q1 pushes the **change-event
> feed** to **#1** (most of the memory is world-state); Q2 lifts **agent-online feedback** (a live source
> is in the loop); Q3 confirms drift, not bad commits, is the dominant error → **re-verification** rises,
> the **eval gate** falls from #1; Q4 then *drops* any channel with no event source to wire. Same
> channels, same effectiveness definition, very different order. **The generic ranking is the default;
> the four questions give you yours.**

> **Two guardrails on the re-ranking.**
> - **Keep a floor.** After re-ranking, retain **at least one preventive (the eval gate) and one
>   proactive channel**, even if demoted — the gate is the *only* channel that stops a bad edit before it
>   ships; re-ranking should reorder priorities, not leave you all-reactive.
> - **Then select, don't just sort.** You'll build 2–4 channels, not 10 — take the **top few after
>   re-ranking**, ensuring the floor is met. And note **Q3 is data-dependent**: you can't know your
>   dominant failure mode until the outcome/telemetry channels (6, 7) have run, so Q3 is the axis that
>   *evolves* — start from Q1/Q2/Q4, let real data re-rank you later.

> **Governance still bounds every channel (§9).** None of these *write* to shared memory — they only
> **propose** a change into a reviewed path. Channels that ingest agent/user/external content (agent
> online feedback, offline feedback, peer learning) must carry **provenance** and be
> treated as **untrusted until reviewed**, or the maintenance loop itself becomes a memory-poisoning
> vector (OWASP ASI06): an attacker who can feed offline feedback or the agent's online channel is
> writing to your memory by proxy.

---

## 8. Personal vs shared (team) memory

Centralization raises a question single-user memory doesn't: **whose memory?**

- **Personal memory** (per-user) — preferences, working style. Writable by that user's agent.
- **Shared / team memory** (org knowledge) — conventions, definitions, institutional facts. The
  high-value centralization target — but also the high-risk one.

Pattern (Anthropic's "remember your users"): **per-user writable stores + a shared read-only store.**
Most agents write only to their own space and *read* the curated shared one; writes to shared memory go
through a stricter, reviewed path (treat shared-memory writes like §9's draft-before-execute).

Centralize team memory via a **synced folder / git repo** (small-medium, transparent, PR-reviewed) or an
**MCP memory server** (large, concurrent, single write authority). A common hybrid: **files for personal
memory, an MCP server for shared team memory.**

### What to share first

Not all memory is worth sharing. Prioritize by **value of sharing ÷ cost of sharing** — the types
separate cleanly:

| # | Type | Share / centralize? | Why | How |
|---|------|---------------------|-----|-----|
| **1** | **Procedural** (skills, workflows, commands, subagents) | ✅ **aggressively, team-wide** | one author → *everyone* levels up; impersonal, durable, already reviewed as code | **git** (`.claude/`) — git-native, free |
| **2** | **Shared semantic** (conventions, definitions, decisions + the *why*) | ✅ **but curate + review** | prevents drift on "what does X mean"; high reuse — but carries staleness + poisoning risk | git shared store / **MCP memory server**, behind review |
| **3** | **Scoped / project memory** | ✅ **with the project team** | high value but *bounded* to the project | project `CLAUDE.md` in the repo (auto-shared) |
| **4** | **Personal semantic** (preferences, style) | ↔ **your own machines, not the team** | personal — your consistency, noise to others | dotfiles / synced folder (per-user) |
| **5** | **Episodic** (raw transcripts) | ❌ **don't centralize raw** | bulky, noisy, privacy-sensitive | keep local; **distill → promote** the gist upward |

> **The principle:** *share what is durable, reusable, and impersonal; keep local what is volatile,
> personal, or noisy.* **Procedural wins** (max durable + reusable + impersonal, and already
> code-reviewed → lowest risk, highest leverage). **Raw episodic loses** — but its value doesn't vanish,
> it **graduates**: an episode where you solved something becomes a **skill** (procedural) or a
> **documented decision** (semantic), and *that* gets shared. You promote the lesson, not the log.

Two cross-cutting rules: **(1)** the more you share, the more **review** you need — shared memory is the
high-risk write target (§9); procedural is safe to share first *because* it already has PR review.
**(2)** mechanism follows type — procedural / scoped / small shared-semantic → **git**; large/concurrent
shared-semantic → **MCP memory server**; personal → **synced folder across your machines**; episodic →
**local, distilled upward**.

### One user, many machines

This is the **same centralization problem, for one person** — and the same two mechanisms solve it. The
catch: most agent-authored knowledge is stored **locally per machine**, so without a sync strategy your
laptop and desktop drift apart.

| Storage | Multi-machine default | How to make it follow you |
|---------|-----------------------|---------------------------|
| **Project `.claude/`** (skills, commands, agents, workflows, project `CLAUDE.md`) | **already in git** | `git clone` on each machine — **free, solved** (best reason to keep things project-level) |
| **User `~/.claude/`** (user `CLAUDE.md`, user skills/commands) | machine-local | a **dotfiles git repo** (or selective synced folder) — sync the *knowledge*, not machine files |
| **Auto-memory** `~/.claude/projects/<id>/memory/` | machine-local | promote durable facts into the git'd project `CLAUDE.md`, or use an MCP memory server |
| **Transcripts** `*.jsonl` *(episodic)* | machine-local, bulky | usually **don't sync**; use a central store only if you need cross-machine history |
| **Cowork app-data** memory | app-managed local, **doesn't auto-sync** | sync/export the memory dir, or use an MCP server |
| **claude.ai chat memory** | **cloud → already multi-machine** | automatic — but siloed and not centralizable (the trade-off) |

**The clean answer: a remote MCP memory server.** One store, every machine queries it —
machine-independent by construction, and it **avoids sync conflicts**. (Synced files written from two
machines produce "conflicted copy" files — the documents caveat again; an MCP server has a **single
write authority**, so no conflicts.) Decision rule, mirroring §10:

- **Mostly project work** → git already covers you.
- **Personal skills + small memory** → a **dotfiles repo** / synced folder.
- **Heavy multi-machine, conflict-free, queryable** → an **MCP memory server**.
- **Casual cross-device chat continuity** → claude.ai's cloud memory (but siloed).

> Two warnings. (1) **Never sync machine-specific files** — device id (`ant-did`), auth tokens, caches,
> sessions, VM bundles; sync only portable knowledge (`CLAUDE.md`, skills, commands, distilled memory).
> (2) **Per type:** procedural syncs cleanly via git (best case); semantic → git for small, MCP server
> for conflict-free; episodic transcripts → leave local; scoped → travels with the repo if it's in the
> project `CLAUDE.md`.

---

## 9. Governance & security — memory poisoning

Persistent memory introduces a threat that transient prompts don't: **memory poisoning** (OWASP
*ASI06* / Agentic-threats *T1*). An attacker writes **false or malicious facts into memory** — directly
(a malicious write to a shared store) or **indirectly** (the agent ingests poisoned external data and
stores it as *trusted* memory). Unlike prompt injection, which ends when the conversation closes,
**poisoning persists and corrupts future sessions** — the exploit waits and triggers later.

Mitigations:

- **Validate on write** — sanity-check what's being stored; don't persist instructions-disguised-as-facts.
- **Provenance / source tagging** — record where a memory came from; distrust facts derived from
  untrusted external content.
- **Human review for shared memory** — writes to team/shared stores are reviewed (the git-PR path makes
  this natural and auditable).
- **Session isolation + auth on memory access** — scope who/what can read and write which store; a
  hijacked instruction still can't exceed that identity (same authorization-layer principle as the
  operational-data doc).
- **Anomaly detection + periodic sanitization** — flag and clean suspicious or contradictory entries.
- **PII / privacy** — be deliberate about storing personal data; honor retention and access controls.

> File-based + git memory is a security asset here: writes are **auditable, attributable, and
> revertible**, and shared-memory changes can require review before they land.

---

## 10. Architecture patterns — choosing the shape

| Pattern | What you get | Use when |
|---------|--------------|----------|
| **File-based (synced folder / git)** | zero infra, transparent, versioned, PR-reviewable | small-to-medium, mostly stable, readability + audit matter — **the default** |
| **MCP memory server** (KG / Mem0-style) | queryable, scalable, single write authority, concurrent | memory is large, structured, or shared across many writers |
| **API memory tool** | runtime-authored client-side files + context editing | an agent runtime manages memory and you want a lean window |
| **Hybrid** | files for personal, MCP server for shared team memory | mixed personal + org memory at scale |

**Decision rule:** start **file-based**; switch to an **MCP memory server** once memory grows past what
you'd keep permanently in context, or when it must be structured/queried or shared with concurrent
writes.

---

## 11. Failure modes to design against

- **Memory poisoning** → validate on write, provenance, review shared writes, isolation.
- **Stale high-relevance facts** → contradiction detection on write + periodic review.
- **No maintenance signal** (only "a human reports it") → wire **multiple feedback channels** (§7),
  including **proactive** ones (re-verification, drift watchers, offline audit, eval gate) — reactive
  reporting alone never catches the stale-high-relevance fact.
- **Context bloat** (too much loaded every turn) → index + retrieve; progressive disclosure.
- **Missed recall** (relevant fact not retrieved) → good indexing/embeddings; hierarchical recall.
- **Contradictions / duplicates** → consolidate on write (update, don't append); dedup.
- **Privacy leak** → deliberate PII handling; access control on shared stores.
- **Siloing** → remember claude.ai memory doesn't centralize; use file-based surfaces.

---

## 12. Takeaways

1. **Memory is how the stateless model persists state** (P1) — and it's just **files or calls** (P7), so
   it centralizes via a synced folder or an MCP server, like everything else.
2. **claude.ai memory is siloed; Claude Code's and Cowork's are local files** — centralize with the
   file-based surfaces, not the chat app.
3. **Capture is curation** — store durable, reusable, **non-derivable** facts as **atomic** units;
   extract then consolidate. Guidance, not defaults, decides quality.
4. **Recall = load vs retrieve** (P6) — small/stable memory loads into context; large/growing memory
   needs an index + retrieval (the discovery problem again).
5. **Forgetting is a real operation** — decay, dedup, and especially **conflict/staleness resolution**;
   file-based + git makes memory revisable, auditable, revertible.
6. **Shared memory is high-value and high-risk** — per-user writable + shared read-only; review writes.
7. **Memory poisoning is persistent compromise** (OWASP ASI06) — validate on write, tag provenance,
   review shared writes, contain at the authorization layer.
8. **Maintenance needs feedback channels** — you can't fix what you can't see. Span **origin** (human ·
   agent · system · external) and **timing** (reactive *and* **proactive**); most teams wire only "a
   human reports it," which is exactly blind to the stale-high-relevance fact. The proactive,
   external-driven, and outcome-quality channels close that gap — each one **proposes** into a reviewed
   path, never writes directly.

---

## References

- [Anthropic — Memory tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)
- [Anthropic — Context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing)
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Memory cookbook](https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/memory_cookbook.ipynb)
- [Anthropic — Build agents that remember user preferences (cookbook)](https://platform.claude.com/cookbook/managed-agents-cma-remember-user-preferences)
- [Anthropic — Use Claude's chat search and memory](https://support.claude.com/en/articles/11817273-use-claude-s-chat-search-and-memory-to-build-on-previous-context)
- [Anthropic — How Claude Code manages memory (CLAUDE.md + auto-memory)](https://code.claude.com/docs/en/memory)
- [Anthropic — Claude Desktop on 3P: Data storage](https://claude.com/docs/cowork/3p/data-storage)
- [Anthropic — Claude Desktop on 3P: Extensions (MCP, plugins, skills)](https://claude.com/docs/cowork/3p/extensions)
- [Model Context Protocol — Knowledge Graph Memory server](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)
- [mcp-memory-service (PyPI)](https://pypi.org/project/mcp-memory-service/)
- [Mem0 — Building Production-Ready AI Agents with Scalable Long-Term Memory](https://arxiv.org/abs/2504.19413)
- [MemGPT — Towards LLMs as Operating Systems](https://arxiv.org/abs/2310.08560)
- [OWASP — Top 10 for Agentic Applications (ASI06: Memory Poisoning)](https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/)
- [OWASP — Agent Memory Guard](https://owasp.org/www-project-agent-memory-guard/)
- [Lakera — Agentic AI Threats: Memory Poisoning & Long-Horizon Goal Hijacks](https://www.lakera.ai/blog/agentic-ai-threats-p1)
- [Christian Schneider — Persistent memory poisoning in AI agents](https://christian-schneider.net/blog/persistent-memory-poisoning-in-ai-agents/)
