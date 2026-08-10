---
title: Add tree command
status: done
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add a `tree` command that prints the Taskr item hierarchy as a compact
terminal tree. The command should show milestones, tasks, and subtasks with
their ID, title, role, and short status so users can inspect the shape of a
worktree without opening individual marker files. Default output uses
space-based indentation without branch markers.

# Acceptance

- `taskr tree` prints the whole Taskr worktree as an indented tree.
- `taskr tree <selector>` prints only the selected subtree.
- Each work item line includes ID, role, short status, and title.
- Default `taskr tree` output uses two spaces per hierarchy level.
- Default `taskr tree` output does not include `+-` or `|` branch markers.
- Done items are hidden by default unless they are needed to keep visible
  children understandable.
- `--all` includes done and cancelled items explicitly.
- `--open` shows only open work, meaning items whose own status is neither
  `done` nor `cancelled`.
- `--ascii` preserves the earlier branch-marker output.
- `--tabs` uses one tab per hierarchy level for indentation.
- `--wide` uses wider space indentation than the default.
- `--tabs` and `--wide` fail clearly when used together.
- File containers and archived work are not shown in the default tree.
- Command help documents selectors, status display, done/open filtering, and
  output formatting flags.
- Shell completion covers the command, selectors, and tree flags where
  applicable.
- Smokey tests cover full-tree output, selected-subtree output, done filtering,
  the `Refinement` milestone example, default indentation, `--ascii`, `--tabs`,
  `--wide`, and invalid formatting flag combinations.

# Comments

- 2026-08-10: Added after dogfooding showed that `list` is too flat for
  milestone planning and refinement review.
- 2026-08-10: Initial CLI contract uses ASCII tree branches (`+-` and `|`) for
  console readability. The first filtering flags are `--all` and `--open`.
- 2026-08-10: Dogfooding showed the ASCII branch markers are visually noisy.
  Default output should use plain space indentation. The branch-marker format
  remains available with `--ascii`.

# Outcome

Implemented `taskr tree` with ASCII hierarchy output. The command supports a
whole-root view, selected subtree view, `--all` for closed items, and `--open`
for open-only views. File containers and archived work stay out of the default
tree through the existing loader behavior.

Help, selector completion, workflow examples, README documentation, and Smokey
coverage were updated. The Smokey suite covers default filtering, all-items
mode, selected subtrees, open-only filtering, a Refinement-style milestone
example, help, and completion.
