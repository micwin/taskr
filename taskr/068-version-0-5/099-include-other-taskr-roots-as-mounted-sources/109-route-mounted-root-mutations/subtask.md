---
title: Route mounted root mutations
status: designing
created_at: 2026-08-25T16:28:13Z
updated_at: 2026-08-25T16:28:13Z
designing_at: 2026-08-25T16:28:13Z
---

# Description

Route supported mutating commands to mounted roots when a prefixed selector
targets a read-write mount, and reject mutations against read-only mounts.

The mounted root's files are the source of truth. Taskr must not create shadow
copies or duplicated marker data in the parent root.

# Acceptance

- Mutating commands against read-only mounted items fail clearly and leave both
  local and mounted roots unchanged.
- Mutating commands against read-write mounted items update files in the
  mounted root.
- Supported mutating commands are explicitly listed before implementation.
- Local-only commands remain local-only and reject mounted selectors clearly.
- Status transition, open-parent, timestamp, and release-note policies still
  apply when the target item lives in a read-write mounted root.
- Smokey covers at least one read-only rejection and one read-write mutation
  routed to the mounted root.

# Comments

- 2026-08-25: Depends on read-only selector loading from 108.

# Outcome
