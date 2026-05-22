# How self-improvement works in `hermes-agent`

Self-improvement is a two-layer system: **per-turn review** (agent learns from the conversation just finished) and **periodic curation** (agent prunes/consolidates what it has learned over time). Both write into the same store — `~/.hermes/skills/` — but use different triggers, different prompts, and different safety rules.

## Layer 1 — Per-turn background review

Implemented in `run_agent.py::_spawn_background_review`. After a user-facing turn completes, the agent decides whether to fire a review pass.

### Triggers (checked at the end of `run_conversation`)

| Dimension | Counter | Default | Reset when |
|---|---|---|---|
| Memory | `_turns_since_memory` | every 10 user turns | `memory` tool used |
| Skills | `_iters_since_skill` | every 10 tool iterations | `skill_manage` used |

Configured via `memory.nudge_interval` and `skills.creation_nudge_interval` in `config.yaml`. Setting `0` disables.

Counters hydrate from the session's persisted history on cache miss so a fresh `AIAgent` (the gateway makes one per inbound message) doesn't reset the cadence — see `run_agent.py` around line 11841.

### What it does

```4212:4354:run_agent.py
    def _spawn_background_review(
        self,
        messages_snapshot: List[Dict],
        review_memory: bool = False,
        review_skills: bool = False,
    ) -> None:
        """Spawn a background thread to review the conversation for memory/skill saves.
        ...
        """
```

The function:

1. Picks one of three system prompts based on which trigger fired:
   - `_MEMORY_REVIEW_PROMPT` — "who is the user?"
   - `_SKILL_REVIEW_PROMPT` — "how to do this class of task?"
   - `_COMBINED_REVIEW_PROMPT` — both
2. Forks a new `AIAgent` on a **daemon thread**, inheriting the parent's provider/model/auth (so OAuth + credential-pool setups still work), `max_iterations=16`, `quiet_mode=True`, `enabled_toolsets=["memory", "skills"]`.
3. Marks the fork with `_memory_write_origin = "background_review"` — this provenance bit is how `tools/skill_provenance.py` tags everything the fork creates as **agent-created** (which is what the curator targets later).
4. Replays the conversation as `conversation_history` and appends the review prompt as the next user message.
5. Auto-denies any dangerous-command guard prompt (the fork has no human to ask, see `_bg_review_auto_deny`).
6. Suppresses all status output. Only the final summary surfaces back to the user as `💾 Self-improvement review: <actions>`.
7. Optionally calls `background_review_callback` so gateway platforms (Telegram, Discord, etc.) can deliver the same summary.

### The review prompts encode policy

The skill prompt around `run_agent.py:3977` is the real specification — it ranks update paths in order: **(1) patch a currently-loaded skill → (2) update an existing umbrella → (3) add a `references/templates/scripts/` support file under an umbrella → (4) create a new class-level umbrella as a last resort**. It also lists explicit **do-not-capture** classes (environment-dependent failures, negative claims about tools, session-specific transients, one-off task narratives) — these have historically calcified into self-imposed refusals.

## Layer 2 — The Curator (skill lifecycle)

`agent/curator.py` plus the `hermes curator <verb>` CLI. Runs in a background fork triggered by an **inactivity check**, not a cron — see `website/docs/user-guide/features/curator.md`.

### Triggers

- Run on CLI session start + on gateway cron-ticker.
- Fires only when `interval_hours` (default 7 days) and `min_idle_hours` (default 2h) have both elapsed.
- First-run is deferred one full interval after install so the user can pin/disable before anything happens.

### Two phases per run

1. **Automatic transitions** (deterministic, no LLM). `last_used_at` older than 30 days → `stale`. Older than 90 → moved to `~/.hermes/skills/.archive/`.
2. **LLM review** (`auxiliary.curator` slot, `max_iterations=8`). Reads usage stats + skills, can patch/consolidate via `skill_manage`, can archive via terminal. Writes `~/.hermes/logs/curator/<ts>/{run.json,REPORT.md}`.

