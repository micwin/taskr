---
title: MVP
status: done
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Deliver the first useful Taskr loop: local root discovery, Markdown marker
storage, command workflows, Smokey coverage, implementation, and release path.

# Acceptance

- A user can initialize or discover a local Taskr root without a root manifest.
- A user can create, inspect, list, and complete milestone/task/subtask items.
- Parent completion is derived from child completion.
- `taskr doctor` rejects invalid directory structures and invalid markers.
- The full MVP workflow is covered by directory-based Smokey tests.
- Local release versioning and packaging are documented and wired. GitHub
  release publishing is tracked separately under the `GitHub integration`
  milestone.

# Comments

- 2026-06-03: MVP starts at the milestone layer. Project and epic roles are out
  of scope until milestone/task/subtask works well.

# Outcome

MVP delivered the first useful local Taskr loop: Markdown marker storage,
directory-derived hierarchy, local root discovery, create/show/list/tree/status
workflows, comments, reporting, moving, archiving, doctor checks, Smokey
coverage, semantic version/build metadata, Debian packaging, init, examples,
completion, and dogfood process rules. GitHub publishing work was intentionally
rescoped into the `GitHub integration` milestone.
