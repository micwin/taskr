---
title: Validate status transitions
status: designing
created_at: 2026-08-10T10:33:05Z
updated_at: 2026-08-10T10:33:05Z
---

# Description

Add validation for `taskr status` so status changes follow an explicit
transition model instead of accepting any allowed status value at any time.

# Acceptance

- The allowed status transition graph is documented.
- `taskr status` accepts valid transitions and rejects invalid transitions with
  clear errors.
- Existing structural checks remain in place, such as rejecting `done` when
  children are unfinished.
- The transition model accounts for `designing`, `developing`, `in_review`,
  `done`, `cancelled`, `blocked`, and existing `open` behavior.
- Status filtering remains independent of transition validation.
- Shell completion continues to list valid status values, and may narrow
  suggestions to valid transitions if implemented.
- The existing Taskr dogfood database is adjusted to satisfy the transition
  model where needed.
- Smokey tests cover valid transitions, invalid transitions, child blockers for
  `done`, and cancellation/blocking cases.
- Smokey tests use dedicated fixtures for transition behavior instead of
  relying only on the dogfood database.

# Comments

- 2026-08-10: Split from the `developing`/`in_review` status discussion because
  transition validation changes command semantics beyond adding status values.

# Outcome
