#!/usr/bin/env bash
# End-to-end test suite for ai-verify-guards.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== Running ai-verify-guards self-tests ==="

# 1. Script check: catches CRLF and broken syntax, passes clean script
printf '#!/usr/bin/env bash\r\necho hi\r\n' > "$TMP/crlf.sh"
! "$ROOT/bin/verify-ai.sh" script "$TMP/crlf.sh" 2>/dev/null
printf '#!/usr/bin/env bash\nif true; then\n  echo missing_fi\n' > "$TMP/bad.sh"
! "$ROOT/bin/verify-ai.sh" script "$TMP/bad.sh" 2>/dev/null
printf '#!/usr/bin/env bash\necho clean\n' > "$TMP/good.sh"
"$ROOT/bin/verify-ai.sh" script "$TMP/good.sh"

# 2. Strict JSON check: rejects NaN and trailing comma, passes valid JSON
printf '{"timeout": NaN}\n' > "$TMP/nan.json"
! "$ROOT/bin/verify-ai.sh" json "$TMP/nan.json" 2>/dev/null
printf '{"timeout": 30,}\n' > "$TMP/comma.json"
! "$ROOT/bin/verify-ai.sh" json "$TMP/comma.json" 2>/dev/null
printf '{"timeout": 30}\n' > "$TMP/good.json"
"$ROOT/bin/verify-ai.sh" json "$TMP/good.json"

# 3. Directory diff check: catches missing file, passes synced dirs
mkdir -p "$TMP/src" "$TMP/dst"
touch "$TMP/src/a.txt" "$TMP/src/b.txt" "$TMP/dst/a.txt"
! "$ROOT/bin/verify-ai.sh" diff-dirs "$TMP/src" "$TMP/dst" 2>/dev/null
touch "$TMP/dst/b.txt"
"$ROOT/bin/verify-ai.sh" diff-dirs "$TMP/src" "$TMP/dst"

# 4. Regex check: catches naive date regex matching 2026-13-45, passes strict regex
! "$ROOT/bin/verify-ai.sh" regex '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
  --must-match 2026-11-22 --must-reject 2026-13-45 2>/dev/null
"$ROOT/bin/verify-ai.sh" regex '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' \
  --must-match 2026-11-22 --must-reject 2026-13-45 --must-reject 17/11/2026

# 5. Strict pipeline check: catches false-green `false | true`
! "$ROOT/bin/verify-ai.sh" run-strict "false | true" 2>/dev/null
"$ROOT/bin/verify-ai.sh" run-strict "true | true"

# 6. Log sanitizer check: redacts secrets and deduplicates lines
cat <<'EOF' > "$TMP/app.log"
ERROR auth failed with sk-live1234567890abcd
ERROR auth failed with sk-live1234567890abcd
WARN header Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig
EOF
OUT="$("$ROOT/bin/sanitize-log.sh" "$TMP/app.log")"
! grep -q "sk-live1234567890abcd" <<< "$OUT"
! grep -q "eyJhbGciOiJIUzI1NiJ9" <<< "$OUT"
grep -q "REDACTED_API_KEY" <<< "$OUT"
grep -q "REDACTED_BEARER" <<< "$OUT"

# 7. Claude PostToolUse hook check
echo "{\"tool_input\":{\"file_path\":\"$TMP/good.json\"}}" | "$ROOT/hooks/claude-post-edit-verify.sh"
! (echo "{\"tool_input\":{\"file_path\":\"$TMP/nan.json\"}}" | "$ROOT/hooks/claude-post-edit-verify.sh" 2>/dev/null)

echo "=== ALL 7 GUARD TEST SUITES PASSED ==="
