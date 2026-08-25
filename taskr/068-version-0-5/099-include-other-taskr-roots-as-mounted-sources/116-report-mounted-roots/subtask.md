---
title: Report mounted roots
status: designing
created_at: 2026-08-25T17:20:20Z
updated_at: 2026-08-25T17:20:20Z
designing_at: 2026-08-25T17:20:20Z
---

# Description

Extend `taskr report` so repository reports include mounted roots and mounted
items with explicit source identity.

# Acceptance

- Reports include mount objects or a dedicated mounted-roots section.
- Mounted item counts and visible rows include mount identity.
- Local and mounted items with the same numeric ID or slug remain
  distinguishable.
- Report status, priority, and tag summaries include mounted items according to
  documented rules.
- Unavailable mounts fail clearly.
- Help, docs, and examples cover mounted report output.
- Smokey covers mounted report section/counts, local/mounted collision
  readability, tags, priorities, and unavailable mount failure.

# Comments

- 2026-08-25: Report-specific slice of ticket 099.

# Outcome
