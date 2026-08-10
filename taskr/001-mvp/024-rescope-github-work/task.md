---
title: Rescope GitHub work out of MVP
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Move GitHub publishing work out of the MVP milestone into a new `going public`
milestone so the local Taskr MVP can close independently.

# Acceptance

- A new `going public` milestone exists.
- GitHub release work moves from the MVP milestone into `going public`.
- GitHub Pages work moves from the MVP milestone into `going public`.
- Broader GitHub integration work is attached to `going public` or explicitly
  linked from it.
- The MVP milestone acceptance is adjusted so it no longer requires GitHub
  publishing before local MVP closure.
- The move is performed with Taskr itself once the move command exists.
- The resulting Taskr worktree passes `taskr doctor`.

# Comments

- 2026-08-10: This ticket should wait for `023-move-items-between-parents` so
  the rescope can be done by dogfooding Taskr instead of manual `mv`.

# Outcome
