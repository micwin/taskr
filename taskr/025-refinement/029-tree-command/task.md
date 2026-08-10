---
title: Add tree command
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add a `tree` command that prints the Taskr item hierarchy as a compact
terminal tree. The command should show milestones, tasks, and subtasks with
their ID, title, role, and short status so users can inspect the shape of a
worktree without opening individual marker files.

# Acceptance

- `taskr tree` prints the whole Taskr worktree as an indented tree.
- `taskr tree <selector>` prints only the selected subtree.
- Each work item line includes ID, role, short status, and title.
- Done items are hidden by default unless they are needed to keep visible
  children understandable.
- An option exists to include done items explicitly.
- An option exists to show only open work.
- File containers and archived work are not shown in the default tree.
- Command help documents selectors, status display, and done/open filtering.
- Shell completion covers the command, selectors, and tree flags where
  applicable.
- Smokey tests cover full-tree output, selected-subtree output, done filtering,
  and the `Refinement` milestone example.

# Comments

- 2026-08-10: Added after dogfooding showed that `list` is too flat for
  milestone planning and refinement review.

# Outcome
