---
title: Load mounted roots for read-only views
status: designing
created_at: 2026-08-25T16:28:12Z
updated_at: 2026-08-25T16:28:12Z
designing_at: 2026-08-25T16:28:12Z
---

# Description

Load configured mounted roots into read-only command surfaces so mounted items
can be inspected alongside local items without mutating either root.

Initial read-only surfaces: `list`, `tree`, `show`, and selector resolution.
Mounted item identity must include the mount identifier, for example
`vendor:003` or `vendor:workflow`, so local and mounted ID/slug collisions do
not become ambiguous when the prefixed selector is used.

# Acceptance

- Configured read-only mounted roots are loaded for `list`, `tree`, and `show`.
- Mounted rows display a stable mount identifier.
- Local selectors keep their current behavior.
- Prefixed mounted selectors resolve mounted IDs and slugs.
- Ambiguity errors include enough local/mount identity to choose a selector.
- `list --glob`, `list --tags`, and `--under` behavior for mounted roots is
  explicitly tested or explicitly deferred.
- Unavailable mounted roots fail with a clear diagnostic unless a later ticket
  defines degraded read-only behavior.
- Smokey covers local/mounted ID collision and prefixed selector success.

# Comments

- 2026-08-25: Depends on the schema and selector contract from 107.

# Outcome
