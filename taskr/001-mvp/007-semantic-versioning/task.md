---
title: Introduce semantic versioning
status: designing
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Define version source, version command output, tag format, and release version
rules.

# Acceptance

- Version numbers follow semantic versioning.
- `taskr version` reports the application version in a stable format.
- Build metadata can be injected during release builds.
- Git tag naming and release branch naming are documented.
- Smokey or unit coverage verifies the version command output.

# Comments

- 2026-06-03: Versioning belongs in MVP because release artifacts need stable
  names.

# Outcome
