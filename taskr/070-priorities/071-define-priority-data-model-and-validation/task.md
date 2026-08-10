---
title: Define priority data model and validation
status: developing
created_at: 2026-08-10T14:41:16Z
updated_at: 2026-08-10T14:50:40Z
designing_at: 2026-08-10T14:41:17Z
developing_at: 2026-08-10T14:50:40Z
---

# Description

Define and load the fixed task priority values `high`, `normal`, and `low`
without introducing priority for milestones or subtasks.

# Acceptance

- Task markers may contain `priority: high` or `priority: low`.
- Missing `priority` and an explicitly requested `normal` priority both have the
  effective value `normal`; Taskr does not persist redundant `priority: normal`.
- Milestones and subtasks do not accept stored priority.
- Priority never changes status, completion, hierarchy, dependencies, or
  archive eligibility.
- `show --meta` displays a task's effective priority.
- Doctor accepts omitted priority and validates present values, role, and case.
- Existing markers require no migration or rewrite.
- Smokey tests cover valid values, omitted/default priority, invalid values,
  unsupported item roles, Doctor, and `show --meta`.

# Comments

- 2026-08-10: Fixed three-level model delegated by analysis ticket `061`.

# Outcome
