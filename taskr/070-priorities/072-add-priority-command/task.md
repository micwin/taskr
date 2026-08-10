---
title: Add priority command
status: designing
created_at: 2026-08-10T14:41:17Z
updated_at: 2026-08-10T14:41:17Z
designing_at: 2026-08-10T14:41:17Z
---

# Description

Add a command for changing one task's effective priority through the CLI.

# Acceptance

- `taskr priority <selector> <high|normal|low>` changes exactly one task.
- Setting `high` or `low` writes the corresponding marker metadata.
- Setting `normal` removes any stored priority field and leaves the effective
  priority as `normal`.
- Milestone and subtask selectors are rejected with a clear error.
- Missing and ambiguous selectors follow the shared selector behavior.
- Command output reports old and new effective priority and whether the marker
  changed.
- Help, examples, and shell completion cover selectors and all three values.
- Smokey tests cover every value, normalization to omitted `normal`, no-op,
  invalid values, unsupported roles, selectors, help, and completion.

# Comments

- 2026-08-10: Mutation is isolated from display and reporting behavior.

# Outcome
