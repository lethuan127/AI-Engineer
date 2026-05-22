---
description: Scaffold a new numbered curriculum note in a track folder.
argument-hint: <track-folder-or-number> <title>
---

# /new-note

Create a new numbered curriculum note. Mirrors `.cursor/commands/new-note.md` so the same workflow works in Claude Code.

## Steps

1. Confirm the target track folder exists. If the user provided a track number only (e.g. `5`), expand it by listing the repo root and matching `^5\. `.
2. List existing notes in the target folder (`^[0-9]+\.[0-9]+\. `) and compute the next sequential number `X.(maxY + 1)`.
3. Read `AGENTS.md` for the house style.
4. Read at least one existing note in the same track as a structural reference. Fall back to `7.1. Claude Platform Managed Agent.md`.
5. Invoke the `add-curriculum-note` skill (`.claude/skills/add-curriculum-note/SKILL.md`) and follow its scaffolding workflow.
6. Create the file with the scaffolded structure:
   - `# X.Y. Title Case`
   - Optional `> Source: …` / `> Companion to …` blockquote
   - At least one `## 1. …` section as a starting point
   - Trailing `## References` section (empty bullet list — to be filled in)
7. Update the track's `README.md` to list the new note with a one-sentence summary.
8. Report the created path and the README diff.

## Constraints

- Do NOT add LLM-generated reference URLs. Leave the References list empty until the user provides sources.
- Do NOT create the file if a note with the same number already exists; stop and ask.
- Do NOT create new track folders (e.g. `12. …`) without explicit user confirmation.
