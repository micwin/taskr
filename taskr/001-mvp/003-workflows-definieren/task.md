---
title: Define workflows
status: done
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Describe the user-visible flows for initializing roots, creating items, listing
work, showing details, marking work done, validating with doctor, and archiving.

# Acceptance

- MVP workflows are documented from the user's point of view.
- Each workflow names the command sequence, expected output shape, and failure cases.
- Completion propagation from subtasks to tasks to milestones is described.
- Archive behavior is described without requiring extra metadata in item markers.
- Workflow notes are specific enough to derive CLI commands and Smokey tests.
- Workflows can be completed with only the Taskr CLI and a text editor, without
  duplicating the same information in multiple places.

# Comments

- 2026-06-03: Use `doc/taskr-worktree-format.md` as the fixed outcome from
  `002-verzeichnisstruktur` when defining workflows.
- 2026-06-03: Keep this ticket at workflow level. Concrete command names,
  arguments, and flags belong to `004-erste-kommandos`.
- 2026-06-03: Promoted the decided workflows into `doc/taskr-workflows.md` so
  command definition and tests can reference them.

# Outcome

The MVP workflows are defined in `doc/taskr-workflows.md`.

The command-definition ticket `004-erste-kommandos` must derive concrete Cobra
commands, arguments, flags, outputs, and exit codes from that workflow
document.
