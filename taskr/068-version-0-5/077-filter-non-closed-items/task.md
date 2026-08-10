---
title: Filter non-closed items
status: designing
created_at: 2026-08-10T16:11:24Z
updated_at: 2026-08-10T16:11:31Z
designing_at: 2026-08-10T16:11:31Z
---

# Description

Add a reusable item filter for work that is neither completed nor cancelled.
The filter should make it easy to select all currently relevant milestones,
tasks, or subtasks without enumerating every open lifecycle status. The exact
CLI flag name and affected commands will be refined before implementation.

# Acceptance

- The filter includes items in every status except `done` and `cancelled`.
- The behavior applies consistently to milestones, tasks, and subtasks where
  the selected command supports those item types.
- The design identifies every command surface that should expose the filter.
- The filter composes predictably with type, parent, priority, and other
  applicable filters.
- Conflicting status-filter combinations fail clearly or have explicitly
  documented precedence.
- Help, examples, documentation, completion, and Smokey coverage are defined
  before implementation begins.

# Comments

- 2026-08-10: Created as a Version 0.5 follow-up while developing item rename.
  The requested semantic set is exactly all statuses except `done` and
  `cancelled`; command naming remains to be refined.

# Outcome
