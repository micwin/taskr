---
title: Priorities
status: designing
created_at: 2026-08-10T14:41:10Z
updated_at: 2026-08-10T14:41:10Z
designing_at: 2026-08-10T14:41:10Z
---

# Description

Introduce a deliberately small priority model for tasks. Priority exists only
to influence task ordering, filtering, grouping, reporting, and selected
display surfaces. It does not affect lifecycle, hierarchy, dependencies, or
completion.

# Acceptance

- Priority supports exactly `high`, `normal`, and `low` for tasks.
- Missing stored priority is interpreted as `normal` without rewriting existing
  markers.
- Data model, mutation, list, tree, and report work are tracked independently.
- All priority behavior is covered by readable Smokey workflows before the
  milestone is closed.
- Help, completion, documentation, examples, Doctor, and `show --meta` remain
  consistent with the implemented command surface.

# Comments

- 2026-08-10: Created from analysis ticket `061`, which remains in the Version
  0.5 milestone and coordinates this implementation milestone.

# Outcome
