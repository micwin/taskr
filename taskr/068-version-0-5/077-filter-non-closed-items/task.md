---
title: Filter non-closed items
status: done
created_at: 2026-08-10T16:11:24Z
updated_at: 2026-08-10T16:34:05Z
designing_at: 2026-08-10T16:11:31Z
developing_at: 2026-08-10T16:24:50Z
reviewing_at: 2026-08-10T16:27:14Z
done_at: 2026-08-10T16:34:05Z
---

# Description

Make `list` and `tree` show unfinished work by default. Unfinished means every
status except `done` and `cancelled`. Users can opt into terminal items with
the shared `--all` flag:

```text
taskr list
taskr list --all
taskr tree
taskr tree --all
```

The existing `tree --open` flag becomes redundant and is removed from the CLI
and every supporting surface.

# Acceptance

- `taskr list` and `taskr tree` exclude items whose own status is `done` or
  `cancelled` by default.
- `taskr list --all` and `taskr tree --all` include `done` and `cancelled`
  items.
- Default filtering and `--all` apply consistently to milestones, tasks, and
  subtasks.
- `list --all` composes with `--type`, `--under`, `--priority`, priority
  grouping, and priority display flags.
- Explicit terminal status filters require `--all`, for example
  `taskr list --all --status done`; requesting `--status done` or
  `--status cancelled` without `--all` fails clearly and points to `--all`.
- Non-terminal `--status` filters continue to work without `--all`.
- `tree --open` is removed because unfinished-only output is now the default.
- Tests for `tree --open` are removed or rewritten to assert the new default
  and `--all` behavior.
- Command help, workflow examples, user documentation, shell completion, and
  existing tests are updated to remove `tree --open`, document `list --all`,
  and avoid examples that request terminal list statuses without `--all`.
- Smokey covers all non-terminal statuses, exclusion of both terminal
  statuses, `--all`, compatible filters, terminal `--status` validation, and
  removal of `tree --open`.

# Comments

- 2026-08-10: Created as a Version 0.5 follow-up while developing item rename.
  The requested semantic set is exactly all statuses except `done` and
  `cancelled`; command naming remains to be refined.
- 2026-08-10: Reversed the initial opt-in-filter proposal. `list` and `tree`
  now default to unfinished items, `--all` includes terminal items, and the
  redundant `tree --open` surface is removed completely.

# Outcome

`list` and `tree` now show unfinished items by default and include `done` and
`cancelled` only with `--all`. Terminal list status filters require `--all`,
the flag composes with existing list filters and priority controls, and the
redundant `tree --open` surface has been removed from code, tests, help,
completion, examples, and documentation.
