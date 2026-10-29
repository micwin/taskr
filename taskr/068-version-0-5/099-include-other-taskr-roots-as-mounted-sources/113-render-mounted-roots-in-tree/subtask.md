---
title: Render mounted roots in tree
status: reviewing
created_at: 2026-08-25T17:20:19Z
updated_at: 2026-08-26T16:12:25Z
designing_at: 2026-08-25T17:20:19Z
developing_at: 2026-08-25T18:40:36Z
blocked_at: 2026-08-25T20:13:09Z
reviewing_at: 2026-08-26T16:12:25Z
---

# Description

Extend `taskr tree` so mount objects and mounted subtrees render in hierarchy
output.

# Acceptance

- Mount objects render as root-level virtual items.
- Mount object rows use `id [mount <mode>] <name>` and show the configured
  mount mode (`read-only` or `read-write`) where normal item rows show status.
  Mount objects do not show Taskr lifecycle status values.
- Mounted root contents render below their mount object using mount-prefixed
  item identity.
- Root branches remain separate: milestones, tasks, and subtasks appear only
  beneath their own source, even when different roots use identical IDs and
  titles. No item may drift into a neighboring root's rendered branch.
- A mounted root without milestones still renders its virtual mount object,
  with its root-level tasks and their subtasks grouped beneath it.
- Existing `tree` indentation modes still work with mounted roots.
- Default unfinished filtering and `--all` behavior are preserved for mounted
  items.
- Cyclic and unavailable mounts fail clearly.
- Help, docs, examples, and shell completion cover mounted tree behavior.
- Smokey covers default tree output, mount objects with modes instead of
  statuses, `--all`, indentation flags, transitive mounts, cycles, unavailable
  mounts, and local/mounted ID collisions.
- Smokey compares complete expected output, including row order and indentation,
  for default, --all, --ascii, --tabs, and --wide modes. Selected direct and
  transitive milestone trees exclude every other root's items.

# Comments

- 2026-08-25: Tree-specific slice of ticket 099.

- 2026-08-25 22:13: Blocked on branch render-mounted-roots-in-tree: accepted exact-row checks pass unescaped square brackets to grep as regular expressions. The branch performs literal fixed-string checks and correct tab matching.

- 2026-10-06 16:35: Review correction: replaced presence-only row checks with ten complete expected-output comparisons for default/all/ASCII/tabs/wide, selected direct/transitive milestones, and a task-only mount. Fixtures include colliding local IDs and titles plus subtasks. The first full comparison exposed equal sort keys for virtual mounts; tree ordering now breaks ties by qualified ID. Full Smokey suite: 48/48 with teardown; Go tests pass.

# Outcome

Mounted roots and their item hierarchies now render in every tree indentation
mode with source-qualified identities and mount access modes.

Review correction: complete expected-output fixtures verify local, direct,
and transitive root boundaries, including identical IDs and titles, subtasks,
closed items, and task-only mounted roots. Selecting a mounted milestone or
task-only mount produces exactly that source subtree. Tree sorting now uses
qualified identity to break equal numeric-ID/path ties for virtual mounts.

# Release Notes

`taskr tree` now includes mounted roots and their items.
Mount root rows have a deterministic order and keep each source subtree separate.
