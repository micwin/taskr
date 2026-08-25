---
title: Normalize built-in status lifecycle
status: designing
created_at: 2026-08-10T17:07:29Z
updated_at: 2026-08-10T17:07:29Z
designing_at: 2026-08-10T17:07:29Z
---

# Description

Normalize Taskr's built-in status vocabulary and ordering before strict
transition validation or configurable workflows are implemented.

The current model exposes both `open` and `active` without a clear lifecycle
distinction. Rename the initial `open` state to `new`, remove the redundant
`active` status, and define one canonical status order for storage, help,
completion, reports, filters, documentation, fixtures, and agent policy.

A possible post-delivery concept such as `productive` is explicitly outside
the built-in lifecycle. It may be analyzed later as a tag, label, or separate
flag without making every Taskr item pass through a production-specific state.

# Acceptance

- The built-in lifecycle starts with `new` instead of `open`.
- The analysis documents that `active` historically meant generic ongoing work
  before `developing` existed.
- `active` is removed from the built-in status model, validation, storage,
  help, examples, completion, reports, filters, documentation, agent policy,
  dogfood data, and committed fixtures.
- Migration explicitly maps existing `status: active` and `active_at` data to
  appropriate normalized lifecycle values and timestamps; the mapping may
  account for item role and current work phase.
- One canonical ordering is defined for all built-in statuses.
- The design decides how the orthogonal `blocked` condition participates in
  ordering and transitions instead of pretending it is an ordinary linear
  phase without discussion.
- Initial status behavior for newly created milestones, tasks, and subtasks is
  defined consistently.
- Migration rules cover existing `status: open`, `open_at`, `status: active`,
  `active_at`, and all affected dogfood and committed fixture data.
- Backwards compatibility is explicit: old names are either rejected with a
  migration diagnostic, accepted temporarily as aliases, or migrated by a
  documented command.
- Status timestamps, including `new_at`, status-specific `*_at` fields, and
  `reopened_at`, remain coherent after migration.
- Status ordering is applied consistently in `status`, `create`, `list`,
  `tree`, `show`, `report`, Doctor, archive checks, help, examples, shell
  completion, and any public API.
- Default config, personal config behavior, project documentation,
  `AGENTS.md`, dogfood markers, and Smokey fixtures use the normalized names.
- Report summaries and extremes preserve their intended meaning after status
  migration.
- The relationship to ticket `048` transition validation is explicit; strict
  transitions must use the normalized built-in lifecycle.
- The relationship to ticket `059` configurable workflows is explicit; the
  normalized lifecycle becomes the default when no custom workflow exists.
- `productive` is not introduced as a status by this ticket. Any later
  production or delivery indicator is tracked as an orthogonal tag, label, or
  flag feature with its own filter and report semantics.
- Smokey tests cover creation, every normalized status value, ordering,
  filtering, reporting, completion, Doctor diagnostics, migration behavior,
  and rejection or compatibility behavior for legacy values before
  implementation starts.

# Comments

- 2026-08-10: Added after README review exposed both `open` and `active` in the
  built-in status list. The intended initial name is `new`; the remaining
  lifecycle order and the fate of `active` require explicit refinement.
- 2026-08-10: Historical review confirmed that `active` meant generic ongoing
  work and predates the more precise `developing` status; it must be removed.
  A possible `productive` concept stays outside the lifecycle and may later be
  represented through tags, labels, or a separate flag.

# Outcome
