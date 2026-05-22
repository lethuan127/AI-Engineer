---
description: Validate the References section of a curriculum note.
---

# /check-refs

Audit and (optionally) repair the `## References` section of the current note, or a path given as argument.

> `/check-refs` — operate on the currently focused file
> `/check-refs "7. AI System Architecture/7.1. Claude Platform Managed Agent.md"` — operate on a path

## Steps

1. **Resolve the target file.** If no argument, use the currently focused markdown file. Refuse politely if the file is not a numbered note in a track folder.
2. **Read [`.claude/skills/normalize-references/SKILL.md`](../../.claude/skills/normalize-references/SKILL.md)** and follow it as the source of truth for formatting and validation.
3. **Run the structural checks:**
   - Exactly one `## References` heading.
   - It is the last `##` heading in the file.
   - Every line under it is either blank or matches `^- \[.+?\]\(.+?\)$`.
   - No bare URLs.
4. **Run the content checks:**
   - For each link, verify it is a URL the user already cited inline in the note OR one the user provided in this session OR one you fetch and confirm resolves (HTTP 200). Do not add or keep references you cannot defend.
   - Flag duplicates.
   - Flag titles that are uninformative (e.g., "Docs", "Link", a bare domain).
5. **Report.** Produce a short table:

   | Issue | Line | Suggestion |
   |---|---|---|

6. **If `--fix` flag is present in the command**, apply fixes for structural issues (reordering, dedup, format-only changes). Never invent or remove URLs in `--fix` mode — only re-format. Surface content issues separately for the user to resolve.

## Output

End with one of:

- `OK — N references, all checks passed.`
- `Issues found — see table above. Run with --fix for structural fixes; resolve content issues manually.`

## Forbidden

- Fabricating URLs to "fix" a missing-references issue. If a section is empty, leave it empty and ask the user for sources.
- Editing any content outside the `## References` section in this command.
