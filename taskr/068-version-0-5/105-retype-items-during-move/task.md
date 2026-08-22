---
title: Retype items during move
status: designing
created_at: 2026-08-22T14:20:00Z
updated_at: 2026-08-22T14:20:10Z
open_at: 2026-08-22T14:20:00Z
designing_at: 2026-08-22T14:20:10Z
---

# Description

Extend `taskr move` so moving an item to a parent with a different expected
child role automatically changes the item's marker type when the conversion is
unambiguous.

The user-facing operation remains `move`: users move work to the place where it
now belongs, and Taskr derives whether the item must become a `task` or
`subtask` from the destination parent. The command must preserve the item's ID,
slug, directory name, content sections, comments, outcome, child directories,
and files while changing only the marker filename required by the new role.

The same parent-context status rules used by `create` apply to `move`. An item
with unfinished work must not be moved below a terminal parent context. Moving
open work below a `done` or `cancelled` task or milestone must fail clearly
instead of silently reopening or corrupting the hierarchy.

# Acceptance

- `taskr move <selector> --under <parent-selector>` keeps the existing behavior
  when the source item type already matches the destination parent.
- Moving a `task` under another `task` automatically converts the source marker
  from `task.md` to `subtask.md`.
- Moving a `subtask` under a `milestone` automatically converts the source
  marker from `subtask.md` to `task.md`.
- The command output reports the type change when one happened, for example
  `type=task->subtask`.
- Retyping preserves the source ID, slug, directory name, title, frontmatter
  metadata, content sections, comments, outcome, child directories, and files.
- The destination parent selector is still validated for missing, ambiguous,
  self, and self-descendant cases.
- Moving or retyping below a `done` or `cancelled` parent context fails clearly.
- Moving a source item that contains unfinished descendants below a terminal
  ancestor fails clearly through normal worktree validation.
- `--root` behavior stays unchanged in this ticket; root-level type changes are
  not introduced here.
- Retype-and-move operations are rolled back if the resulting worktree is
  invalid.
- `taskr move --help` documents automatic retyping and closed-parent behavior.
- Shell completion remains valid for move sources and `--under` parents.
- Smokey tests cover task-to-subtask move, subtask-to-task move, unchanged-type
  move, terminal-parent rejection, rollback-relevant invalid move rejection,
  help text, and completion surfaces.

# Comments

- 2026-08-22: Michael decided that this belongs in `move`, not in a separate
  `retype` command. `move` should infer type changes from the destination.
- 2026-08-22: Closed parent context follows ticket 046: terminal parents are
  `done` and `cancelled`, and they must not accept new or moved unfinished
  work.

# Outcome
