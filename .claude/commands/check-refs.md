---
description: Validate the References section of a curriculum note.
argument-hint: "[path] [--fix]"
---

# /check-refs

Audit and optionally repair the `## References` section of a curriculum note. Mirrors `.cursor/commands/check-refs.md` so the same workflow works in Claude Code.

## Steps

1. Resolve the target file:
   - With no path argument, use the currently focused markdown file from `$ARGUMENTS`.
   - Refuse politely if the file is not a numbered note in a track folder.
2. Read `.claude/skills/normalize-references/SKILL.md` and follow it as the source of truth.
3. Structural checks:
   - Exactly one `## References` heading.
   - It is the last `##` heading in the file.
   - Every non-blank line under it matches `^- \[.+?\]\(.+?\)$`.
   - No bare URLs.
4. Content checks:
   - Every link must be one the user already cited inline, one the user provided, or one fetched via `WebFetch` returning 200. Otherwise remove it.
   - Flag duplicates.
   - Flag uninformative titles (`Docs`, `Link`, bare domains).
5. Report a table:

   | Issue | Line | Suggestion |
   |---|---|---|

6. If `--fix` is in `$ARGUMENTS`, apply structural fixes only (reorder, dedup, reformat). Never invent or remove URLs. Surface content issues separately.

## Output

End with one of:

- `OK — N references, all checks passed.`
- `Issues found — see table. Run with --fix for structural fixes; resolve content issues manually.`

## Forbidden

- Fabricating URLs to "fix" a missing-references issue.
- Editing content outside the `## References` section.
