---
title: Define milestone close workflow
status: designing
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Define how a milestone should be closed from the CLI before the MVP milestone
itself is closed.

# Acceptance

- The workflow states whether `taskr status <milestone> done` is enough or
  whether a dedicated command such as `taskr close <selector>` is needed.
- The workflow defines how `# Outcome` must be handled before a milestone can be
  closed.
- The workflow preserves the rule that parents can only be `done` when all
  completion children are done.
- The workflow is designed together with `048-validate-status-transitions` so
  milestone closure uses the same transition model as ordinary status changes.
- The workflow defines what happens after close: stay in place, archive
  immediately, or archive as a separate command.
- Required command/help/doctor changes are identified before implementation.

# Comments

- 2026-08-07: Current implementation can set a milestone to `done` via
  `taskr status <selector> done` when all descendants are already `done`.
  There is no dedicated milestone-close command or outcome enforcement yet.
- 2026-08-10: This should be handled together with
  `048-validate-status-transitions`; closing a milestone is a special case of
  status transition validation, not an independent rule system.
- 2026-08-10: Moved from `MVP` to `Governance` because the current CLI can
  already close milestones with `taskr status <milestone> done`; the remaining
  work is about policy and validation checks, not MVP availability.

# Outcome
