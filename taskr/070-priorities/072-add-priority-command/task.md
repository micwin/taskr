---
title: Add priority command
status: reviewing
created_at: 2026-08-10T14:41:17Z
updated_at: 2026-08-10T15:24:30Z
designing_at: 2026-08-10T14:41:17Z
developing_at: 2026-08-10T15:07:28Z
reviewing_at: 2026-08-10T15:24:30Z
---

# Description

Add a command for changing one task's effective priority through the CLI.

# Acceptance

- `taskr priority <selector> <high|normal|low>` changes exactly one task.
- Setting `high` or `low` writes the corresponding marker metadata.
- Setting `normal` removes any stored priority field and leaves the effective
  priority as `normal`.
- Every real priority change updates `updated_at`; no separate `priority_at`
  field is introduced.
- Milestone and subtask selectors are rejected with a clear error.
- Missing and ambiguous selectors follow the shared selector behavior.
- Command output reports old and new effective priority, whether the marker
  changed, and whether a priority value remains stored.
- Repeating the effective priority is a successful no-op and does not rewrite
  the marker or update `updated_at`.
- Help, examples, and shell completion cover selectors and all three values.
- Smokey tests cover every value, normalization to omitted `normal`, no-op,
  invalid values, unsupported roles, selectors, help, and completion.

# Comments

- 2026-08-10: Mutation is isolated from display and reporting behavior.
- 2026-08-10: Resetting with `taskr priority <selector> normal` removes stored
  priority metadata. A separate clear/delete form is intentionally omitted.

# Outcome

`taskr priority <selector> <high|normal|low>` now changes task priority through
the CLI. High and low are stored, normal removes the field, real changes update
`updated_at`, and effective no-ops leave markers byte-identical. The command
rejects unsupported roles and invalid values, uses task-only selector
completion, completes all three values, and is covered by help, examples,
workflow documentation, and Smokey behavior.
