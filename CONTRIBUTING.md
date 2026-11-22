# Contributing to ai-verify-guards

Caught a sneaky silent failure from Claude Code, Cursor, Codex, or another coding agent? PRs and issue reports are very welcome.

## What Makes a Great Guard
1. **Real failure mode**: Must catch an actual silent failure (false-green test, broken encoding, silently skipped files, non-strict parsing, etc.) — no contrived toy examples.
2. **Zero external dependencies**: Standard POSIX/Bash utilities and Python 3 standard library only so anyone can run it on macOS or Linux out of the box.
3. **Proven with a failing + passing test**: Every new guard must add both a negative case (proving it catches the bug) and a positive case to `tests/run_tests.sh`.

## Local Verification Before Opening a PR
```bash
chmod +x bin/*.sh hooks/*.sh tests/*.sh
./tests/run_tests.sh
```
