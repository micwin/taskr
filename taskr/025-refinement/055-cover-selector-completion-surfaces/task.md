---
title: Cover selector completion surfaces
status: designing
created_at: 2026-08-10T11:31:47Z
updated_at: 2026-08-10T11:31:47Z
---

# Description

Extend Smokey coverage so every command argument or flag that accepts a Taskr
item selector is tested for ID and slug shell completion. The implementation
already uses shared selector completion helpers, but tests currently cover only
representative surfaces.

# Acceptance

- Smokey tests assert selector completion by ID and slug for `comment
  <selector>`.
- Smokey tests assert selector completion by ID and slug for `show <selector>`.
- Smokey tests assert selector completion by ID and slug for `tree [selector]`.
- Smokey tests assert selector completion by ID and slug for `status
  <selector>`.
- Smokey tests assert selector completion by ID and slug for `move <selector>`.
- Smokey tests assert selector completion by ID and slug for `open <selector>`.
- Smokey tests assert selector completion by ID and slug for `archive
  <selector>`.
- Smokey tests assert selector completion by ID and slug for `create --under`,
  `list --under`, `move --under`, and `report --under`.
- The tests keep using dedicated Smokey fixtures and do not depend on the
  Taskr dogfood database.
- `AGENTS.md` states that every new or changed command argument or flag that
  accepts Taskr IDs or slugs must wire shell completion for those values.
- `AGENTS.md` states that Smokey must test completion at the exact command
  argument or flag surface where IDs or slugs are accepted, not only through a
  representative shared helper.
- Documentation/help changes are only needed if the tests expose a mismatch in
  current behavior.

# Comments

- 2026-08-10: Added after confirming that all selector surfaces use the shared
  selector completion helper, while Smokey only checks `show` and
  `create --under` directly.
- 2026-08-10: Expanded to include an agent policy rule requiring completion and
  exact-surface Smokey coverage for every ID/slug selector surface.

# Outcome
