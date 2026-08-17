---
title: Support references inside tickets
status: designing
created_at: 2026-08-17T07:23:50Z
updated_at: 2026-08-17T07:23:50Z
designing_at: 2026-08-17T07:23:50Z
---

# Description

Define first-class references inside Taskr ticket content. References may point
to other Taskr items, repository files, or external URLs. The design should
clarify where references are written, how they are rendered by `show`, `report`,
and generated sites, and whether Taskr validates reachable targets.

# Acceptance

- Define syntax for references to Taskr items, files, and URLs.
- Decide whether references live in Markdown body text, frontmatter, a dedicated
  section, or a combination of these.
- Specify validation behavior for missing Taskr items and missing local files.
- Specify rendering behavior for CLI output, reports, and generated sites.
- Identify Smokey coverage before implementation begins.

# Comments

- 2026-08-17: Added while discussing tags and future project cross-linking.

# Outcome
