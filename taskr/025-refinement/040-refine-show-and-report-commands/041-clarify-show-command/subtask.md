---
title: Clarify show command
status: designing
created_at: 2026-08-10T09:48:33Z
updated_at: 2026-08-10T09:48:33Z
---

# Description

Clarify and implement `show` as the command for displaying exactly one complete
Taskr item on the console. `show` is not a report command and does not summarize
sets of items.

# Acceptance

- `taskr show <selector>` prints the selected item's full readable content by
  default.
- `taskr show <selector>` is console-oriented output for one item only.
- `taskr show <selector>` fails when the selector matches zero or multiple
  items.
- Full show output includes the item identity, title, status, marker path,
  `# Description`, `# Acceptance`, `# Comments`, and `# Outcome`.
- `taskr show <selector> --meta` prints marker metadata/frontmatter fields
  instead of the full body view.
- `--meta` is not a short output mode; a future `--short` mode is out of scope.
- Selector completion still works for `show`.
- Help documents the default full display and the `--meta` mode.
- Smokey tests cover default full output, metadata output, comments visibility,
  outcome visibility, missing selector errors, and ambiguous selector errors.

# Comments

- 2026-08-10: Split from parent `040`. `show` is for one whole ticket, not only
  the previous concise metadata line.
- 2026-08-10: User clarified that `show` and `report` are completely separate:
  `show` is only for console output of a single item and must fail on ambiguous
  selectors. Future output formats or templates may be added later.

# Outcome
