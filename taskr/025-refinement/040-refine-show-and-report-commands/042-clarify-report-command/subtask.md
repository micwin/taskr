---
title: Clarify report command
status: designing
created_at: 2026-08-10T09:48:33Z
updated_at: 2026-08-10T09:48:33Z
---

# Description

Clarify and implement `report` as a command for multi-item summaries across a
set of matching Taskr items.

# Acceptance

- `taskr report` is documented as a multi-ticket report command.
- Default report output remains compact and lists multiple matching items.
- Report filters such as `--under`, `--type`, and `--status` keep their current
  semantics.
- `report` does not become the primary way to inspect one item's complete
  marker text.
- If report gains detail flags later, they are explicitly scoped to multi-item
  reporting.
- Help documents the multi-item role of `report`.
- Smokey tests cover report output with multiple matching tickets and filtered
  report output.

# Comments

- 2026-08-10: Split from parent `040`. `report` is for summaries over sets of
  items; `show` is the single-item content viewer.

# Outcome
