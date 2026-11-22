#!/usr/bin/env bash
# verify-ai.sh — Shell-level verification guards for AI coding agent output.
# Trust the shell, not the summary.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: verify-ai.sh <command> [args...]

Commands:
  script <file>                       Check shell syntax (bash -n) and hidden CRLF (\r) endings
  json <file>                         Validate strict JSON (rejects syntax errors, NaN, Infinity)
  diff-dirs <src_dir> <dst_dir>       List files present in src_dir but missing from dst_dir
  regex <pattern> [flags]             Test regex with --must-match <str> and --must-reject <str>
  run-strict <shell_command>          Run a command under `set -o pipefail` so pipes cannot mask failures
EOF
}

cmd_script() {
  local target="${1:-}"
  if [[ -z "$target" || ! -f "$target" ]]; then
    echo "[FAIL] File not found: ${target:-<missing>}" >&2
    return 2
  fi

  local failed=0
  if LC_ALL=C grep -q $'\r' "$target"; then
    echo "[FAIL] Hidden CRLF (\\r) line endings detected in: $target" >&2
    echo "       Fix: tr -d '\\r' < \"$target\" > \"${target}.clean\" && mv \"${target}.clean\" \"$target\"" >&2
    failed=1
  fi

  if ! bash -n "$target"; then
    echo "[FAIL] Bash syntax check failed for: $target" >&2
    failed=1
  fi

  if [[ "$failed" -ne 0 ]]; then
    return 1
  fi
  echo "[PASS] Script syntax & line endings clean: $target"
}

cmd_json() {
  local target="${1:-}"
  if [[ -z "$target" || ! -f "$target" ]]; then
    echo "[FAIL] JSON file not found: ${target:-<missing>}" >&2
    return 2
  fi

  python3 - "$target" <<'PY'
import json, sys

path = sys.argv[1]
def reject_constant(val):
    raise ValueError(f"Non-standard JSON constant not allowed: {val}")

try:
    with open(path, "r", encoding="utf-8") as fh:
        json.load(fh, parse_constant=reject_constant)
except Exception as exc:
    print(f"[FAIL] Invalid strict JSON ({path}): {exc}", file=sys.stderr)
    sys.exit(1)

print(f"[PASS] Strict JSON valid: {path}")
PY
}

cmd_diff_dirs() {
  local src="${1:-}"
  local dst="${2:-}"
  if [[ ! -d "$src" || ! -d "$dst" ]]; then
    echo "[FAIL] Both arguments must be existing directories: src='$src' dst='$dst'" >&2
    return 2
  fi

  local missing
  missing="$(comm -23 <(cd "$src" && find . -type f | sort) <(cd "$dst" && find . -type f | sort))"
  if [[ -n "$missing" ]]; then
    echo "[FAIL] Files present in '$src' but missing from '$dst':" >&2
    printf '%s\n' "$missing" >&2
    return 1
  fi

  echo "[PASS] Every file in '$src' exists in '$dst'"
}

cmd_regex() {
  local pattern="${1:-}"
  if [[ -z "$pattern" ]]; then
    echo "[FAIL] Missing regex pattern" >&2
    return 2
  fi
  shift

  local -a must_match=()
  local -a must_reject=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --must-match)
        must_match+=("${2:-}")
        shift 2
        ;;
      --must-reject)
        must_reject+=("${2:-}")
        shift 2
        ;;
      *)
        echo "[FAIL] Unknown flag: $1" >&2
        return 2
        ;;
    esac
  done

  python3 - "$pattern" "${#must_match[@]}" "${must_match[@]}" "${must_reject[@]}" <<'PY'
import re, sys

pattern = sys.argv[1]
n_match = int(sys.argv[2])
must_match = sys.argv[3 : 3 + n_match]
must_reject = sys.argv[3 + n_match :]

try:
    rx = re.compile(pattern)
except re.error as exc:
    print(f"[FAIL] Invalid regex: {exc}", file=sys.stderr)
    sys.exit(2)

errors = []
for s in must_match:
    if rx.search(s) is None:
        errors.append(f"Expected MATCH, got none: {s!r}")
for s in must_reject:
    if rx.search(s) is not None:
        errors.append(f"Expected REJECT, but matched: {s!r}")

if errors:
    for err in errors:
        print(f"[FAIL] {err}", file=sys.stderr)
    sys.exit(1)

print(f"[PASS] Regex verified ({len(must_match)} matched, {len(must_reject)} rejected)")
PY
}

cmd_run_strict() {
  local raw_cmd="${1:-}"
  if [[ -z "$raw_cmd" ]]; then
    echo "[FAIL] Missing shell command to execute" >&2
    return 2
  fi

  if bash -o pipefail -c "$raw_cmd"; then
    echo "[PASS] Strict pipeline exited 0"
  else
    local code=$?
    echo "[FAIL] Strict pipeline failed with exit code $code" >&2
    return "$code"
  fi
}

main() {
  local sub="${1:-}"
  if [[ -z "$sub" || "$sub" == "-h" || "$sub" == "--help" ]]; then
    usage
    exit 0
  fi
  shift

  case "$sub" in
    script)     cmd_script "$@" ;;
    json)       cmd_json "$@" ;;
    diff-dirs)  cmd_diff_dirs "$@" ;;
    regex)      cmd_regex "$@" ;;
    run-strict) cmd_run_strict "$@" ;;
    *)
      echo "[FAIL] Unknown command: $sub" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
