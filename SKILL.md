---
name: ai-verify-guards
description: >-
  Deterministic shell-level verification guards for AI coding agents (Claude Code,
  Cursor, Codex, Copilot). Use before claiming any code edit, script, regex, JSON
  config, batch file refactor, or piped test run is complete — catches false-green
  pipes, hidden CRLF endings, bash/Python syntax breaks, non-strict JSON (NaN/Infinity),
  silently dropped files, and secrets in pasted logs.
---

# ai-verify-guards — Trust the Shell, Not the Summary

Run deterministic, zero-dependency shell verification checks before reporting that an edit, refactor, or test run succeeded.

> Built & maintained by **Harvey | Tech Builder** (`@lxy71` on X · [harveyi.com](https://harveyi.com) · [GitHub](https://github.com/haiwei971-ui/ai-verify-guards)).

---

## When to Run This Skill

Always run the relevant check **before** telling the user `"Done"` or `"All tests pass"`:

1. **After running any piped test or build command** (`pytest | tail`, `npm test | head`, etc.) — verify under `set -o pipefail`.
2. **After writing or editing a `.sh` / `.bash` script** — verify syntax (`bash -n`) and ensure zero hidden CRLF (`\r`) line endings.
3. **After writing or editing a `.json` file** — verify strict RFC 8259 JSON (rejecting trailing commas AND Python's silent `NaN` / `Infinity`).
4. **After batch file copies, moves, or directory refactors** — verify zero files were silently dropped.
5. **After generating any regex or validator** — verify against at least 2 adversarial inputs (e.g., `2026-13-45` for date regexes).
6. **Before summarizing or pasting raw server logs into context** — scrub API keys, Bearer tokens, and repeated noise first.
7. **After fixing a failing test** — run `git diff --name-only` to verify `tests/` assertions were not silently rewritten unless explicitly requested.

---

## Included Zero-Dependency Scripts

All scripts use only standard Bash + Python 3 stdlib (macOS & Linux):

### 1. Unified Verifier (`bin/verify-ai.sh`)

```bash
# 1. Catch bash syntax errors and hidden CRLF (\r) endings
bash bin/verify-ai.sh script path/to/deploy.sh

# 2. Validate strict JSON (rejects trailing commas, NaN, and Infinity)
bash bin/verify-ai.sh json path/to/config.json

# 3. Verify no files were silently dropped between src and dst directories
bash bin/verify-ai.sh diff-dirs ./src ./dst

# 4. Verify a regex against valid AND adversarial inputs
bash bin/verify-ai.sh regex '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' \
  --must-match 2026-11-22 \
  --must-reject 2026-13-45 --must-reject 17/11/2026

# 5. Run a piped test command under strict pipefail so tail/grep cannot hide failures
bash bin/verify-ai.sh run-strict "pytest | tail -n 20"
```

### 2. LLM Log Sanitizer (`bin/sanitize-log.sh`)

Scrub secrets (`sk-`, `ghp_`, `github_pat_`, `xoxb-`, `AKIA`, `Bearer `), collapse duplicate crash lines into frequency counts, and cap token budget before pasting logs into prompts:

```bash
cat app.log | bash bin/sanitize-log.sh --max-line 140 --max-bytes 4000 --top 15
```

### 3. Claude Code `PostToolUse` Hook (`hooks/claude-post-edit-verify.sh`)

Wire into `.claude/settings.json` to auto-validate every `.sh`, `.py`, and `.json` file Claude Code edits or writes:

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

## Verification Receipt Protocol

When finishing a task using this skill, report:
1. The exact verification command executed.
2. The raw observed exit code (`exit 0` or failure output).
3. `git diff --stat` confirming no unintended files (especially `tests/`) were altered.

---

## More Verified Receipts & Updates

- Interactive receipts & guard snippets: **https://harveyi.com**
- Open-source repository & CI: **https://github.com/haiwei971-ui/ai-verify-guards**
- Daily locally-verified receipts on X: **https://x.com/lxy71**
