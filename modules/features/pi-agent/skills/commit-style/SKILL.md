---
name: commit-style
description: Format git commit messages using Conventional Commits with a DCO sign-off line.
---
# Commit style

- Format: `type(scope): subject`.
- `type` is one of feat, fix, docs, refactor, perf, test, chore, build, ci, revert.
- `scope` is optional; use it for the affected package or module, lowercase.
- `subject`: imperative mood, no trailing period, ≤ 72 chars.
- Breaking change: append `!` after the type/scope and add a `BREAKING CHANGE:` footer.
- Body wraps at 72 chars. Explain *why*, not *what* — the diff already shows what.
- Every commit ends with a DCO sign-off: `Signed-off-by: Name <email>`. Use `git commit -s`.
- Never write "WIP", "misc", or "updates" as the subject — ask what actually changed.
