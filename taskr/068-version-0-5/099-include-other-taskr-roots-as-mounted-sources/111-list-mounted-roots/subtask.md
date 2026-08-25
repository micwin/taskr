---
title: List mounted roots
status: designing
created_at: 2026-08-25T17:20:19Z
updated_at: 2026-08-25T17:20:19Z
designing_at: 2026-08-25T17:20:19Z
---

# Description

Extend `taskr list` so mount objects and mounted items can appear in list
output with clear source identity.

# Acceptance

- `taskr list --type mount` lists virtual mount objects.
- Default `taskr list` includes mount objects in the root-level overview.
- Mounted items use ID-prefixed identity such as `vendor:003`.
- Mounted item rows do not collide with local rows that share numeric IDs or
  slugs.
- Existing list filters keep their local behavior and explicitly include or
  exclude mounted items according to the 099 contract.
- `--glob` and `--tags` cover mounted items.
- Unavailable mounted roots fail clearly.
- Help, docs, examples, and shell completion reflect mount list behavior.
- Smokey covers listing mount objects, mounted items, ID collisions, `--glob`,
  `--tags`, and unavailable mounts.

# Comments

- 2026-08-25: List-specific slice of ticket 099.

# Outcome
