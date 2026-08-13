---
title: Record chronological item change history
status: designing
created_at: 2026-08-13T13:48:26Z
updated_at: 2026-08-13T13:48:30Z
designing_at: 2026-08-13T13:48:30Z
---

# Description

Design a chronological, machine-readable change history for Taskr items. The
history records item lifecycle and mutation events such as item creation,
status changes, added comments, moves, renames, priority changes, and later
supported item operations.

The initial design must compare at least two storage models: one flat history
file for the complete Taskr root and an append-only log section inside each
item marker. The decision must preserve Taskr's local-first, editor-compatible
workflow without duplicating current item state as another source of truth.

# Acceptance

- The design defines which Taskr operations create history events and which
  direct editor changes can or cannot be represented reliably.
- Every event has a stable chronological order and enough timestamp precision
  to distinguish multiple changes made on the same day or within one workflow.
- The design evaluates a single flat root-level history file against one
  append-only history section per item, including readability, merge behavior,
  archival and move behavior, atomic writes, query cost, and corruption scope.
- History records facts about changes without becoming a second canonical copy
  of current status, title, parent, priority, or marker content.
- Event records identify the affected item stably even when its directory,
  slug, title, or parent changes.
- The interaction with existing `created_at`, `updated_at`, status-specific
  timestamps, and `reopened_at` is clarified. Redundant timestamps are either
  justified or removed through a separately agreed migration.
- Retention, ordering after Git merges, legacy items without history, Doctor
  validation, and potential repair behavior are specified before
  implementation.
- CLI display and filtering requirements are discussed separately from the
  storage format; recording history does not automatically require a new
  presentation command in the same implementation ticket.
- Smokey scenarios are designed only after the storage and event contracts are
  agreed with the user.

# Comments

- 2026-08-13: Created as a refinement ticket. Candidate storage is either one
  flat chronological file for the Taskr root or a log section at the bottom of
  every item marker; no storage decision has been made yet.
- 2026-08-13: Known initial events include ticket creation, status changes, and
  added comments. Moves, renames, priority changes, and future mutation
  commands must be considered for a consistent event model.

# Outcome
