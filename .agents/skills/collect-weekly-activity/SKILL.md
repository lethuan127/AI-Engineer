---
name: collect-weekly-activity
description: Collect per-week git commits + Linear tickets across all 100x/Vireox repos into the weekly activity log (CV/vireox(100x) work tracking/weekly/). Use when the user says "collect weekly activity", "update the weekly log", "pull my activity from git and Linear", or "catch up the weekly files up to now". This is the collector that FEEDS activity-to-resume — run it first, then distill.
---

# Collect Weekly Activity

Produces the per-week files under `CV/vireox(100x) work tracking/weekly/` that
[[activity-to-resume]] later distills. Each week = one `week-of-YYYY-MM-DD.md` (Monday
date), holding that week's git commits (with bodies) grouped by repo, plus Linear tickets
grouped by status. `INDEX.md` is the table of contents.

> Weeks run **Monday → Sunday**. The filename date is the Monday.

## Step 0 — Find the gap

Read `weekly/INDEX.md`. The last table row is the last collected week. Collect every full
(and current partial) week from there up to today. Today's date is in the session context.

## Step 1 — Discover repos + author identity

```bash
find /Users/thuanle/Documents100x -maxdepth 3 -type d -name ".git" 2>/dev/null | sed 's#/.git##'
```

- **Author filter (Thuan):** `--author="thuan@100xteam.ai" --author="thuan.le@rennlabs.com"`
  (multiple `--author` = OR). Confirm with `git log --pretty='%an <%ae>' | sort -u` if unsure.
- **Exclude non-work / vendored repos:** `wedding`, `AI-Engineer`, `mastra`, `agno`,
  `litellm`, `deepagents`, `Codex-agent-sdk-python`, `LibreCodeInterpreter`.

## Step 2 — Dump commits to files (do NOT read 200+ commits into context)

For each work repo, write a dump file to the scratchpad. Use `--all` (commits may live on
feature branches), `--date=short`, and a parseable delimiter:

```bash
git -C "$repo" log --all \
  --author="thuan@100xteam.ai" --author="thuan.le@rennlabs.com" \
  --since="<first-monday> 00:00" --until="<today+1> 00:00" \
  --date=short --pretty=format:'===COMMIT===%n%ad|%s%n%b' > "$SP/dump_$name.md"
```

Then get a date+subject overview (`grep -E '^2026-[0-9]{2}-[0-9]{2}\|'`) and bucket line
ranges into weeks yourself. This is the plan for the write step.

## Step 3 — Linear tickets

Load `mcp__claude_ai_Linear__list_issues`, then:

```
list_issues(assignee="me", updatedAt="<first-monday>", orderBy="updatedAt", limit=150)
```

The result is large — it saves to a tool-results file. Parse with **python3**, bucket each
ticket into a week: put it in **Completed** for the week its `completedAt` falls in; otherwise
**In progress/opened** for the week its `startedAt` or `updatedAt` falls in. De-dupe: a ticket
completed in an earlier week must not reappear as "active" later. Cross-reference AIP/CENG IDs
against that week's commit subjects to confirm placement.

## Step 4 — Write the files

Copy the format of the most recent existing weekly file exactly. Skeleton:

```markdown
# Week of <D Month YYYY>

> **Range:** Mon <D Mon> – Sun <D Mon YYYY>  
> **Activity:** <N> commits across <R> repos · <T> Linear tickets

| Repository | Commits | Domain |
|---|---|---|
| `100x-agent-runtime` | 42 | Deep Agents runtime |
...

---

## 🎫 Linear tickets
**Completed (N)** / **In progress / opened (N)** / **Canceled (N)**
- ✅ / 🔵 / ⚪ / 📋 / ❌ **AIP-xxx** — Title _(Priority[, `Label`])_

---

## `repo` — <domain> (N)
- `YYYY-MM-DD` <subject>
  > body line, two-space-indented blockquote, paragraph breaks kept as `  >`
```

Rules: commits **ascending** by date; repo sections ordered by count **descending**; strip
`Co-Authored-By:` trailers and squash `-----` separators; truncate any single body to ~12
lines ending `…`; skip bodies that only repeat the subject. Status emoji: ✅ done, 🔵 in
progress/review, ⚪ todo, 📋 backlog, ❌ canceled.

**Known domain labels:** `100x-agent-runtime`=Deep Agents runtime · `100x-agent-hub`=Backend
agent platform · `100x-web-application`=Web app API · `100x-ai-plugins`=Plugin marketplace /
SDD harness · `vireox-runtime-plugin`=Vireox runtime plugin · `100x-managed-plugins`=Managed
customer plugins.

> For a heavy backlog (many weeks / 50+ commits/week), fan out one subagent per week (they're
> independent). Give each the date range, dump-file paths, the format reference file, and the
> pre-built Linear section for that week; have it report the per-repo counts it extracted so
> you can verify against your Step-2 plan.

## Step 5 — Update INDEX.md

Append a row per new week `| <D Month YYYY> | <commits> | <repos> | <linear> | [file](./file) |`
and bump the "N active weeks" count in the intro line.

## Environment gotchas (this machine)

- **`git` lives outside the standard bins** — never `export PATH=...` to a hardcoded list or
  git vanishes. Leave PATH alone.
- Inside multi-line/compound bash, `head`/`wc`/`tr` are often **not found** and `grep` is a
  shell-function wrapper (ugrep). **Use `python3`** for counting/slicing/parsing instead.
- **zsh does not word-split** unquoted `$var` — `set -- $w` keeps `$w` as one word. Use
  `${=w}` to force splitting, or arrays, or `${var%%:*}` / `${var##*:}` parameter expansion.
- Iterate repos with `find ... | while read -r repo`, not a bare `for x in $VAR`.

## Quality bar

- [ ] Every full/partial week since the last INDEX row is present.
- [ ] Per-repo commit counts in each file match the git-log totals.
- [ ] Linear tickets bucketed with no completed-ticket duplicated as "active" in a later week.
- [ ] INDEX row + active-week count updated.
- [ ] Nothing committed to git unless the user asks.
