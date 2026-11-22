#!/usr/bin/env bash
# sanitize-log.sh — 3-step shell cleanup before pasting production logs into an LLM:
#   1. Redact common secrets (API keys, GitHub/Slack/AWS tokens, Bearer auth)
#   2. Collapse duplicate lines into frequency counts
#   3. Cap line width and total byte budget

set -euo pipefail

MAX_LINE=140
MAX_BYTES=4000
TOP_N=20
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-line)  MAX_LINE="$2"; shift 2 ;;
    --max-bytes) MAX_BYTES="$2"; shift 2 ;;
    --top)       TOP_N="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: sanitize-log.sh [--max-line 140] [--max-bytes 4000] [--top 20] [file]"
      exit 0
      ;;
    *)
      INPUT_FILE="$1"; shift ;;
  esac
done

read_input() {
  if [[ -n "$INPUT_FILE" ]]; then
    cat "$INPUT_FILE"
  else
    cat
  fi
}

read_input \
  | sed -E \
      -e 's/(sk-[A-Za-z0-9_-]{8,})/[REDACTED_API_KEY]/g' \
      -e 's/(ghp_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]{10,})/[REDACTED_GH_TOKEN]/g' \
      -e 's/(xox[baprs]-[A-Za-z0-9-]{10,})/[REDACTED_SLACK_TOKEN]/g' \
      -e 's/(AKIA[0-9A-Z]{16})/[REDACTED_AWS_KEY]/g' \
      -e 's/(Bearer[[:space:]]+)[A-Za-z0-9._-]+/\1[REDACTED_BEARER]/g' \
  | cut -c1-"$MAX_LINE" \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -n "$TOP_N" \
  | head -c "$MAX_BYTES"
printf '\n'
