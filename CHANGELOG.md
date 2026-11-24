# Changelog

All notable changes to `ai-verify-guards` are documented in this file.
This project follows [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-11-24

### Added
- **`py-test <file.py>` AST guard in `bin/verify-ai.sh`**: Detects silent Python `unittest.mock` tautologies where an AI coding agent writes `assert mock_fn.assert_called_once` (or bare `mock_fn.assert_called_once`) without parentheses `()` — which evaluates the truthy bound method object and exits `0` even when the mock was never called. Also flags `assert (cond, "msg")` non-empty tuple literals and `assert True`.
- **`--version` flag** on `bin/verify-ai.sh` (`ai-verify-guards v1.1.0`).
- **Test suite #8** in `tests/run_tests.sh` covering `py-test` tautology detection.
- Cross-links to companion tools [`ai-diff-audit`](https://github.com/haiwei971-ui/ai-diff-audit) and [`ai-signal-radar`](https://github.com/haiwei971-ui/ai-signal-radar).

## [1.0.0] - 2026-11-22

### Added
- Initial public release of `bin/verify-ai.sh` (`script`, `json`, `diff-dirs`, `regex`, `run-strict`).
- `bin/sanitize-log.sh` 3-step LLM log secret scrubber and deduplicator.
- `hooks/claude-post-edit-verify.sh` Claude Code `PostToolUse` hook.
- `SKILL.md` for Claude Code, Cursor, Codex, and Agensi.
- 7 end-to-end automated test suites and GitHub Actions CI workflow.
