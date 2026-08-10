---
title: Analyze priorities
status: designing
created_at: 2026-08-10T12:35:20Z
updated_at: 2026-08-10T12:35:20Z
---

# Description

Analyze how Taskr should represent and use item priorities without conflating
priority with status, hierarchy, dependencies, or scheduling.

The design should decide whether priority is a simple ordered value, a
project-configurable scale, a label-like marker, or a report-only annotation.

# Acceptance

- The analysis defines what priority means in Taskr and how it differs from
  status, dependencies, milestones, and ordering in the directory tree.
- The analysis compares possible priority models, such as numeric values,
  named levels, project-configured scales, or no built-in priority.
- The analysis proposes where priority is stored without duplicating hierarchy
  or role information.
- The analysis covers filtering and sorting in `list`, `tree`, and `report`.
- The analysis covers whether priority affects `status`, `archive`, `doctor`,
  completion, examples, and future website generation.
- The analysis covers default behavior for items without a priority.
- The analysis covers validation, invalid values, case sensitivity, and
  migration of existing dogfood data.
- The analysis identifies Smokey coverage requirements before implementation.
- No priority implementation is added until the design is accepted.

# Comments

- 2026-08-10: Added while collecting refinement ideas after configurable
  workflows and tags/labels. Priority needs separate design because it may
  influence sorting and reporting but should not silently change lifecycle
  semantics.

# Outcome
