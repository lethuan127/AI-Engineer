# Harness Engineering — Design Spec

> Date: 2026-05-22
> Status: Approved (brainstorm)
> Scope: Apply harness engineering to this repo for both Cursor and Claude Code, and seed `11. Harness Engineering/` with curriculum content documenting the discipline.

---

## 1. Goal

Two outcomes from one effort:

1. **Configure a working harness** in this repo so Cursor and Claude Code authoring sessions are faster, more consistent, and less error-prone — turning the repo's tacit conventions (numbered filenames, References sections, vendor-neutral architectural framing) into rules the agent enforces automatically.
2. **Document harness engineering as a discipline** in the `11. Harness Engineering/` curriculum folder, in the same style as `7.1` / `7.2` (dense, architectural, vendor-neutral primitives first, vendor specifics second).

The two outcomes reinforce each other: the configuration is the worked example the curriculum points at, and the curriculum is the source of truth that the configuration enforces.

## 2. Framing — How Section 11 Differs From Section 7

- **Section 7** (`AI System Architecture`) treats the agent harness as a **backend platform you build or buy** — Claude Managed Agents, OpenAI Assistants, or your own implementation of the components in `7.2`.
- **Section 11** (`Harness Engineering`) treats the harness as a **practice you apply** as a *consumer* of an existing coding agent (Cursor, Claude Code, Codex CLI, Copilot CLI). The primitives are repo memory files, rules, skills, hooks, slash commands, subagents, MCP servers — the surfaces the editor exposes for shaping agent behavior inside a codebase.

The README of section 11 makes this distinction explicit and cross-links to `7.1` / `7.2`.

## 3. Curriculum Outline (`11. Harness Engineering/`)

```
README.md                                  — overview, mental model, learning path, 7.* cross-links
11.1. What Is a Harness.md                 — definition, harness loop, why it matters as a practice
11.2. Repo Memory — AGENTS.md & Friends.md — root instruction files, precedence, what belongs there
11.3. Rules and Project Instructions.md    — Cursor rules .mdc, Claude project memory, scoping
11.4. Skills.md                            — SKILL.md format, description-as-router, distribution
11.5. Hooks, Permissions, Side Effects.md  — event hooks, allow/deny, secret hygiene
11.6. Slash Commands and Subagents.md      — when to use which; parent/child context isolation
11.7. Tools and MCP.md                     — built-in/custom/MCP taxonomy, MCP servers
11.8. Context Engineering in the Harness.md — caching, compaction, attachments, fs-as-memory
11.9. Vendor Diff Matrix.md                — Cursor / Claude Code / Codex CLI / Copilot CLI table
11.10. Reference Implementation Tour.md    — walkthrough of this repo's configured harness
11.11. Operational Concerns.md             — versioning, drift, eval, multi-developer governance
```

Each note targets ~150–250 lines, dense, with tables, opinionated takeaways, and a `## References` section. No emojis except where they encode meaning (e.g., the 🟢🟡🔴 build-tier convention already established in `7.2`).

## 4. Harness Configuration (created in repo)

### 4.1 Universal

`AGENTS.md` (repo root) — primary instruction file. Both Cursor and Claude Code (in current versions) read it. Contains:

- Repo purpose: AI Engineering curriculum, mostly markdown notes.
- Style guide: heading levels, code-fence rules, table preference, no emoji unless asked.
- Naming convention: `X.Y. Title Case.md` for numbered notes; lowercase-hyphenated for stubs.
- Required structure: every substantive note ends with a `## References` section of bullet links.
- Folder conventions: numbered top-level folders; new sections require user confirmation.
- Forbidden actions: editing files outside the curriculum tree without confirmation; adding LLM-generated link-bait references.

### 4.2 Cursor

