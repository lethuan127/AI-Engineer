# How Hermes Agent Self-Improves

A practical, code-level explanation of the learning loop that makes Hermes "the only agent with a built-in learning loop." This document is for someone who wants to understand *exactly* what happens, when it fires, and where it lives in the codebase — not just the marketing summary.

---

## TL;DR

Hermes gets better at *your* tasks over time through **four cooperating mechanisms**, none of which require retraining the model:

| Mechanism | What it learns | Where it's stored | When it fires |
|-----------|----------------|-------------------|---------------|
| **Persistent memory** | Who you are, your preferences, environment facts | `~/.hermes/memories/MEMORY.md` + `USER.md` | Nudged every N turns + on-demand |
| **Skills (procedural memory)** | *How* to do a class of task | `~/.hermes/skills/<category>/<skill>/` | Nudged every N tool-iterations + on-demand |
| **Background self-improvement review** | Both of the above, autonomously | shared memory/skill stores | After a turn completes, in a forked agent |
| **The Curator** | Keeps the skill library healthy | `~/.hermes/skills/` (+ `.archive/`) | Idle-triggered, ~weekly |

Two more support recall rather than learning:
- **Session search** — FTS5 full-text search over every past conversation (`~/.hermes/state.db`).
- **External memory providers** (Honcho, Mem0, …) — deeper, server-side user modeling layered *on top of* built-in memory.

The key architectural idea: **learning happens out-of-band**. The model that's helping you isn't distracted by bookkeeping — a separate forked agent reviews the conversation *after* your answer is delivered and writes to the shared stores.

---

## 1. The two kinds of memory

Hermes draws a sharp line that's worth internalizing:

> **Memory** = "who the user is and what the current state of operations is."
> **Skills** = "how to do this class of task for this user."

This distinction drives every routing decision in the learning loop. A *preference* ("I hate verbose explanations") goes to **both** — memory records the fact, but the *skill that governs the offending task* gets patched so the next session starts already fixed.

### 1a. Persistent Memory — `MEMORY.md` and `USER.md`

Two small, hard-capped files injected into the system prompt at session start:

| File | Purpose | Char limit |
|------|---------|-----------|
| `MEMORY.md` | Agent's own notes — environment facts, conventions, lessons | 2,200 chars (~800 tokens) |
| `USER.md` | User profile — identity, communication style, expectations | 1,375 chars (~500 tokens) |

Important properties:

- **Frozen snapshot.** Memory is loaded into the system prompt *once* at session start and never changes mid-session — this protects the LLM prefix cache. Writes hit disk immediately, but only appear in the prompt next session. (Tool responses always show live state.)
- **Bounded on purpose.** Tight limits force consolidation. When full, the agent must `replace`/`remove` before it can `add`. This keeps the agent from drowning in stale notes.
- **Managed by the `memory` tool** with three actions: `add`, `replace`, `remove` (substring matching via `old_text` — no need for full entry text). There is no `read` — it's already in context.
- **Security-scanned.** Entries are checked for prompt injection, credential exfiltration, and invisible Unicode before being accepted, because they land in the system prompt.

### 1b. Skills — procedural memory

Skills are on-demand knowledge documents (`SKILL.md` + optional `references/`, `templates/`, `scripts/`) that follow **progressive disclosure**:

```
Level 0: skills_list()           → [{name, description, category}]   (~3k tokens, always in prompt)
Level 1: skill_view(name)        → full SKILL.md
Level 2: skill_view(name, path)  → a specific reference file
```

The full content only loads when actually needed, so a large library costs almost nothing until used.

The agent writes its own skills via the **`skill_manage` tool**:

| Action | Use for |
|--------|---------|
| `create` | New skill from scratch |
| `patch` | Targeted fix (**preferred** — token-efficient, only the diff is in the call) |
| `edit` | Major structural rewrite (full replacement) |
| `delete` | Remove a skill |
| `write_file` / `remove_file` | Add/remove a `references/`, `templates/`, or `scripts/` support file |

All agent-created skills land in `~/.hermes/skills/`. **Bundled** skills (shipped with the repo) and **hub-installed** skills are never modified by the learning loop or curator — only skills the agent itself authored.

---

## 2. The nudge system — *when* the agent is reminded to learn

Left alone, an LLM finishes a task and moves on; it doesn't spontaneously decide to journal what it learned. Hermes solves this with **periodic nudges** — two independent counters that, when they trip, schedule a review.

Both live on the agent instance (`run_agent.py`), default interval **10**, configurable:

```yaml
# config.yaml
memory:
  nudge_interval: 10            # review memory every 10 user turns
skills:
  creation_nudge_interval: 10   # review skills every 10 tool iterations
```

### Memory nudge — turn-based
- Counter `_turns_since_memory` increments **once per user turn**.
- At `>= nudge_interval`, it sets `_should_review_memory = True` and resets.
- On session resume, the counter is *hydrated* from persisted history (`prior_user_turns % interval`) so short sessions don't reset progress and never reach the trigger.
- Resets to 0 whenever the `memory` tool is actually used (no point nudging right after a save).

