---
title: Move mounted items
status: reviewing
created_at: 2026-08-25T17:31:00Z
updated_at: 2026-08-25T20:15:44Z
designing_at: 2026-08-25T17:31:00Z
developing_at: 2026-08-25T19:27:44Z
reviewing_at: 2026-08-25T20:15:44Z
---

# Description

Extend `taskr move` so items can be moved within read-write mounted roots.

Cross-root moves are out of scope unless explicitly added later. Initial
mounted move behavior is same-root inside the selected mounted root.

# Acceptance

- `taskr move <mount-id>:<item> --under <mount-id>:<parent>` moves inside the
  same read-write mounted root.
- When `--under` contains a mount selector, its mount chain must match the
  source mount chain exactly.
- When `--under` omits a mount selector, the parent selector is resolved inside
  the source root, not inside the command's local parent root.
- `taskr move <mount-id>:<item> --root` moves the item to the mounted root
  level, not the parent root.
- `taskr move .:<item> ...` targets the local root explicitly.
- Cross-root moves between local and mounted roots or between different mounts
  fail clearly unless later explicitly designed.
- Read-only mounted roots fail clearly and leave every root unchanged.
- Existing `--retype`, terminal-parent, descendant, rollback, and timestamp
  behavior remains enforced in mounted roots.
- Help, docs, examples, and shell completion cover mounted `move` selectors and
  mounted `--under`.
- Smokey covers read-write mounted move, `--root`, `--retype`, cross-root
  rejection, read-only rejection, unchanged parent root, rollback, and
  completion.

# Comments

- 2026-08-25: Added after reviewing 099 command coverage.

# Outcome

Move operates within the source root, supports qualified and source-relative
parents, preserves retyping rules, and rejects cross-root or read-only moves.

# Release Notes

`taskr move` supports items inside writable mounted roots.
