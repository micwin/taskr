---
title: Clarify report command
status: done
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
  by status: `open`, `designing`, `developing`, `active`, `reviewing`, `done`,
  and `cancelled`.
- Default report output includes the oldest item per non-closed status and the
  newest item for `done` and `cancelled`, where such items exist.
- Default report output includes one section per milestone, headed by milestone
  name and slug.
- Each milestone section includes counts of child tickets by status.
- Each milestone section lists tickets currently in `developing` or
  `reviewing`.
- Report is initially top-level only; item selectors and status/type filters
  are rejected until their report semantics are deliberately designed.
- Default report output includes open milestones that do not yet contain
  tickets in a separate section.
- Repeated report rows do not include the item type when the surrounding
  heading already defines that context.
- Truncated lists include an explicit heading that states the visible count and
  the total count.
- `report` does not become the primary way to inspect one item's complete
  marker text.
- If report gains detail flags later, they are explicitly scoped to multi-item
  reporting.
- Help documents the repository-report role of `report`.
- Smokey tests cover the default repository report, report date, status
  statistics, milestone sections, developing/reviewing ticket lists, truncated
  list headings, open milestones without tickets, output files, and rejection
  of unsupported filters.

# Comments

- 2026-08-10: Split from parent `040`. `report` is for summaries over sets of
  items; `show` is the single-item content viewer.
- 2026-08-10: User clarified the default report content: project name, report
  date, status statistics for milestones/tasks/subtasks, oldest open-ish items,
  newest done/cancelled items, and milestone sections with status counts plus
  developing/reviewing ticket lists.
- 2026-08-10: Review feedback clarified that reports are initially top-level
  only, open milestones without tickets need their own section, repeated rows
  should avoid redundant type text, and truncated lists need headings that state
  the visible and total counts.

# Outcome

Implemented `taskr report` as a repository report. Default output now includes
project name, report date, status summary by item type, oldest non-closed items,
newest closed items, milestone sections with task status counts,
developing/reviewing ticket lists, and open milestones without tickets.
`--output` writes the same top-level report to a file. `--under`, `--type`, and
`--status` are intentionally not part of the initial report surface. Help,
workflow documentation, and Smokey coverage were updated.

Review feedback tightened the text format: report sections use explicit
headings, status counts use readable phrases such as `tasks with status
"designing": 3`, item lines omit redundant type text in typed sections, empty
open milestones are listed separately, and truncated current-work lists state
the visible count and total count in the heading.
