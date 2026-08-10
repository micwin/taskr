---
title: Resolve ID collision policy
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Resolve how Taskr should handle item ID collisions, fix the current dogfood
worktree collision, and cover the path that introduced it with a regression
test.

# Acceptance

- The intended ID uniqueness rule is documented clearly.
- The current duplicate `018` IDs in the dogfood worktree are resolved.
- `taskr doctor` passes for the repository dogfood worktree.
- Commands that load the whole worktree, such as `list`, work after the fix.
- If the uniqueness rule changes, selector behavior and completion are updated
  to stay unambiguous.
- Smokey tests cover duplicate-ID rejection or the replacement rule.
- The regression test reproduces a root-wide collision introduced by adding a
  new milestone whose ID already exists on a task below another milestone.

# Comments

- 2026-08-10: Current collision is between
  `taskr/001-mvp/018-create-help-valid-types/` and
  `taskr/018-github-integration/`.
- 2026-08-10: Git history shows both colliding items were introduced together
  in commit `8aad23b` (`docs: add follow-up taskr tickets`) by manually adding
  dogfood ticket directories. The failure path is manual batch ticket creation
  without a `taskr doctor` gate before committing.
- 2026-08-10: Git does not record whether `taskr create` was used. The
  sequential `taskr create` path should not be able to create this exact
  collision because it loads the root and chooses the next root-wide ID on each
  call. The likely path is manual editing or ticket creation from stale root
  state.
- 2026-08-10: Moved from `Refinement` to `Governance` because this affects the
  ID model and repository repair policy.

# Outcome
