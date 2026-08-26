---
title: List mounted roots
status: reviewing
created_at: 2026-08-25T17:20:19Z
updated_at: 2026-08-25T20:15:42Z
designing_at: 2026-08-25T17:20:19Z
developing_at: 2026-08-25T18:23:10Z
reviewing_at: 2026-08-25T20:15:42Z
---

# Description

Extend `taskr list` so mount objects and mounted items can appear in list
output with clear source identity.

# Acceptance

- `taskr list --type mount` lists virtual mount objects.
- Mount object rows use `id mount <mode> <name>` and show the configured
  mount mode (`read-only` or `read-write`) where normal item rows show status.
  Mount objects do not show Taskr lifecycle status values.
- Default `taskr list` includes mount objects in the root-level overview.
- Transitive mount objects are listed with qualified mount IDs such as
  `vendor:lib`.
- Transitive mount object rows show the configured mode of that mount entry.
  Effective writeability is constrained by the complete mount chain and belongs
  to mutation and doctor behavior.
- Mounted items use ID-prefixed identity such as `vendor:003`.
- Mounted item rows do not collide with local rows that share numeric IDs or
  slugs.
- Existing list filters keep their local behavior and explicitly include or
  exclude mounted items according to the 099 contract.
- `--glob` and `--tags` cover mounted items.
- Unavailable mounted roots fail clearly.
- Help, docs, examples, and shell completion reflect mount list behavior.
- Smokey covers listing mount objects with modes instead of statuses,
  transitive mount objects, mounted items, ID collisions, `--glob`, `--tags`,
  and unavailable mounts.

# Comments

- 2026-08-25: List-specific slice of ticket 099.

# Outcome

List output now includes virtual mounts, transitive mounts, and qualified items;
mount rows display access mode instead of lifecycle status.

# Release Notes

`taskr list` displays mounted roots and their source-qualified items.
