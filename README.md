# ai-verify-guards

[![CI](https://github.com/haiwei971-ui/ai-verify-guards/actions/workflows/ci.yml/badge.svg)](https://github.com/haiwei971-ui/ai-verify-guards/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-blue.svg)](#quick-start)
[![Follow on X](https://img.shields.io/badge/X-@lxy71-000000.svg?logo=x)](https://x.com/lxy71)

> **Trust the shell, not the summary.**  
> Lightweight, zero-dependency shell guards and hooks that catch silent failures from AI coding agents (**Claude Code**, **Cursor**, **Codex**) before you commit or review a single line.

Built and maintained by **Harvey (`@lxy71`)** — every check in this repo comes from a real silent failure caught in daily AI-assisted development.

---

## Why This Exists

AI coding agents rarely fail loudly. They fail silently and hand you a confident summary saying *"Done — all tests pass"*:

- `pytest | tail -n 20` exits `0` even when tests fail (missing `pipefail`).
- Batch refactors or copies silently drop files.
- Generated scripts sneak in CRLF (`\r`) endings or missing `fi` / syntax errors.
- Python's `json.loads()` accepts `NaN` / `Infinity` silently unless you pass `parse_constant`.
- Generated regexes match the **shape** (`2026-13-45`) instead of valid reality.
- Raw crash logs pasted into prompts leak secrets and burn 80% of your context window on duplicate noise.

---

## Included Tools

| Script | Purpose |
| :--- | :--- |
| `bin/verify-ai.sh` | Unified CLI to verify shell syntax/CRLF, strict JSON, directory syncs, adversarial regexes, and `pipefail`-enforced test pipelines |
| `bin/sanitize-log.sh` | 3-step shell pipeline to scrub secrets, deduplicate repeated errors, and cap tokens before pasting logs into any LLM |
| `hooks/claude-post-edit-verify.sh` | Drop-in Claude Code `PostToolUse` hook that auto-validates edited `.sh`, `.py`, and `.json` files |
| `tests/run_tests.sh` | End-to-end self-test suite proving every guard catches real failures (verified on GitHub Actions CI) |

---

## Quick Start

```bash
git clone https://github.com/haiwei971-ui/ai-verify-guards.git
cd ai-verify-guards
chmod +x bin/*.sh hooks/*.sh tests/*.sh
./tests/run_tests.sh
```

### Real Output Example

```text
$ ./bin/verify-ai.sh regex '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
    --must-match 2026-11-22 --must-reject 2026-13-45
[FAIL] Expected REJECT, but matched: '2026-13-45'

$ ./bin/verify-ai.sh run-strict "false | true"
[FAIL] Strict pipeline failed with exit code 1

$ ./bin/verify-ai.sh json bad_nan.json
[FAIL] Invalid strict JSON (bad_nan.json): Non-standard JSON constant not allowed: NaN
```

### 1. Run Verification Checks (`bin/verify-ai.sh`)

```bash
# Catch bash syntax errors and hidden CRLF (\r) endings
./bin/verify-ai.sh script path/to/deploy.sh

# Validate strict JSON (rejects trailing commas AND NaN/Infinity)
./bin/verify-ai.sh json config.json

# Verify no files were silently dropped between two directories
./bin/verify-ai.sh diff-dirs ./src ./dst

# Test a regex against valid AND adversarial inputs (like 2026-13-45)
./bin/verify-ai.sh regex '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' \
  --must-match 2026-11-22 \
  --must-reject 2026-13-45 --must-reject 17/11/2026

# Run a piped test command without letting the pipe hide a failure
./bin/verify-ai.sh run-strict "pytest | tail -n 20"
```

### 2. Sanitize Logs Before Pasting to an LLM (`bin/sanitize-log.sh`)

```bash
# Redact API keys/tokens, collapse duplicate lines with counts, and cap output to 4,000 bytes
cat app.log | ./bin/sanitize-log.sh

# Custom line width and byte budget
./bin/sanitize-log.sh --max-line 140 --max-bytes 4000 --top 15 app.log
```

### 3. Wire Into Claude Code (`hooks/claude-post-edit-verify.sh`)

Add to your `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/ai-verify-guards/hooks/claude-post-edit-verify.sh"
          }
        ]
      }
    ]
  }
}
```

Whenever Claude Code writes or edits a `.sh`, `.py`, or `.json` file, the hook runs syntax, CRLF, and strict JSON validation automatically.

---

## Contributing & Daily Receipts

- Caught a silent AI failure in the wild? See [CONTRIBUTING.md](CONTRIBUTING.md) or open an Issue.
- Daily tested shell receipts & AI coding guardrails: follow [@lxy71 on X](https://x.com/lxy71).

## License

MIT — fork it, wire it into your own hooks, and stop trusting summaries without receipts.
