# ai-verify-guards

> **Trust the shell, not the summary.**  
> Lightweight, zero-dependency shell guards and hooks that catch silent failures from AI coding agents (Claude Code, Cursor, Codex) before you commit or review a single line.

Built and maintained by **Harvey (`@lxy71`)** — every check in this repo comes from a real silent failure caught in daily AI-assisted development.

---

## Why This Exists

AI coding agents rarely fail loudly. They fail silently and hand you a confident summary saying *"Done — all tests pass"*:

- `pytest | tail -n 20` exits `0` even when tests fail (missing `pipefail`).
- Batch refactors or copies silently drop files.
- Generated scripts sneak in CRLF (`\r`) endings or missing `fi` / syntax errors.
- JSON configs silently break or accept invalid `NaN` / `Infinity` tokens.
- Generated regexes match the **shape** (`2026-13-45`) instead of valid reality.
- Raw crash logs pasted into prompts leak secrets and burn 80% of the context window on duplicate noise.

---

## Included Tools

| Script | Purpose |
| :--- | :--- |
| `bin/verify-ai.sh` | Unified CLI to verify scripts, strict JSON, directory syncs, adversarial regexes, and unmasked piped test runs |
| `bin/sanitize-log.sh` | 3-step shell pipeline to scrub secrets, deduplicate repeated errors, and cap tokens before pasting logs into any LLM |
| `hooks/claude-post-edit-verify.sh` | Drop-in Claude Code `PostToolUse` hook that auto-validates edited `.sh`, `.py`, and `.json` files |
| `tests/run_tests.sh` | End-to-end self-test suite proving every guard catches real failures |

---

## Quick Start

```bash
chmod +x bin/verify-ai.sh bin/sanitize-log.sh hooks/claude-post-edit-verify.sh tests/run_tests.sh
./tests/run_tests.sh
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

## License

MIT — fork it, wire it into your own hooks, and stop trusting summaries without receipts.
