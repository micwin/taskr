---
title: Clarify show and report command semantics
status: designing
created_at: 2026-08-10T09:45:12Z
updated_at: 2026-08-10T09:45:12Z
---

# Description

Clarify the intended semantics of `show` and `report`. `show` is for one whole
ticket and should display the ticket content, including comments and outcome,
on the console. `report` is for summaries across multiple tickets and should
remain focused on multi-item views.

Detailed behavior is split into subtasks so `show` and `report` can be refined
and implemented independently.

# Acceptance

- A subtask exists for the clarified `show` command behavior.
- A subtask exists for the clarified `report` command behavior.
- The parent ticket stays focused on command responsibility boundaries.
- Implementation can proceed one subtask at a time.

# Comments

- 2026-08-10: Added after checking that current `show` prints only metadata.
  Intended behavior is that `show` displays a whole ticket. The compact output
  can move behind `--meta`.
- 2026-08-10: `report` is a multi-ticket command and should not be stretched
  into the primary single-ticket content viewer.
- 2026-08-10: Split into subtasks `041` for `show` and `042` for `report`.
  `--meta` means actual marker metadata, not a short display. A future `--short`
  mode can be considered separately.

# Outcome
