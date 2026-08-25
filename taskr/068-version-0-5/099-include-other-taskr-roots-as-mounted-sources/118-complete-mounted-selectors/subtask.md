---
title: Complete mounted selectors
status: developing
created_at: 2026-08-25T17:20:21Z
updated_at: 2026-08-25T19:08:13Z
designing_at: 2026-08-25T17:20:21Z
developing_at: 2026-08-25T19:08:13Z
---

# Description

Extend shell completion for mount IDs and mounted item selectors at every
command surface introduced or affected by mounted roots.

The local root placeholder `.` participates in the same completion surfaces as
mount IDs. Transitive mount IDs must be completed as well.

# Acceptance

- Completion suggests mount IDs for `show`, `remove mount`, `reconfigure
  mount`, and other mount-object selectors.
- Completion suggests `.` where the current local root is accepted as an
  explicit mount/root selector.
- Completion suggests transitive mount IDs where mount IDs are accepted.
- Completion suggests mounted item selectors such as `vendor:003` where
  read-only item selectors are accepted.
- Completion suggests local-root-prefixed item selectors such as `.:005` where
  prefixed item selectors are accepted.
- Mutating-command completion suggests mounted item selectors only when the
  command can legally mutate them.
- Completion respects read-only/read-write mode and transitive mount chains.
- Completion includes mounted selectors for list/tree/report filter surfaces
  where selectors are accepted.
- Completion handles unavailable or invalid mounts with no file fallback and a
  clear command behavior.
- Help/docs/examples mention mounted selector completion where useful.
- Smokey covers exact completion surfaces for create/reconfigure/remove,
  show/list/tree/report/status, `--mount .`, `.:005`, read-only rejection,
  read-write success, and transitive mounts.

# Comments

- 2026-08-25: Completion-specific slice of ticket 099.
- 2026-08-25: Completion must include transitive mount IDs and the `.` local
  root placeholder.

# Outcome
