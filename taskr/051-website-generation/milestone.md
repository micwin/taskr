---
title: Website generation
status: designing
created_at: 2026-08-10T10:37:03Z
updated_at: 2026-08-10T10:37:03Z
---

# Description

Define and implement website generation for projects managed by Taskr, similar
in spirit to Maven's `site` command. A Taskr root should be able to produce a
static, browsable project site from that project's milestones, tasks, subtasks,
reports, comments, outcomes, and related files.

# Acceptance

- The generated site represents the managed project, not a marketing or
  documentation website for Taskr itself.
- The generated site preserves Taskr project semantics without requiring
  duplicated metadata outside the marker files and directory tree.
- The scope distinguishes static generation from future live/server-backed
  views.
- The initial command surface contains `taskr site init <site-directory>` for
  project-local setup, argument-free `taskr site generate` for persistent
  static output, and `taskr site open` for browser preview of that configured
  output.
- The milestone defines tasks for command design, templates/theme behavior,
  generated content structure, asset handling, documentation, and tests.
- Generated output never changes the Taskr source database unless explicitly
  requested by a command.
- Documentation, help, examples, and completion requirements are captured for
  user-visible commands and flags.
- Smokey coverage is planned for the full website generation workflow using
  dedicated fixtures.

# Comments

- 2026-08-10: Added as a separate milestone because project website generation
  is a larger product surface than a single refinement task.
- 2026-08-10: Clarified that the feature generates a site for the project
  managed by a Taskr root, comparable to `mvn site`, not a website for Taskr
  itself.
- 2026-08-10: Split the initial command workflow into persistent generation and
  immediate temporary browser preview, tracked by tasks `081` and `082`.
- 2026-08-10: Revised the workflow to initialize one persistent site directory.
  Tasks `085`, `081`, and `082` cover initialization, generation, and preview
  and are intended to be specified and implemented as one coherent feature.
- 2026-08-10: Project-local feature configuration starts with root-level
  `taskr.toml`; subtask `086` defines its reusable contract and `[site]` is the
  first table.

# Outcome