- `.cursor/rules/markdown-style.mdc` — *Always*-applied, scoped to `*.md`. Formatting, heading levels, code fences, table preference.
- `.cursor/rules/references-section.mdc` — *Auto-Attached* when editing `[0-9]*/*.md`. Enforces trailing `## References` section.
- `.cursor/rules/naming-convention.mdc` — *Agent-Requested*. Used when the agent creates new files; encodes the `X.Y. Title Case.md` pattern.
- `.cursor/rules/no-emoji.mdc` — *Always*. Suppresses emoji decoration in notes (allows the 🟢🟡🔴 tier convention as exception).
- `.cursor/commands/new-note.md` — slash command scaffolding a numbered note.
- `.cursor/commands/check-refs.md` — slash command validating the References section of the current note.
- `.cursor/mcp.json` — pins `context7` at repo level so cloners get doc-lookup MCP.
- `.cursor/hooks.json` — `afterFileEdit` hook on `*.md` warns if no `## References` section.
- `.cursor/hooks/check-references.sh` — script implementing the hook check.

### 4.3 Claude Code

- `.claude/settings.json` — minimal, project-scoped permissions and hook registration.
- `.claude/commands/new-note.md` — same slash command as Cursor (single source of truth duplicated by content).
- `.claude/commands/check-refs.md` — same.
- `.claude/agents/curriculum-author.md` — subagent specialized in writing notes in this repo's voice.
- `.claude/agents/reference-validator.md` — subagent that fetches every link in a note and reports broken ones.
- `.claude/hooks/check-references.sh` — same script as Cursor's, symlinked or duplicated.

### 4.4 Skills (shared source of truth)

- `.claude/skills/add-curriculum-note/SKILL.md` — discovery + structure for new numbered notes.
- `.claude/skills/normalize-references/SKILL.md` — references-section format and validation steps.

Cursor rules reference these SKILL.md files by path so both surfaces use the same source.

## 5. Deliberately Out of Scope

- **No per-vendor curriculum duplication.** Vendor specifics live in `11.9 Vendor Diff Matrix.md` and in inline call-outs only.
- **No MCP servers beyond context7.** This is a notes repo, not a service — no need for filesystem/git/database MCPs.
- **No heavy hook chain.** One `afterFileEdit` reference-validator hook demonstrates the primitive. Adding more (lint, spellcheck, link-fetch) is left as an exercise documented in `11.5`.
- **No CI integration.** The harness shapes interactive agent behavior; CI is a separate axis covered briefly in `11.11` but not configured here.

## 6. Success Criteria

1. A clone of the repo opened in Cursor and in Claude Code both pick up the relevant configuration without manual setup.
2. Creating a new note via `/new-note` produces a file that satisfies all rules without manual fixing.
3. `11. Harness Engineering/` curriculum reads as a coherent self-contained track, in the same style as `7.1` / `7.2`.
4. The Reference Implementation Tour (`11.10`) can be followed by a reader using only the curriculum + the configured files.
5. No emoji decoration in any new note (except the 🟢🟡🔴 tier convention when used semantically).

## 7. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Vendor surfaces churn (Cursor and Claude Code update monthly) | Curriculum focuses on primitives; `11.9 Vendor Diff Matrix.md` is the only vendor-version-sensitive note and is dated. |
| Hooks fire on unrelated edits and become noise | Scope to `*.md` only, warn rather than block. |
| AGENTS.md / .cursor rules / .claude memory drift | `11.11 Operational Concerns.md` documents the single-source-of-truth approach (skills) and the drift-detection pattern. |
| Subagents are Claude Code-specific | Curriculum frames subagents as a primitive any harness can implement; Cursor's "explore" / "Task" tool is the equivalent and is called out. |

## 8. Decision Log

- **B over A and C** for curriculum structure: principles-first beats vendor-parallel (avoids duplication) and beats exhaustive cross-vendor (avoids churn).
- **AGENTS.md** chosen as the universal entry point over `CLAUDE.md` / `.cursorrules`. Both Cursor (2026+) and Claude Code read `AGENTS.md`; it is also the agreed convention across the ecosystem (OpenAI Codex CLI, Aider, others).
- **Skills live in `.claude/skills/`** and are referenced by Cursor rules rather than duplicated. Avoids drift.
- **Subagents are Claude Code only** in the configuration. Cursor's equivalent is the `Task` tool dispatched against the user-global `subagent_type`s; not configurable per-repo.
