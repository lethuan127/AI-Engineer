#!/usr/bin/env bash
# check-references.sh — Warn if a numbered curriculum note is missing the
# trailing `## References` section, or if it appears empty.
#
# Wired from .cursor/hooks.json (afterFileEdit) and .claude/settings.json
# (PostToolUse on Edit|Write). Both vendors now send a JSON payload on stdin
# (Cursor: `{ "file_path": "...", "edits": [...] }`; Claude Code:
# `{ "tool_input": { "file_path": "..." }, ... }`). We support either shape,
# and also accept a path as $1 for manual smoke-tests.
#
# Always exits 0. Output is advisory; never blocks an edit. The point is to
# surface a single line of feedback in the agent transcript.

set -u

# Hooks must fail soft. Tolerate missing jq.
# Precedence: positional arg (manual smoke-test) > stdin JSON (real hook).
file="${1:-}"
if [ -z "$file" ] && [ ! -t 0 ]; then
  payload=$(cat || true)
  if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
    file=$(printf '%s' "$payload" | jq -r '
      .file_path
      // .tool_input.file_path
      // .tool_response.filePath
      // empty
    ')
  fi
fi

if [ -z "$file" ] || [ ! -f "$file" ]; then
  exit 0
fi

# Only check numbered notes in track folders, e.g. "7. .../7.1. Foo.md".
base="$(basename "$file")"
if [[ ! "$base" =~ ^[0-9]+\.[0-9]+\.\  ]]; then
  exit 0
fi

# Stub notes (lowercase-hyphenated.md) are exempt — they don't start with a digit.
if [[ "$base" =~ ^[a-z] ]]; then
  exit 0
fi

ref_count=$(grep -c -E '^## References[[:space:]]*$' "$file" || true)

if [[ "$ref_count" -eq 0 ]]; then
  echo "[hook] $file: missing '## References' section (see AGENTS.md §5)."
  exit 0
fi

if [[ "$ref_count" -gt 1 ]]; then
  echo "[hook] $file: multiple '## References' headings ($ref_count); should be exactly one."
  exit 0
fi

last_h2=$(grep -E '^## ' "$file" | tail -n 1)
if [[ "$last_h2" != "## References" ]]; then
  echo "[hook] $file: '## References' is not the last top-level section (found: '$last_h2')."
  exit 0
fi

ref_body=$(awk '/^## References[[:space:]]*$/{flag=1; next} /^## /{flag=0} flag' "$file")
if ! grep -q -E '^- \[.+\]\(.+\)' <<<"$ref_body"; then
  echo "[hook] $file: '## References' has no bullet links yet."
fi

exit 0
