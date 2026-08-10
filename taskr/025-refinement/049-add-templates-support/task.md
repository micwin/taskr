---
title: Add templates support
status: designing
created_at: 2026-08-10T10:35:05Z
updated_at: 2026-08-10T10:35:05Z
---

# Description

Add template support for generated Taskr items so new milestone, task, and
subtask markers can be created from configurable Markdown/frontmatter
templates instead of only the built-in default skeleton.

# Acceptance

- Taskr can resolve templates for supported item types without duplicating
  structural information that is already derived from the directory tree.
- Template lookup distinguishes personal configuration from project-local Taskr
  roots.
- Built-in templates remain available when no custom template is configured.
- Created items still contain the required marker file, frontmatter, and
  required H1 sections.
- Template rendering fills standard fields such as title, status, created time,
  and updated time.
- Invalid templates fail with clear errors before a broken item is written.
- Documentation, help, examples, and completion are updated if templates add
  commands, flags, or config keys.
- Smokey tests cover built-in template creation, custom template creation, and
  invalid template handling.

# Comments

- 2026-08-10: Added as a refinement topic for making generated dogfood and
  user project items less hard-coded while preserving the current file format
  rules.

# Outcome
