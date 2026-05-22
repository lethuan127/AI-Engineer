# AGENTS.md — Agent Working Agreement for AI-Engineer

This file is the **primary instruction file** for any AI coding agent (Cursor, Claude Code, Codex CLI, Copilot CLI, etc.) operating in this repository. It is the agent-facing equivalent of `CONTRIBUTING.md`.

If you are a human, this file also tells you what the agents have been told.

---

## 1. What This Repository Is

A personal AI Engineering curriculum, structured as numbered top-level folders (`0. Software Engineering`, `1. AI & ML Fundamentals`, …, `11. Harness Engineering`). Each folder is a **track** with its own `README.md` and one or more numbered notes in the form `X.Y. Title Case.md`.

The dominant artifact is the **architectural note** — a dense, opinionated markdown file (~150–250 lines) that explains a primitive, pattern, or tradeoff. See `7.1. Claude Platform Managed Agent.md` and `7.2. Self-Implemented Agent Harness — Components.md` as the style reference.

This is **not** a code repo. There is no application to run, no test suite, no build. Almost every change is markdown.

## 2. House Style for Notes

When creating or editing a curriculum note, follow these rules:

1. **Heading levels.** `#` for the title (line 1). `##` for top-level sections, numbered as `## 1. …`, `## 2. …` etc. `###` for subsections. Do not skip levels.
2. **Opening.** Line 1 is the `# X.Y. Title` heading. Line 3 may be a `> Source: …` or `> Companion to …` blockquote with cross-links.
3. **Tables over prose** when comparing 3+ items along the same axes. Use markdown pipe tables.
4. **Code fences** for shell, JSON, YAML, ASCII diagrams. Always specify a language (` ```text` for ASCII art is fine).
5. **Opinionated callouts.** Inline `> Why it matters:` / `> Architectural takeaway:` / `> Lesson:` blockquotes are encouraged where the takeaway is not obvious.
6. **Ending.** Every substantive note ends with a `## References` section containing bullet-link items: `- [Title](URL)`. No bare URLs.
7. **No emoji decoration.** Exception: the tier convention 🟢 MVP / 🟡 Production / 🔴 Managed-grade may be used semantically (see `7.2`).
8. **No marketing language.** No "powerful", "seamless", "robust", "industry-leading". Architectural notes should sound like a senior engineer talking to another senior engineer.
9. **Cross-link aggressively** with relative paths: `[7.1. Claude Platform Managed Agent](./7.1.%20Claude%20Platform%20Managed%20Agent.md)`. Spaces in filenames must be URL-encoded as `%20`.

## 3. File Naming

| Kind | Pattern | Example |
|---|---|---|
| Track folder | `N. Title Case` | `5. AI Agents & Tool Use` |
| Numbered note | `X.Y. Title Case.md` | `7.1. Claude Platform Managed Agent.md` |
| Stub / WIP note | `lowercase-hyphenated.md` | `prompt-caching.md` |
| Track README | `README.md` | (one per track folder) |

Use real spaces (not underscores/hyphens) for numbered notes. Use em-dash `—` (U+2014) when joining a title and a subtitle: `7.2. Self-Implemented Agent Harness — Components.md`.

## 4. Working Agreement

**Allowed without asking:**

- Edit existing notes to improve clarity, add references, fix typos, refactor headings.
- Create new numbered notes inside an existing track when the user requests new content.
- Run read-only shell commands (`ls`, `git status`, `git diff`, `git log`).

**Confirm with the user first:**

- Creating a new top-level track folder (`12. …`).
- Renaming or moving existing notes (changes URLs in cross-links).
- Mass refactors across multiple notes.
- Deleting any file.
- Any `git` write operation (`git add`, `commit`, `push`, `reset`, etc.).

**Forbidden:**

- Adding LLM-generated link-bait references that you have not actually verified resolve. Every URL in a References section must be one the user already cited or one you fetched and confirmed exists.
- Decorating notes with emojis outside the 🟢🟡🔴 tier convention.
- Editing files outside the curriculum tree (e.g., `.git/`, OS files) without an explicit instruction.

## 5. References Section Format

Every substantive note ends with this exact structure:

```markdown
## References

- [Anthropic — Managed Agents Overview](https://platform.claude.com/docs/en/managed-agents/overview)
- [MCP Specification](https://modelcontextprotocol.io/specification)
```

Rules:

- Section heading is exactly `## References` (plural, capital R).
- One bullet per item, hyphen-bullet `- `, then `[Title](URL)`.
- Title should be informative — prefer `Anthropic — Managed Agents Overview` over `Managed Agents Overview`.
- No annotations after the link (no parenthetical descriptions). If the reference needs explanation, cite it inline in the body instead.

## 6. Linked Tooling

This repo configures both Cursor and Claude Code:

- **`.cursor/rules/`** — file-scoped rules (markdown style, references enforcement, naming).
- **`.cursor/commands/`** — slash commands (`/new-note`, `/check-refs`).
- **`.cursor/hooks.json`** — post-edit hook for references validation.
- **`.cursor/mcp.json`** — pins `context7` MCP for doc lookups.
- **`.claude/settings.json`** — Claude Code project settings.
- **`.claude/commands/`** — same slash commands.
- **`.claude/agents/`** — subagents (`curriculum-author`, `reference-validator`).
- **`.claude/skills/`** — shared skills (`add-curriculum-note`, `normalize-references`).
- **`.claude/hooks/`** — same references-validator hook.

`11. Harness Engineering/` documents what each of these does and why.

## 7. Mental Model

When in doubt, optimize for a future reader who is a senior engineer learning AI engineering on their own. The voice is:

- **Direct.** State the claim, then justify it.
- **Architectural.** Talk about primitives, boundaries, tradeoffs — not features.
- **Vendor-neutral by default.** Vendor specifics belong in tables or call-outs, not in section headings.
- **YAGNI-pruned.** Cut anything you cannot defend as load-bearing.

If a note would be better as a section inside an existing note, prefer that. New notes are earned, not free.
