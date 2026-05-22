---
name: normalize-references
description: Use to validate, normalize, or repair the `## References` section of a curriculum note. Defines the canonical format, the checks, and the only-mutate-structure-never-content discipline. Invoke from the reference-validator subagent, from `/check-refs`, or whenever a References section looks off.
---

# Normalize References

The canonical format and validation procedure for the `## References` section that closes every substantive curriculum note in this repo.

## Canonical format

```markdown
## References

- [Anthropic — Managed Agents Overview](https://platform.claude.com/docs/en/managed-agents/overview)
- [MCP Specification](https://modelcontextprotocol.io/specification)
- [Cursor Rules — Documentation](https://cursor.com/docs/agent/rules)
```

Format rules:

| Rule | Detail |
|---|---|
| Heading | Exactly `## References` (level 2, plural, capital R) |
| Position | Last `##` heading in the file |
| Bullet style | `- ` (hyphen + single space), not `* ` |
| Link form | `[Title](URL)` only — no bare URLs |
| Title prefix | When the source has a clear publisher, prefer `Publisher — Page Title` (em-dash separator) |
| Annotations | None after the closing `)` |
| Blank lines | One blank line between heading and first bullet; no blank lines between bullets |
| Ordering | Order of citation in the body, or grouped logically — but never alphabetized blindly |
| Duplicates | None within the section |

## When to use

- Reference-validator subagent is dispatched.
- `/check-refs` slash command is invoked.
- User asks: "Check the references on this note", "normalize the references", "fix the references section".

## When NOT to use

- Stub notes (`lowercase-hyphenated.md`) — they are exempt from the References section requirement.
- README files — they list notes, not external references.
- Files outside the `[0-9]+\. .+/` track folders.

## Workflow

### Step 1 — Locate the section

```bash
grep -n '^## References' "<file>"
```

Expect exactly one match. If zero, the note is missing the section — report `MISSING`. If two or more, report `DUPLICATE_HEADING` and stop.

### Step 2 — Verify position

The line number of `## References` must be greater than the line number of every other `^## ` heading in the file.

```bash
last_h2=$(grep -E '^## ' "<file>" | tail -n 1)
[[ "$last_h2" == "## References" ]] || echo "NOT_LAST"
```

### Step 3 — Validate each bullet

For every non-blank line under the heading until EOF or next `##`:

```regex
^- \[[^\]]+\]\([^)]+\)$
```

Anything that does not match is an `INVALID_FORMAT` issue. Common offenders:

- Bare URL: `- https://example.com`
- Annotation: `- [Foo](https://foo) — best for X`
- Bullet-star: `* [Foo](https://foo)`
- Missing closing paren / bracket.

### Step 4 — Content checks (the dangerous step)

For each link's URL:

1. Confirm it has actually been cited in the body OR was provided by the user. If not, the link is suspicious.
2. **Use `WebFetch` to confirm HTTP 200** (or a known documented exception). If you cannot reach it from the current environment, mark `UNVERIFIED` — do not silently keep or drop it.

For each link's title:

3. Reject uninformative titles: `Docs`, `Link`, `Home`, `Read more`, a bare domain like `example.com`.
4. Prefer `Publisher — Page Title` form when the publisher is identifiable.

### Step 5 — Decide what to mutate

| Mode | Mutation allowed |
|---|---|
| `--fix` / `repair` | Structural only — reorder, dedup, normalize bullet style, re-format link form. **Never invent or drop URLs.** |
| Default / `report` | None. Output a report; user decides. |

The single hardest rule: **if you cannot defend a URL (cited inline, provided by user, or fetched 200), surface it; do not "fix" by guessing a replacement.**

### Step 6 — Output

Two paragraphs max:

1. A markdown table of issues.
2. A summary line: `OK — N references, all checks passed.` or `Issues — N structural, M content; ran fixes for structural only.`

## Forbidden

- **Fabricating URLs.** Even if a link 404s and you "know" what the right one is, surface the issue — do not substitute.
- **Removing a valid URL** because you don't recognize it.
- **Editing the note body** to add inline citations during normalization. That is the curriculum-author's job, not yours.
- **Alphabetizing** unless the existing section is alphabetized.

## Example report

```markdown
### 5. AI Agents & Tool Use/5.1. Programmatic Tool Calling.md

| Severity | Line | Issue | Suggestion |
|---|---|---|---|
| ERROR | 207 | Bare URL: https://docs.anthropic.com/...  | Wrap as `[Anthropic — Tool Use Overview](https://docs.anthropic.com/...)` |
| WARN  | 211 | Title is uninformative ("Docs") | Use page H1 — `MCP Specification` |
| WARN  | 213 | Duplicate URL (also on line 209) | Remove one |
| INFO  | —   | Section verified as last `##` heading | — |

OK — 6 references; 2 structural issues fixed, 1 content issue surfaced for user.
```