### Skill nudge — iteration-based
- Counter `_iters_since_skill` increments **per tool-calling iteration within a turn**.
- Checked *after* the agent loop finishes, based on how many tool iterations *this turn* used. At `>= interval` → `_should_review_skills = True`, reset.
- Resets to 0 whenever `skill_manage` is used.

The two counters are deliberately different units: memory tracks *conversations* (you reveal yourself over turns), skills track *work* (a procedure is worth saving after enough tool calls). A long, tool-heavy task triggers a skill review; a long chatty session triggers a memory review.

---

## 3. The background self-improvement review — the heart of the loop

This is the mechanism that makes it autonomous. Code: `AIAgent._spawn_background_review()` in `run_agent.py`.

### How it runs
When `_should_review_memory` or `_should_review_skills` is set, **after the final response is delivered to you** (`if final_response and not interrupted`), Hermes spawns a **background thread** containing a *full fork* of the agent:

```python
review_agent = AIAgent(
    model=self.model,                 # same model
    max_iterations=16,
    quiet_mode=True,
    enabled_toolsets=["memory", "skills"],   # only memory + skill tools
    parent_session_id=self.session_id,
    # inherits parent's live provider / base_url / api_key / api_mode
)
review_agent._memory_store = self._memory_store   # writes to the SHARED store
```

Critical design choices, with the *why*:

- **Runs after your answer.** The review never competes with your task for the model's attention. You get your answer at full speed; learning happens in the background.
- **Forked context, isolated thread.** The fork gets a snapshot of the conversation as its history, runs in its own prompt cache, and **never modifies the main conversation** or produces user-visible output (beyond a one-line summary).
- **Inherits live runtime credentials.** It copies the parent's provider/model/key/api_mode rather than re-resolving from env — so OAuth-only providers and credential pools keep working in the fork.
- **Auto-denies dangerous commands.** The worker thread installs a non-interactive approval callback that resolves any dangerous-command guard to `deny` — it can't deadlock against the TUI or run something destructive unsupervised.
- **Silent except for the summary.** All status/warning output is suppressed; you only see a compact line like:
  `💾 Self-improvement review: updated skill 'deploy-k8s' · saved user preference`

### The three review prompts
Which prompt the fork receives depends on which triggers fired (`_MEMORY_REVIEW_PROMPT`, `_SKILL_REVIEW_PROMPT`, or `_COMBINED_REVIEW_PROMPT`). Their contents encode the actual *learning policy*:

**Memory review** asks: did the user reveal persona/preferences, or express expectations about how you should behave? Save with the `memory` tool, else "Nothing to save."

**Skill review** is the richest and most opinionated. Its policy:

- **Be ACTIVE.** "Most sessions produce at least one skill update… A pass that does nothing is a missed learning opportunity, not a neutral outcome." It deliberately biases *toward* writing.
- **Target shape: class-level umbrella skills**, each with a rich `SKILL.md` + `references/` for detail — *not* a flat list of narrow one-session skills.
- **Signals that warrant action:** user corrected your style/tone/verbosity (frustration is a *first-class* skill signal, not just memory); user corrected your workflow; a non-trivial technique/fix emerged; a loaded skill turned out wrong.
- **Preference order** (pick the earliest that fits):
  1. **Patch a currently-loaded skill** — the one that was in play.
  2. **Patch an existing umbrella** found via `skills_list` + `skill_view`.
  3. **Add a support file** under an umbrella: `references/` (session detail / knowledge banks), `templates/` (copy-and-modify starters), `scripts/` (re-runnable probes).
  4. **Create a new class-level umbrella** — only when nothing fits. The name MUST be class-level, never a PR number, error string, codename, or "fix-X-today" artifact.
- **Anti-patterns it explicitly refuses to capture** (these are the guardrails that keep self-improvement from poisoning itself):
  - Environment-dependent failures (missing binaries, "command not found", unconfigured creds) — the user can fix these; they aren't durable rules.
  - **Negative claims** about tools ("browser tools don't work", "X is broken") — "These harden into refusals the agent cites against itself for months after the actual problem was fixed."
  - Transient errors that resolved before the session ended (the lesson is the retry pattern, not the failure).
  - One-off task narratives ("summarize today's market").
  - If a tool failed due to setup state, capture the *fix* (install/config step) under a troubleshooting skill — never "this tool doesn't work."

This negative-space policy is as important as the positive one: a naïve self-improving agent slowly accumulates self-imposed constraints and gets *worse*. Hermes's prompts are tuned to avoid exactly that failure mode.

---

## 4. The Curator — keeping the library healthy at scale

Docs: `website/docs/user-guide/features/curator.md`. The self-improvement loop *creates* skills; without maintenance you'd end up with dozens of narrow near-duplicates polluting the catalog and wasting tokens. The curator is the garbage-collector / librarian.

