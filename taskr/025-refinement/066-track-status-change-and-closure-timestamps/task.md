---
title: Track status transition timestamps
status: developing
created_at: 2026-08-10T13:49:39Z
updated_at: 2026-08-10T13:49:39Z
---

# Description

Record when an item was last changed by a status operation and when it most
recently entered each status. The current `status` command changes only
`status`, leaving `updated_at` unchanged and providing no transition timing.

Transition timestamps are marker metadata. They must not be derived from Git
history or filesystem modification times.

# Acceptance

- Every successful `taskr status` change sets `updated_at` to the current UTC
  timestamp.
- Every supported status has a corresponding optional timestamp field:
  `open_at`, `designing_at`, `developing_at`, `active_at`, `reviewing_at`,
  `blocked_at`, `done_at`, and `cancelled_at`.
- A successful status transition sets the target status's `*_at` field to the
  current UTC timestamp.
- If an item enters a status more than once, its `*_at` field records the most
  recent entry into that status.
- Changing an item from `done` or `cancelled` to a non-closed status also sets
  `reopened_at` to the current UTC timestamp.
- If an item is reopened more than once, `reopened_at` records the most recent
  reopening.
- Repeating the current status does not silently manufacture a new change or
  transition timestamp; exact no-op behavior and output are documented.
- All status timestamp fields and `reopened_at` are optional. Existing markers
  and markers with incomplete historical timestamps remain valid and usable.
- When present, transition timestamps must use the same timestamp format as
  `created_at` and `updated_at`.
- Marker parsing, `show --meta`, doctor validation, help, workflow
  documentation, and examples reflect the timestamp behavior where relevant.
- Smokey tests cover ordinary status changes, repeated entry into a status,
  both closed statuses, reopening, missing historical timestamps, timestamp
  format, and the agreed no-op behavior.

# Comments

- 2026-08-10: Created after closing ticket `040` exposed that Taskr records
  neither the closure time nor an updated `updated_at` value during status
  changes.
- 2026-08-10: Refined to store the most recent entry time for every status and
  the most recent reopening time. Missing transition history remains valid for
  compatibility with existing markers.
- 2026-08-10: Timestamp assertions were added beside existing status-transition
  workflow checks. The central status workflow now also exercises the missing
  target statuses so every supported `*_at` field and `reopened_at` is covered.

# Outcome
