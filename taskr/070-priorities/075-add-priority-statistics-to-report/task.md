---
title: Add priority statistics to report
status: designing
created_at: 2026-08-10T14:41:19Z
updated_at: 2026-08-10T14:41:19Z
designing_at: 2026-08-10T14:41:19Z
---

# Description

Add effective task-priority statistics to the repository report.

# Acceptance

- The default report includes counts of tasks with effective priority `high`,
  `normal`, and `low`.
- Tasks without stored priority count as `normal`.
- Priority counts are available for the repository summary and each milestone
  section where task status counts are already shown.
- Milestones and subtasks are excluded from priority counts.
- Priority statistics do not alter status statistics or current-work
  selection.
- Report headings and row wording make the counted task scope explicit.
- Help, workflow documentation, examples, and Smokey fixtures cover non-zero
  counts, omitted/default priority, empty milestones, and deterministic output.

# Comments

- 2026-08-10: Reporting is separated from list/tree ordering so its output can
  be reviewed independently.

# Outcome
