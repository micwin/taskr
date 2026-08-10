---
title: Analyze configurable workflows
status: designing
created_at: 2026-08-10T12:32:30Z
updated_at: 2026-08-10T12:32:30Z
---

# Description

Analyze how Taskr should support configurable workflows for item statuses and
status transitions without breaking the built-in default lifecycle.

The immediate trigger is the `developing` status: it fits naturally between
`designing` and `reviewing`, but a configurable workflow feature would let
projects define their own lifecycle names, allowed transitions, and possibly
role-specific behavior.

# Acceptance

- The analysis defines the built-in default workflow, including `designing`,
  `developing`, `reviewing`, `done`, `cancelled`, `blocked`, and existing
  `open` behavior.
- The analysis decides what parts of a workflow may be configured: status
  names, transition graph, initial status, closed statuses, review handoff
  status, and role-specific rules.
- The analysis distinguishes personal config from project-local Taskr root
  workflow config.
- The analysis covers how configurable workflows interact with `taskr status`,
  `taskr create`, `list --status`, `report --status`, `tree --open`,
  `archive`, `doctor`, shell completion, and examples.
- The analysis covers invalid configs, migration of existing dogfood data,
  backwards compatibility, and default behavior when no workflow config exists.
- The analysis defines whether workflow config is required before implementing
  stricter transition validation in `048-validate-status-transitions`.
- The analysis explains how agent policy in `AGENTS.md` should refer to
  statuses when projects may configure workflow names.
- Smokey coverage requirements are identified for default workflow behavior and
  at least one project-local custom workflow fixture.
- No configurable workflow implementation is added until the design is
  accepted.

# Comments

- 2026-08-10: Added while preparing tests for `047-add-developing-status`; the
  status itself is small, but configurable lifecycle workflows are a separate
  design problem.

# Outcome
