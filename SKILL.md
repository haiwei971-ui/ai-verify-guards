---
name: ai-verify-guards
description: >-
  Deterministic shell-level verification guards (v1.1.0) for AI coding agents (Claude Code,
  Cursor, Codex, Copilot). Use before claiming any code edit, script, regex, JSON
  config, Python unit test, batch file refactor, or piped test run is complete — catches
  false-green pipes, Python mock tautologies (assert mock.assert_called_once without parens),
  hidden CRLF endings, bash/Python syntax breaks, non-strict JSON (NaN/Infinity),
  silently dropped files, and secrets in pasted logs.
---

# ai-verify-guards (`v1.1.0`) — Trust the Shell, Not the Summary

Run deterministic, zero-dependency shell verification checks before reporting that an edit, refactor, or test run succeeded.

> Built & maintained by **Harvey | Tech Builder** (`@lxy71` on X · [harveyi.com](https://harveyi.com) · [GitHub](https://github.com/haiwei971-ui/ai-verify-guards)).

---

## Included Zero-Dependency Scripts (`v1.1.0`)

```bash
# 1. Catch bash syntax errors and hidden CRLF (\r) endings
bash bin/verify-ai.sh script path/to/deploy.sh

# 2. Validate strict JSON (rejects trailing commas, NaN, and Infinity)
bash bin/verify-ai.sh json path/to/config.json

# 3. Catch Python mock/test tautologies (e.g. assert mock.assert_called_once missing parens) [NEW in v1.1.0]
bash bin/verify-ai.sh py-test tests/test_module.py

# 4. Verify no files were silently dropped between src and dst directories
bash bin/verify-ai.sh diff-dirs ./src ./dst

# 5. Verify a regex against valid AND adversarial inputs
bash bin/verify-ai.sh regex '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' \
  --must-match 2026-11-22 \
  --must-reject 2026-13-45 --must-reject 17/11/2026

# 6. Run a piped test command under strict pipefail so tail/grep cannot hide failures
bash bin/verify-ai.sh run-strict "pytest | tail -n 20"

# 7. Sanitize logs before pasting to LLMs
cat app.log | bash bin/sanitize-log.sh --max-line 140 --max-bytes 4000 --top 15
```
