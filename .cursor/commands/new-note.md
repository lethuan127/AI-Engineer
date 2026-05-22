---
description: Scaffold a new numbered curriculum note in a track folder.
---

# /new-note

Create a new numbered curriculum note. Usage:

> `/new-note <track-folder> <title>`
>
> Example: `/new-note "5. AI Agents & Tool Use" "Programmatic Tool Calling"`

## Steps

1. **Confirm the target track folder exists.** If the user provided a track number only (`5`), expand it to the folder name by listing the repo root and matching `^5\. `.
2. **Compute the next `X.Y` number.** List files in the target folder matching `^[0-9]+\.[0-9]+\. `. The new note's number is `X.(maxY + 1)`.
3. **Build the filename:** `X.Y. Title Case.md`. Use real spaces. Em-dash for subtitles.
4. **Read `AGENTS.md`** to refresh the house style rules.
5. **Read at least one existing note in the same track** as a structural reference. If the track has no notes yet, fall back to `7.1. Claude Platform Managed Agent.md`.
6. **Read [`.claude/skills/add-curriculum-note/SKILL.md`](../../.claude/skills/add-curriculum-note/SKILL.md)** and follow its scaffolding workflow.
7. **Create the file** with the scaffolded structure:
   - `# X.Y. Title Case`
   - Optional `> Source: …` / `> Companion to …` blockquote
   - At least one `## 1. …` section as a starting point
   - Trailing `## References` section (empty bullet list — to be filled in)
8. **Update the track's `README.md`** to list the new note with a one-sentence summary.
9. **Report** the created path and the README diff.

## Constraints

- Do NOT add LLM-generated reference URLs. Leave the References list with a single placeholder bullet `- ` or skip until the user provides sources.
- Do NOT create the file if a note with the same number already exists; ask the user how to disambiguate.
- Do NOT create new track folders. If the user asks for one (`12. …`), stop and confirm first.
