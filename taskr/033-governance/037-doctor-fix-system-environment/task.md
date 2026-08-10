---
title: Add doctor fix system environment mode
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add an explicit `taskr doctor --fix --system` mode for repairable system or
environment problems. The first target is an unusable temporary directory
configuration while running Taskr.

Without `--system`, system and environment failures remain errors and must not
be treated as Taskr data problems.

`--system` is not a lenient data-repair mode. It fixes only supported system
problems and must not repair Taskr worktree data such as duplicate IDs.

# Acceptance

- `taskr doctor --fix` without `--system` keeps failing on unusable system temp
  configuration without changing the Taskr worktree.
- `taskr doctor --fix --system` repairs only supported system/environment
  problems.
- `taskr doctor --fix --system` does not repair duplicate IDs or other Taskr
  worktree data problems.
- `--system` and a future `--lenient` mode are separate concepts; this ticket
  does not add `--lenient`.
- The first supported system fix handles unusable temp configuration.
- `taskr doctor` detects missing or unusable temp configuration.
- Normal Taskr commands emit a warning at startup when temp configuration is
  missing or unusable, but continue when the command does not need temp.
- Temp environment values are inspected before attempting a system fix.
- Empty temp values, root-only temp values such as `/`, and invalid or unsafe
  temp locations are rejected instead of used blindly.
- When the configured temp location cannot be made safe, Taskr falls back to
  creating a temporary directory with the platform default temp lookup.
- System fixes are reported separately from Taskr data fixes.
- A `--dry` flag exists for `--system` repair and reports the planned system
  changes without applying them.
- If `--dry` becomes a global flag, command help and docs for `--system`
  explicitly mention that global dry-run behavior.
- Help and docs clearly separate Taskr data repair from system/environment
  repair.
- Smokey tests cover doctor detection of bad temp configuration, startup
  warnings for normal commands, default failure on bad temp configuration,
  `--fix --system --dry`, and successful `--fix --system` behavior for a
  repairable temp case.

# Comments

- 2026-08-10: Split out from `034-doctor-fix` so the first implementation can
  keep system failures separate from Taskr data repair.
- 2026-08-10: The current implementation treats missing or unusable temp as an
  environment error. This ticket adds an explicit opt-in to handle repairable
  cases.
- 2026-08-10: `--system` should be exclusive to system repair, not a best-effort
  mode for Taskr data. `--dry` should show what would be changed before a
  system repair is applied.

# Outcome
