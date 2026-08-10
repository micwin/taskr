---
title: Require examples for command variants
status: designing
created_at: 2026-08-10T09:58:06Z
updated_at: 2026-08-10T09:58:06Z
---

# Description

Add a project check that ensures every user-facing command, subcommand, flag,
and important command variant has documented examples. Each command should have
at least one common example and one advanced or edge-case example, without
labeling them with those internal categories in user-facing docs.

# Acceptance

- The build or test process checks example coverage for user-facing commands.
- Every command has at least one normal usage example.
- Every command with flags, subcommands, or non-trivial input modes has at
  least one advanced or edge-case example.
- The check covers Cobra command help, `taskr examples`, or another documented
  examples source chosen during implementation.
- The check fails when a new command or flag is added without suitable example
  coverage.
- User-facing docs do not expose internal labels such as "main form" or
  "expert form".
- The rule is documented for contributors.
- Smokey or another project-standard test verifies the check.

# Comments

- 2026-08-10: Added after `comment` needed help, examples, and README updates.
  The goal is a process guard so future commands and flags do not ship without
  examples for ordinary and more advanced use.

# Outcome
