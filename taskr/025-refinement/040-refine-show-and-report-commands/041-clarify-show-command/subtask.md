---
title: Clarify show command
status: designing
created_at: 2026-08-10T09:48:33Z
updated_at: 2026-08-10T09:48:33Z
---

# Description

Clarify and implement `show` as the command for displaying one complete Taskr
item on the console.

# Acceptance

- `taskr show <selector>` prints the selected item's full readable content by
  default.
- Full show output includes the item identity, title, status, marker path,
  `# Description`, `# Acceptance`, `# Comments`, and `# Outcome`.
- `taskr show <selector> --meta` prints marker metadata/frontmatter fields
  instead of the full body view.
- `--meta` is not a short output mode; a future `--short` mode is out of scope.
- Selector completion still works for `show`.
- Help documents the default full display and the `--meta` mode.
- Smokey tests cover default full output, metadata output, comments visibility,
  outcome visibility, and selector errors.

# Comments

- 2026-08-10: Split from parent `040`. `show` is for one whole ticket, not only
  the previous concise metadata line.

# Outcome
