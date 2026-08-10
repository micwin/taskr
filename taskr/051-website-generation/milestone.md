---
title: Website generation
status: designing
created_at: 2026-08-10T10:37:03Z
updated_at: 2026-08-10T10:37:03Z
---

# Description

Define and implement Taskr website generation so a Taskr root can produce a
static, browsable project site from its milestones, tasks, subtasks, reports,
comments, outcomes, and related files.

# Acceptance

- The generated site preserves Taskr semantics without requiring duplicated
  metadata outside the marker files and directory tree.
- The scope distinguishes static generation from future live/server-backed
  views.
- The milestone defines tasks for command design, templates/theme behavior,
  generated content structure, asset handling, documentation, and tests.
- Generated output never changes the Taskr source database unless explicitly
  requested by a command.
- Documentation, help, examples, and completion requirements are captured for
  user-visible commands and flags.
- Smokey coverage is planned for the full website generation workflow using
  dedicated fixtures.

# Comments

- 2026-08-10: Added as a separate milestone because website generation is a
  larger product surface than a single refinement task.

# Outcome
