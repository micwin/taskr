---
title: Add comment command
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add a `comment` command that appends a dated entry to an item's `# Comments`
section from the command line. This keeps routine ticket notes inside the Taskr
workflow without opening an editor for small updates.

# Acceptance

- `taskr comment <selector> <text>` appends the text to the selected item's
  `# Comments` section.
- The appended comment includes the current date.
- The command errors if the selector is missing, unknown, or ambiguous.
- The command preserves the required marker section order and keeps
  `# Outcome` as the final section.
- Multi-line comments are supported through stdin or an explicit option.
- Command help documents selector usage and comment input modes.
- Shell completion covers selectors for the command.
- Smokey tests cover single-line comments, multi-line comments, ambiguous
  selectors, and section preservation.

# Comments

- 2026-08-10: Added so common dogfood ticket notes can be written through the
  CLI instead of manual marker editing.

# Outcome