### When it runs
**Not a cron daemon** — an *inactivity check*. On CLI start and on a recurring gateway tick, it checks:
1. Enough time since last run (`interval_hours`, default **168** = 7 days), **and**
2. Agent idle long enough (`min_idle_hours`, default **2** hours).

Both true → it spawns a background `AIAgent` fork (same pattern as the review nudges). On a brand-new install it defers the first real pass by a full interval, giving you time to review/pin/opt-out first.

### What it does — two phases
1. **Automatic transitions** (deterministic, no LLM): skills unused for `stale_after_days` (30) → `stale`; unused for `archive_after_days` (90) → moved to `~/.hermes/skills/.archive/`.
2. **LLM review** (single aux-model pass, `max_iterations=8`): surveys agent-created skills, reads them with `skill_view`, and decides per-skill to keep / patch / consolidate overlapping ones / archive.

### Safety rails
- **Only touches agent-created skills** — never bundled or hub-installed ones.
- **Never deletes** — worst case is archival into `.archive/` (recoverable).
- **Pinned skills are off-limits** to both auto-transitions and the agent's own `skill_manage`.
- Has its own backup/rollback: `hermes curator backup` / `rollback`.

```yaml
curator:
  enabled: true
  interval_hours: 168
  min_idle_hours: 2
  stale_after_days: 30
  archive_after_days: 90
```

Key CLI: `hermes curator status | run [--dry-run|--background] | pin <skill> | unpin | pause | resume | rollback`.

The curator's LLM pass is a routable auxiliary slot (`auxiliary.curator`) — you can pin it to a cheaper model (e.g. a Flash-class model) so weekly maintenance costs little.

---

## 5. Recall (not learning, but part of the loop)

### Session search
Every CLI and messaging session is stored in SQLite (`~/.hermes/state.db`) with **FTS5 full-text search**. The `session_search` tool finds past conversations and summarizes the hits (Gemini-Flash-class aux model). This is the "did we discuss X three weeks ago?" path — unbounded, on-demand, complementary to the always-in-context MEMORY.md.

| | Persistent Memory | Session Search |
|---|---|---|
| Capacity | ~1,300 tokens total | Unlimited (all sessions) |
| Speed | Instant (in prompt) | Search + LLM summarize |
| Use case | Facts always needed | Recall a specific past chat |

### External memory providers (Honcho et al.)
Eight pluggable backends (Honcho, Mem0, OpenViking, Hindsight, …) run *alongside* built-in memory, never replacing it. **Honcho** adds **dialectic reasoning**: after each turn (gated by `dialecticCadence`), it reasons about the exchange to derive insights about your preferences, habits, and goals that accumulate server-side — a deepening user model that goes beyond what you explicitly stated, with per-agent ("peer") profile isolation.

---

## 6. End-to-end: a turn through the lens of self-improvement

```
You send a message
        │
        ▼
  Memory + skill nudge counters increment
        │
        ▼
  Agent does the work (tool calls, etc.) ──► You get your answer (full speed)
        │
        ▼
  Did a nudge trip this turn?  ──no──► done
        │ yes
        ▼
  Spawn background review fork (separate thread, shared stores)
        │
        ▼
  Fork reads conversation, applies the learning policy:
     • save user facts/preferences  → memory tool
     • patch/create/extend a skill  → skill_manage tool
        │
        ▼
  One-line summary: "💾 Self-improvement review: …"
        │
   ... days later, agent idle 2h+ ...
        ▼
  Curator: stale→archive transitions + LLM consolidation pass
```

Next session, the updated `MEMORY.md`/`USER.md` are in the system prompt, and the improved skills are in the `skills_list` index — so the agent starts already knowing.

---

## 7. Where to look in the code / docs

| Concern | Location |
|---------|----------|
| Nudge counters & triggers | `run_agent.py` (`_turns_since_memory`, `_iters_since_skill`, `_memory_nudge_interval`, `_skill_nudge_interval`) |
| Background review fork | `run_agent.py::_spawn_background_review` (~L4212) |
| Review policy prompts | `run_agent.py` `_MEMORY_REVIEW_PROMPT` / `_SKILL_REVIEW_PROMPT` / `_COMBINED_REVIEW_PROMPT` (~L3966) |
| `skill_manage` tool | `tools/skill_manager_tool.py` |
| Memory feature doc | `website/docs/user-guide/features/memory.md` |
| Skills feature doc | `website/docs/user-guide/features/skills.md` |
| Curator feature doc | `website/docs/user-guide/features/curator.md` |
| Honcho / providers | `website/docs/user-guide/features/honcho.md`, `memory-providers.md` |

---

## 8. The one-sentence mental model

> Hermes treats every conversation as training data for *itself*: a background fork reviews each meaningful turn against a carefully-tuned learning policy, writes durable facts to bounded memory and durable procedures to a progressively-disclosed skill library, and a periodic curator prunes and consolidates that library — so the agent improves at *your* tasks without ever retraining the underlying model.
