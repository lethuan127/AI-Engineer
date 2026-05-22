---
name: add-curriculum-note
description: Use when creating a new numbered curriculum note (`X.Y. Title Case.md`) anywhere in the AI-Engineer repo. Encodes the filename convention, structural skeleton, voice, and the post-creation update to the track `README.md`. Invoke whenever the user says "add a note", "write a new note", or runs `/new-note`.
---

# Add Curriculum Note

This skill is the single source of truth for scaffolding a new numbered note in this repo. Both `.cursor/commands/new-note.md` and `.claude/commands/new-note.md` delegate here.

## When to use

- User asks: "Add a note about X to section Y."
- User runs `/new-note <track> <title>`.
- Curriculum-author subagent is dispatched.

## When NOT to use

- The note already exists (use `Edit` to modify it).
- The user wants a stub (one-line placeholder) — those use `lowercase-hyphenated.md`, no number, no References section. Create directly without this skill.
- The user wants a new track folder. Stop and confirm; this skill does not create tracks.

## Inputs

| Input | Source |
|---|---|
| Track folder | Argument or inferred from focused file's directory |
| Title | Argument or inferred from user's prompt |
| Optional subtitle | Argument |
| Optional companion-to / source-of cross-links | Argument or user prompt |

## Workflow

### Step 1 — Resolve target folder

If the user gave a track number only (e.g. `5`):

```bash
ls -d [0-9]*\ * | grep "^${TRACK_NUM}\. "
```

Pick the single match. If multiple match or none match, stop and ask.

### Step 2 — Compute next `X.Y`

```bash
ls "<track folder>/" | grep -E '^[0-9]+\.[0-9]+\. ' | sort -V | tail -n 1
```

Extract `X.Y` from that filename; new note is `X.(Y+1)`. If the folder has no numbered notes yet, start at `X.1`.

### Step 3 — Build the filename

`X.Y. Title Case.md`

- Title Case: capitalize each significant word.
- Real spaces, not hyphens or underscores.
- Em-dash `—` (U+2014) before optional subtitles: `X.Y. Title — Subtitle.md`.

Confirm the file does not already exist. If it does, stop and ask.

### Step 4 — Read the style reference

Read at least one existing note in the same track. Fall back to `7. AI System Architecture/7.1. Claude Platform Managed Agent.md` if the track has no notes yet. Match its structure (heading numbering, table density, callouts).

### Step 5 — Scaffold the file

Write this skeleton — fill the body in a subsequent edit, not in this scaffolding step:

```markdown
# X.Y. <Title>

> <Optional companion-to or source blockquote with cross-link>

<One-paragraph framing: what is this note about, what is the thesis, why does it matter architecturally.>

---

## 1. <First Section>

<Body. Tables for 3+-item comparisons. Code fences for shell/JSON/YAML/ASCII.
Inline `> Why it matters:` / `> Architectural takeaway:` / `> Lesson:` callouts
where the takeaway is not obvious.>

## 2. <Next Section>

---

## References

-
```

### Step 6 — Update the track `README.md`

Add a line to the track's README listing the new note:

```markdown
- [X.Y. <Title>](./X.Y.%20<URL-encoded Title>.md) — <one-sentence summary>
```

Place it in numeric order. Spaces in the URL must be `%20`.

### Step 7 — Report

Return:

1. Created file path.
2. README diff.
3. Reminder that the References section is intentionally empty — the user provides sources, or the curriculum-author subagent fetches and verifies them with `WebFetch`.

## Hard rules

- **No fabricated references.** The References bullet list starts empty (`- ` with nothing after it, or just blank). Never invent URLs.
- **No emojis.** The 🟢🟡🔴 build-tier glyphs are allowed only when used semantically as in `7.2`.
- **Do not create a track folder.** If the user wants `12. …`, stop and confirm.
- **Do not rename existing notes.** Renames break cross-link URLs across the repo.
- **Do not skip the README update.** A note that isn't linked from the track README is effectively invisible.

## Verifying

After creating, run the references hook manually as a smoke test:

```bash
bash .cursor/hooks/check-references.sh "<path to new file>"
```

It should output one of:

- `missing '## References' section` — bug in the skeleton, fix.
- `'## References' has no bullet links yet` — expected, this is fine for a new note.
