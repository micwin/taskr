---
title: Analyze ticket dependencies
status: designing
created_at: 2026-08-10T12:27:36Z
updated_at: 2026-08-10T12:27:36Z
---

# Description

Analyze how Taskr should represent and enforce dependencies between tickets
without undermining the current directory-derived hierarchy model.

The goal is to decide whether dependencies are needed as first-class metadata,
derived workflow state, report-only annotations, or a separate mechanism, and
how they interact with existing parent/child completion semantics.

# Acceptance

- The analysis distinguishes hierarchy from dependency: parent/child structure
  remains directory-derived, while dependencies represent ordering or blocking
  relationships across that hierarchy.
- The analysis defines concrete dependency use cases, such as one ticket
  waiting for another ticket's outcome or a design ticket gating implementation
  tickets.
- The analysis compares possible storage approaches without prematurely
  choosing one.
- The analysis covers how dependencies would affect `status`, `tree`, `list`,
  `report`, `doctor`, completion, and archive behavior.
- The analysis covers cycle detection, missing targets, renamed/moved items,
  archived items, and ambiguous selectors.
- The analysis explains whether dependencies should block `done`, block
  `developing`, appear only as warnings, or only affect reports.
- The analysis considers how to keep ticket files readable and avoid duplicated
  or redundant structural information.
- A proposed MVP dependency model is documented before any implementation
  ticket is created.

# Comments

- 2026-08-10: Added while discussing `047-add-developing-status`; several
  lifecycle ideas depend on relationships between tickets but should be handled
  separately from adding a status value.

# Outcome
