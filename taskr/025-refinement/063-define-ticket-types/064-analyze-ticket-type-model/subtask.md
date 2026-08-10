---
title: Analyze ticket type model
status: designing
created_at: 2026-08-10T13:04:29Z
updated_at: 2026-08-10T13:04:29Z
---

# Description

Analyze the data model and semantics for ticket types.

# Acceptance

- The analysis defines the difference between item role and ticket type.
- The analysis compares possible type vocabularies such as `bug`, `feature`,
  `addon`, `task`, `chore`, or project-configurable values.
- The analysis proposes where ticket type is stored without duplicating
  directory-derived hierarchy.
- The analysis covers default behavior for existing items without a ticket
  type.
- The analysis covers validation, unknown types, case sensitivity,
  normalization, and migration of existing dogfood data.
- The analysis covers selector ambiguity, completion, search, tags/labels, and
  reporting interactions.
- The analysis explains whether ticket types are global, project-local, or
  personal-config driven.

# Comments

- 2026-08-10: Split from `063-define-ticket-types` as the model analysis
  subtask.

# Outcome
