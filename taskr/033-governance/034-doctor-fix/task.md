---
title: Add doctor fix mode
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add a `taskr doctor --fix` mode that repairs root-wide duplicate item IDs by
renumbering colliding item directories after showing or reporting what changed.
Other repair classes stay out of scope for the first implementation.

This belongs to Governance because repair behavior defines how Taskr recovers
from process failures such as the current duplicate `018` ID.

# Acceptance

- `taskr doctor` remains read-only by default.
- `taskr doctor --fix` repairs duplicate item IDs deterministically.
- `taskr doctor --fix` currently fixes only duplicate IDs.
- `taskr doctor --fix` succeeds only when every detected error is fixed by the
  run.
- If the worktree has errors outside the supported fix scope, `--fix` reports
  the unsupported error and leaves the worktree unchanged.
- `taskr doctor --fix --lenient` uses best-effort behavior: it applies
  supported fixes even when unsupported errors remain.
- Lenient fix mode still exits non-zero if unsupported errors remain after the
  supported fixes are applied.
- The command reports every changed path.
- The first item for a duplicated ID keeps its current ID according to the
  normal item sort order.
- Later colliding items are renamed to the next free root-wide IDs.
- Directory slugs and marker content are preserved.
- Fix operations use a temporary work directory from the platform's standard
  temp location, such as Go's `os.TempDir()`, instead of creating temporary
  files below the Taskr root.
- The temporary work directory is cleaned up after success and after handled
  failure paths.
- The command preserves marker content and required section order.
- Command help documents duplicate-ID repair behavior and current limitations.
- Documentation and help describe the actual implemented `doctor` validation
  scope instead of aspirational checks that are not implemented yet.
- Documentation and help explain that fix mode requires a reasonably loadable
  worktree; it can repair supported integrity problems but cannot recover from
  arbitrary broken marker structure or malformed marker content.
- Documentation and help explain that `--lenient` relaxes all-or-fail behavior
  to best-effort repair.
- Smokey tests cover read-only doctor behavior and duplicate-ID repair.
- Shell completion includes the `--fix` flag.

# Comments

- 2026-08-10: Added while discussing the duplicate-ID failure.
- 2026-08-10: Moved from `Refinement` to `Governance` because repair policy is
  part of resolving the current `018` worktree failure inside the process.
- 2026-08-10: Initial Smokey workflow defines `doctor --fix` as duplicate-ID
  repair only. Other repairs can become later tickets.
- 2026-08-10: `doctor` currently validates the loadable worktree structure and
  frontmatter fields used by the loader, not every stricter rule described in
  the earlier README. This ticket should align docs/help with actual behavior.
- 2026-08-10: Fix mode should be all-or-fail for detected errors. It must not
  silently repair duplicate IDs while leaving other known validation errors in
  the same worktree.
- 2026-08-10: `--lenient` intentionally weakens that to best-effort repair for
  cases where preserving some progress is more useful than an unchanged tree.
- 2026-08-10: Temporary repair staging should use the system temp location
  (`$TMPDIR`, `$TMP`, `$TEMP`, or the platform default as resolved by Go)
  instead of adding transient files to the Taskr root.

# Outcome
