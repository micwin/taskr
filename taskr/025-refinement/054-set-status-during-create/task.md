---
title: Set status during create
status: designing
created_at: 2026-08-10T10:52:28Z
updated_at: 2026-08-10T10:52:28Z
---

# Description

Allow callers to set an item's initial status during `taskr create` instead of
always writing the built-in default status.

# Acceptance

- `taskr create` accepts an explicit initial status, likely through
  `--status <status>`.
- The requested status is validated with the same status model used by
  `taskr status`, `taskr list --status`, and reports.
- If no status is provided, create keeps the documented default behavior.
- Invalid status values fail clearly before any item directory or marker file is
  created.
- Status completion works for the create status argument.
- Documentation, help, examples, and workflow docs describe the option and the
  default behavior.
- Smokey tests cover default create status, explicit valid status, invalid
  status rejection, and completion for create status values.

# Comments

- 2026-08-10: Added after clarifying that `taskr create` currently writes
  `status: open` and has no way to set another initial status directly.

# Outcome
