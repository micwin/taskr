---
title: Validate mounted roots in doctor
status: designing
created_at: 2026-08-25T16:28:13Z
updated_at: 2026-08-25T16:28:13Z
designing_at: 2026-08-25T16:28:13Z
---

# Description

Extend `taskr doctor` so it validates mounted-root configuration and reports
mounted-root problems with the mount identifier.

# Acceptance

- `doctor` validates mount configuration syntax, duplicate mount identifiers,
  invalid modes, and invalid paths.
- `doctor` validates that each configured mounted path is a Taskr root unless a
  later degraded-mode policy says otherwise.
- Local-root errors and mounted-root errors are distinguishable in diagnostics.
- Mounted-root item validation reports the mount identifier.
- The strictness of unavailable mounted roots is documented.
- Smokey covers invalid config, missing mounted root, and a mounted root with a
  doctor-detectable structural error.

# Comments

- 2026-08-25: Depends on the schema from 107.

# Outcome
