---
title: Clarify show command
status: done
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
- `taskr show <selector>` fails when the selector matches zero items.
- When a selector matches multiple items, `show` exits with a non-zero status
  and prints every candidate's item ID and title so the user can immediately
  retry with an unambiguous selector.
- Full show output includes the item identity, title, status, marker path,
  `# Description`, `# Acceptance`, `# Comments`, and `# Outcome`.
- `taskr show <selector> --meta` prints marker metadata/frontmatter fields
  instead of the full body view.
- `--meta` is not a short output mode; a future `--short` mode is out of scope.
- Selector completion still works for `show`.
- Help documents the default full display and the `--meta` mode.
- Smokey tests cover default full output, metadata output, comments visibility,
  outcome visibility, missing selector errors, and ambiguous selector errors
  containing every candidate's ID and title.

# Comments

- 2026-08-10: Split from parent `040`. `show` is for one whole ticket, not only
  the previous concise metadata line.
- 2026-08-10: User clarified that `show` and `report` are completely separate:
  `show` is only for console output of a single item and must fail on ambiguous
  selectors. Future output formats or templates may be added later.
- 2026-08-10: Ambiguous selectors keep a non-zero exit status, but the
  diagnostic must list every matching item by ID and title instead of merely
  reporting ambiguity.

# Outcome

`taskr show <selector>` now prints one item's identity, marker path, and complete
Markdown body. `--meta` prints metadata without body sections. Ambiguous
selectors retain a non-zero exit status and list every matching item by ID and
title. Help, workflow documentation, examples, completion, and Smokey coverage
reflect the implemented behavior.
