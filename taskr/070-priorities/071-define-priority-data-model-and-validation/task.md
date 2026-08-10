---
title: Define priority data model and validation
status: done
created_at: 2026-08-10T14:41:16Z
updated_at: 2026-08-10T14:52:43Z
designing_at: 2026-08-10T14:41:17Z
developing_at: 2026-08-10T14:50:40Z
reviewing_at: 2026-08-10T14:51:55Z
done_at: 2026-08-10T14:52:43Z
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
- Full `show` output always displays stored `high` and `low`; effective
  `normal` remains metadata-only.
- Doctor accepts omitted priority and validates present values, role, and case.
- Existing markers require no migration or rewrite.
- Smokey tests cover valid values, omitted/default priority, invalid values,
  unsupported item roles, Doctor, and `show --meta`.

# Comments

- 2026-08-10: Fixed three-level model delegated by analysis ticket `061`.
- 2026-08-10: After initial completion, full `show` output was clarified to
  always display stored `high` and `low`; `normal` remains metadata-only.

# Outcome

Task markers now load stored lowercase `high` and `low` priorities and derive
`normal` when the field is absent. Redundant stored `normal`, unknown or
non-canonical values, and priority metadata on milestones or subtasks fail
Doctor validation. `show --meta` displays every task's effective priority, and
full `show` output displays non-normal priority. The marker-format
documentation describes the backward-compatible model.
