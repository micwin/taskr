---
title: Add priority statistics to report
status: done
created_at: 2026-08-10T14:41:19Z
updated_at: 2026-08-10T15:53:17Z
designing_at: 2026-08-10T14:41:19Z
developing_at: 2026-08-10T15:22:35Z
reviewing_at: 2026-08-10T15:30:41Z
done_at: 2026-08-10T15:53:17Z
---

# Description

Add effective task-priority statistics to the repository report.

# Acceptance

- The default report includes counts of tasks with effective priority `high`,
  `normal`, and `low`.
- Tasks without stored priority count as `normal`.
- Priority counts are available for the repository summary and each milestone
  section where task status counts are already shown.
- Repository output uses `# Task Priority Summary`; milestone sections use
  `### Task Priority Counts`.
- Count rows use `tasks with effective priority "<value>": <count>` in stable
  `high`, `normal`, `low` order.
- Milestones and subtasks are excluded from priority counts.
- Priority statistics do not alter status statistics or current-work
  selection.
- Report headings and row wording make the counted task scope explicit.
- Help, workflow documentation, examples, and Smokey fixtures cover non-zero
  counts, omitted/default priority, empty milestones, and deterministic output.

# Comments

- 2026-08-10: Reporting is separated from list/tree ordering so its output can
  be reviewed independently.
- 2026-08-10: No report flags are added. Priority counts are part of the default
  top-level report, while empty milestones remain only in the existing empty
  milestone section.

# Outcome

The default repository report now includes deterministic effective task
priority counts in global and populated milestone sections. Omitted priority is
counted as normal; milestones and subtasks are excluded. Empty milestones keep
their existing dedicated section, while status summaries and current-work
selection remain unchanged. Help, workflow documentation, and the shared
end-to-end Priority Smokey workflow cover the final report behavior.
