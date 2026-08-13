---
title: Set status during create
status: reviewing
created_at: 2026-08-10T10:52:28Z
updated_at: 2026-08-13T20:50:33Z
developing_at: 2026-08-13T20:37:29Z
reviewing_at: 2026-08-13T20:50:33Z
---

# Description

Allow callers to set an item's initial non-closed status during `taskr create`
instead of always writing the built-in default status.

# Acceptance

- `taskr create` accepts an explicit initial status through
  `--status <status>`.
- The requested status is validated with the same status model used by
  `taskr status`, `taskr list --status`, and reports.
- Every currently valid status except `done` and `cancelled` may be selected as
  an initial status. Creating already closed work is rejected because it does
  not represent a creation workflow.
- If no status is provided, create keeps the documented `open` default.
- Invalid status values fail clearly before any item directory or marker file is
  created.
- `created_at`, `updated_at`, and the selected `<status>_at` field receive the
  same UTC RFC3339 timestamp, including `open_at` for the default status.
- Status completion works for the create status argument and offers all valid
  initial statuses without `done` or `cancelled`.
- Documentation, help, examples, and workflow docs describe the option and the
  default behavior.
- `taskr examples` includes the ordinary form
  `taskr create task "Implement parser" --under 001 --status designing` and an
  extended form combining parent, initial status, and non-interactive creation.
- Smokey tests cover the default status and timestamp, every explicit valid
  initial status, closed and invalid status rejection before creation,
  timestamp consistency, help, examples, and completion values.

# Comments

- 2026-08-10: Added after clarifying that `taskr create` currently writes
  `status: open` and has no way to set another initial status directly.
- 2026-08-13: Agreed that `done` and `cancelled` make no sense during creation
  and are rejected. Other currently valid statuses are allowed. Creation writes
  one timestamp consistently to `created_at`, `updated_at`, and the selected
  status-specific timestamp.

# Outcome

`taskr create --status` now accepts every built-in non-closed status and
defaults to `open`. Invalid, `done`, and `cancelled` values fail before any item
directory is created. New markers record one identical UTC RFC3339 value in
`created_at`, `updated_at`, and the selected status timestamp. Help, completion,
workflow documentation, examples, and Smokey coverage describe and verify the
behavior.
