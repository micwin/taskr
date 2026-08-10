---
title: Switch marker storage format to XML
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Change only the on-disk marker file storage format from Markdown with YAML
frontmatter to XML. The Taskr worktree model, item roles, directory naming,
selectors, commands, status semantics, and user workflows should stay the same
unless this ticket is explicitly expanded during refinement.

# Acceptance

- The XML marker format is specified for milestones, tasks, subtasks, and file
  containers.
- Existing logical fields are preserved: title, status, created timestamp,
  updated timestamp, description, acceptance, comments, and outcome.
- The directory structure continues to define item role through marker
  filename and parent/child hierarchy through paths.
- The change does not introduce duplicated role, ID, or parent data inside the
  marker content.
- A migration path from current Markdown marker files to XML is defined before
  implementation.
- Command behavior remains unchanged except for reading and writing XML marker
  files.
- Existing command stdout/stderr output remains unchanged unless a command
  explicitly prints marker source content by design.
- XML markup must not leak into normal CLI output, reports, errors, completion,
  or help text by accident.
- Doctor validation is updated to validate XML marker files and report format
  errors clearly.
- Help, examples, docs, completion, and Smokey fixtures/tests are updated where
  the marker format is visible.

# Comments

- 2026-08-10: This is intentionally scoped to storage format only. It should
  not change Taskr's command model or worktree hierarchy.

# Outcome
