#!/usr/bin/env bash
# claude-post-edit-verify.sh — Drop-in Claude Code PostToolUse hook.
# Reads hook JSON payload from stdin, extracts tool_input.file_path, and
# verifies .sh / .py / .json files automatically.

set -euo pipefail

PAYLOAD="$(cat)"
FILE_PATH="$(python3 -c '
import json, sys
try:
    data = json.loads(sys.argv[1])
    ti = data.get("tool_input") or {}
    print(ti.get("file_path") or ti.get("path") or "")
except Exception:
    print("")
' "$PAYLOAD")"

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFIER="${SCRIPT_DIR}/../bin/verify-ai.sh"

case "$FILE_PATH" in
  *.sh)
    "$VERIFIER" script "$FILE_PATH"
    ;;
  *.json)
    "$VERIFIER" json "$FILE_PATH"
    ;;
  *.py)
    python3 -m py_compile "$FILE_PATH"
    echo "[PASS] Python syntax valid: $FILE_PATH"
    ;;
  *)
    exit 0
    ;;
esac
