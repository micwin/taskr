---
title: Clarify report command
status: designing
created_at: 2026-08-10T09:48:33Z
updated_at: 2026-08-10T09:48:33Z
---

# Description

Clarify and implement `report` as a repository-level report command. `report`
is not the single-item viewer; it produces a report about the whole Taskr root
by default, with switches controlling which content and sections are included.

# Acceptance

- `taskr report` is documented as a repository report command.
- Default report output includes the project/root name.
- Default report output includes the report date.
- Default report output includes statistics for milestones, tasks, and subtasks
  by status: `open`, `designing`, `developing`, `reviewing`, `done`, and
  `cancelled`.
- Default report output includes the oldest item per non-closed status and the
  newest item for `done` and `cancelled`, where such items exist.
- Default report output includes one section per milestone, headed by milestone
  name and slug.
- Each milestone section includes counts of child tickets by status.
- Each milestone section lists tickets currently in `developing` or
  `reviewing`.
- Report filters and switches can control what appears in the report, but must
  preserve the repository-report role of the command.
- `report` does not become the primary way to inspect one item's complete
  marker text.
- If report gains detail flags later, they are explicitly scoped to multi-item
  reporting.
- Help documents the repository-report role of `report`.
- Smokey tests cover the default repository report, report date, status
  statistics, milestone sections, developing/reviewing ticket lists, and
  filtered report output.

# Comments

- 2026-08-10: Split from parent `040`. `report` is for summaries over sets of
  items; `show` is the single-item content viewer.
- 2026-08-10: User clarified the default report content: project name, report
  date, status statistics for milestones/tasks/subtasks, oldest open-ish items,
  newest done/cancelled items, and milestone sections with status counts plus
  developing/reviewing ticket lists.

# Outcome
