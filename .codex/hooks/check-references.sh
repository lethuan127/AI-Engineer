#!/usr/bin/env bash
# Claude Code wrapper around the shared references-section check.
#
# Both Cursor and Claude Code now send hook payloads as JSON on stdin. The
# shared script in `.cursor/hooks/check-references.sh` already accepts both
# shapes (`.file_path` for Cursor, `.tool_input.file_path` for Claude Code)
# so this wrapper just forwards stdin and lives in `.claude/` for tidiness.
exec bash "$(dirname "$0")/../../.cursor/hooks/check-references.sh" "$@"
