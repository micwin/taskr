---
title: Cross-platform support
status: designing
created_at: 2026-08-10T18:05:42Z
updated_at: 2026-08-10T18:05:42Z
designing_at: 2026-08-10T18:05:42Z
---

# Description

Track Taskr portability work that is intentionally scheduled after Version
0.5. The milestone starts with a standalone Windows executable and the runtime
compatibility work required to make that artifact meaningful.

# Acceptance

- Cross-platform work is scoped independently of the Version 0.5 milestone.
- Each supported platform has explicit build, dependency, runtime, test,
  documentation, and release-artifact requirements.
- A successful cross-compile alone is not treated as complete platform support.
- Unsupported platform behavior fails clearly instead of silently assuming a
  Unix environment.

# Comments

- 2026-08-10: Created after Windows executable work was explicitly deferred
  beyond Version 0.5. Task `083` is the first scoped item.

# Outcome
