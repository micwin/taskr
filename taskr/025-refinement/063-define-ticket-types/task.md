---
title: Define ticket types
status: designing
created_at: 2026-08-10T13:04:28Z
updated_at: 2026-08-10T13:04:28Z
---

# Description

Define ticket types for Taskr items, such as `bug`, `addon`, `feature`, or
similar categories. Ticket type is separate from the structural item role
(`milestone`, `task`, `subtask`) and should support filtering, reporting, and
workflow decisions without duplicating hierarchy information.

# Acceptance

- The ticket type concept is analyzed before implementation.
- The MVP scope and possible subfeatures are documented before implementation.
- The design distinguishes item role from ticket type.
- The design covers storage, validation, filtering, completion, reports,
  examples, and doctor behavior.
- The design avoids making ticket type mandatory before the default behavior is
  clearly decided.
- Follow-up implementation tickets are created only after the analysis and
  scope are accepted.

# Comments

- 2026-08-10: Added as a refinement feature idea for categorizing tickets as
  bugs, addons, features, or similar work kinds.

# Outcome
