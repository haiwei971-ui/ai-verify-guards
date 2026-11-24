# ai-verify-guards

[![Version](https://img.shields.io/badge/Version-v1.1.0-38bdf8.svg)](CHANGELOG.md)
[![CI](https://github.com/haiwei971-ui/ai-verify-guards/actions/workflows/ci.yml/badge.svg)](https://github.com/haiwei971-ui/ai-verify-guards/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-blue.svg)](#quick-start)
[![Follow on X](https://img.shields.io/badge/X-@lxy71-000000.svg?logo=x)](https://x.com/lxy71)

> **Trust the shell, not the summary.**  
> Lightweight, zero-dependency shell guards and hooks that catch silent failures from AI coding agents (**Claude Code**, **Cursor**, **Codex**) before you commit or review a single line.

Built and maintained by **Harvey (`@lxy71` · [harveyi.com](https://harveyi.com))** — every check in this repo comes from a real silent failure caught in daily AI-assisted development.

---

## Why This Exists

AI coding agents rarely fail loudly. They fail silently and hand you a confident summary saying *"Done — all tests pass"*:

- `pytest | tail -n 20` exits `0` even when tests fail (missing `pipefail`).
- `assert mock_send.assert_called_once` (missing `()`) evaluates a truthy bound method and passes on every CI run even when `mock_send` was never called (**new in `v1.1.0`**).
- Batch refactors or copies silently drop files.
- Generated scripts sneak in CRLF (`\r`) endings or missing `fi` / syntax errors.
- Python's `json.loads()` accepts `NaN` / `Infinity` silently unless you pass `parse_constant`.
- Generated regexes match the **shape** (`2026-13-45`) instead of valid reality.
- Raw crash logs pasted into prompts leak secrets and burn 80% of your context window on duplicate noise.

---

## Included Tools (`v1.1.0`)

| Script | Purpose |
| :--- | :--- |
| `bin/verify-ai.sh` | Unified CLI to verify shell syntax/CRLF, strict JSON, Python mock/test tautologies (`py-test`), directory syncs, adversarial regexes, and `pipefail`-enforced test pipelines |
| `bin/sanitize-log.sh` | 3-step shell pipeline to scrub secrets, deduplicate repeated errors, and cap tokens before pasting logs into any LLM |
| `hooks/claude-post-edit-verify.sh` | Drop-in Claude Code `PostToolUse` hook that auto-validates edited `.sh`, `.py`, and `.json` files |
| `tests/run_tests.sh` | 8 end-to-end self-test suites proving every guard catches real failures (verified on GitHub Actions CI) |

---

## Quick Start

```bash
git clone https://github.com/haiwei971-ui/ai-verify-guards.git
cd ai-verify-guards
chmod +x bin/*.sh hooks/*.sh tests/*.sh
./tests/run_tests.sh
```

### 1. Run Verification Checks (`bin/verify-ai.sh`)

```bash
# Catch bash syntax errors and hidden CRLF (\r) endings
./bin/verify-ai.sh script path/to/deploy.sh

# Validate strict JSON (rejects trailing commas AND NaN/Infinity)
./bin/verify-ai.sh json config.json

# Catch Python test tautologies (e.g. assert mock_fn.assert_called_once missing parens) [NEW in v1.1.0]
./bin/verify-ai.sh py-test tests/test_billing.py

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
cat app.log | ./bin/sanitize-log.sh --max-line 140 --max-bytes 4000 --top 15
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

---

## Companion Open-Source Tools & Agent Skills by Harvey (`@lxy71`)

- **[ai-diff-audit (`v1.0.0`)](https://github.com/haiwei971-ui/ai-diff-audit)** — Read-only Git diff auditor that flags skipped tests (`@pytest.mark.skip`, `it.skip`), deleted assertions, `except: pass`, `|| true`, and out-of-scope edits before commit or PR.
- **[ai-signal-radar (`v1.0.0`)](https://github.com/haiwei971-ui/ai-signal-radar)** — Self-hosted 24/7 AI Opportunity, Bounty, Lead & Deal Radar with SQLite deduplication, multi-LLM scoring (OpenAI/Ollama/Claude/Gemini), dark Web UI, and 5 webhook channels.
- **[Agensi Verified Agent Skills Hub](https://www.agensi.io/creators/harvey-liu)** — Install `AI Verify Guards`, `AI Diff Audit`, and `Test Integrity Guard Pro` directly into Claude Code, Cursor, and 20+ agents.
- **[harveyi.com](https://harveyi.com)** — Interactive terminal receipts & copy-paste guard snippets.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## License

MIT — see [LICENSE](LICENSE).