### Invariants (the boundary that makes it safe to leave on by default)

- Only touches skills whose name is **not** in `.bundled_manifest` and **not** in `.hub/lock.json`. Bundled and hub skills are off-limits.
- **Never deletes.** Max destructive action is archive, recoverable via `hermes curator restore <name>`.
- Takes a `tar.gz` snapshot of `~/.hermes/skills/` to `~/.hermes/skills/.curator_backups/<utc>/` before every mutating pass. `hermes curator rollback` undoes the whole run.
- Pinned skills are exempt from auto-transitions and from `skill_manage(action="delete")`. Pin via `hermes curator pin <name>`; stored in `~/.hermes/skills/.usage.json`.

### Telemetry that drives staleness

`tools/skill_usage.py` owns the sidecar `~/.hermes/skills/.usage.json`:

- `view_count` — increments on `skill_view`
- `use_count` — increments when loaded into prompt
- `patch_count` — increments on `skill_manage patch/edit/write_file/remove_file`
- `last_used_at`, `last_viewed_at`, `last_patched_at`, `state`, `pinned`, `archived_at`

Bundled and hub skills are excluded from telemetry writes entirely.

## The end-to-end flow

```
User turn N completes
     │
     ▼
Trigger check (memory turn count OR skill iteration count)
     │
     ▼  (best-effort, never blocks user response)
_spawn_background_review() — daemon thread
     │
     ├─ Fork AIAgent (memory + skills toolsets only)
     ├─ Set _memory_write_origin = "background_review"
     ├─ Run review prompt against conversation history
     └─ skill_manage(...) / memory(...) calls land in
        ~/.hermes/skills/  and  the memory provider
              │
              ▼  (skill_provenance ContextVar marks these
                  writes as "agent-created")
              ▼
~7 days idle later: Curator wakes up
     │
     ├─ Auto-transition stale (30d) / archive (90d)
     ├─ Optional LLM review pass
     └─ Snapshot + report under ~/.hermes/logs/curator/
```

## What to keep in mind when changing this code

1. **Provenance is binary.** `agent-created` = "not in `.bundled_manifest` and not in `.hub/lock.json`". A hand-written skill the user dropped in `~/.hermes/skills/` looks identical to one the review fork saved. The pin mechanism is the user's escape hatch.
2. **The review fork is not durable.** It's a `threading.Thread(daemon=True)` — if the process exits, it dies. Long-lived work belongs in `cronjob` or the curator, not here.
3. **The fork must not break prompt caching.** It uses its own messages list and its own model call — it never mutates the parent's `messages` or `_cached_system_prompt`. Per `AGENTS.md`, mid-conversation system-prompt mutation is forbidden.
4. **Dangerous commands auto-deny** in the fork (`_bg_review_auto_deny`). Any new approval gate needs to handle the "no human present" case the same way, or the fork deadlocks on `input()` under `prompt_toolkit`'s `patch_stdout`.
5. **Curator runs on the `auxiliary.curator` aux-task slot** — not the main chat model by default. To pin a cheaper reviewer, `hermes model` → "Auxiliary models" → "Curator", or set `auxiliary.curator.{provider,model}` in `config.yaml`.

Reference points if you go deeper:

- Review fork: `run_agent.py::_spawn_background_review`, `_MEMORY_REVIEW_PROMPT` / `_SKILL_REVIEW_PROMPT` / `_COMBINED_REVIEW_PROMPT` (around line 3966–4147).
- Trigger checks: `run_agent.py` line ~11881 (memory) and ~15488 (skills).
- Provenance ContextVar: `tools/skill_provenance.py`.
- Curator engine: `agent/curator.py`, `agent/curator_backup.py`.
- Telemetry: `tools/skill_usage.py`.
- User-facing docs: `website/docs/user-guide/features/skills.md` (the loop) and `website/docs/user-guide/features/curator.md` (the maintenance pass).