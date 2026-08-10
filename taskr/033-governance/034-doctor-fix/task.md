---
title: Add doctor fix mode
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add a `taskr doctor --fix` mode that can repair well-understood structural
problems in a Taskr worktree after showing or reporting what will change.
Unsafe or semantic repairs must remain errors unless the user explicitly
confirms them through a supported option.

This belongs to Governance because repair behavior defines how Taskr recovers
from process failures such as the current duplicate `018` ID.

# Acceptance

- `taskr doctor` remains read-only by default.
- `taskr doctor --fix` repairs only deterministic, non-semantic problems.
- The command reports every changed path.
- The command refuses ambiguous repairs, such as choosing a new ID for a
  duplicate item, unless an explicit supported policy exists.
- The command preserves marker content and required section order.
- Command help documents what `--fix` can and cannot repair.
- Smokey tests cover read-only doctor behavior, a repaired fixture, and an
  unrepaired ambiguous fixture.
- Shell completion includes the `--fix` flag.

# Comments

- 2026-08-10: Added while discussing the duplicate-ID failure. Duplicate IDs
  are probably not auto-fixable until the desired renumbering policy is defined.
- 2026-08-10: Moved from `Refinement` to `Governance` because repair policy is
  part of resolving the current `018` worktree failure inside the process.

# Outcome
