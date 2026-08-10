---
title: Rescope GitHub work out of MVP
status: done
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Move GitHub publishing work out of the MVP milestone into the `GitHub
integration` milestone so the local Taskr MVP can close independently.

# Acceptance

- The `GitHub integration` milestone exists.
- GitHub release work moves from the MVP milestone into `GitHub integration`.
- GitHub Pages work moves from the MVP milestone into `GitHub integration`.
- Broader GitHub integration work is attached to `GitHub integration` or
  explicitly linked from it.
- The MVP milestone acceptance is adjusted so it no longer requires GitHub
  publishing before local MVP closure.
- The move is performed with Taskr itself once the move command exists.
- The resulting Taskr worktree passes `taskr doctor`.

# Comments

- 2026-08-10: This ticket should wait for `023-move-items-between-parents` so
  the rescope can be done by dogfooding Taskr instead of manual `mv`.
- 2026-08-10: Target milestone changed from the proposed `going public`
  milestone to the existing `Refinement` milestone.
- 2026-08-10: User clarified that GitHub work should move to the dedicated
  `GitHub integration` milestone instead of `Refinement`.

# Outcome

GitHub release and GitHub Pages work were moved out of the MVP milestone and
under the dedicated `GitHub integration` milestone using `taskr move`.
