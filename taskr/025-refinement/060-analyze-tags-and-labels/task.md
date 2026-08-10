---
title: Analyze tags and labels
status: designing
created_at: 2026-08-10T12:33:35Z
updated_at: 2026-08-10T12:33:35Z
---

# Description

Analyze how Taskr should support tags or labels on items, including search,
filtering, completion, and whether labels may participate in selector-like
targeting.

The design must decide whether tags are only metadata for filtering and reports
or whether they can be used like slugs/IDs in commands such as `show`, `list`,
`report`, `move`, `create --under`, or other selector surfaces.

# Acceptance

- The analysis defines the difference, if any, between tags and labels.
- The analysis proposes where tags/labels are stored without duplicating
  hierarchy or role information.
- The analysis covers search and filter behavior, including possible flags such
  as `--tag`, `--label`, or selector syntax.
- The analysis covers whether tags/labels can be used as command targets, and
  if so how ambiguity is handled.
- The analysis covers how tags/labels interact with slugs, IDs, title matching,
  and selector precedence.
- The analysis covers `--under` behavior and whether tags/labels can identify a
  parent target or only filter candidate sets.
- The analysis covers shell completion for tags/labels and for commands that
  accept item IDs or slugs.
- The analysis covers `tree`, `list`, `report`, `show`, `doctor`, `move`,
  `create`, archive behavior, and future website generation.
- The analysis covers invalid tags, renamed tags, missing targets, case
  sensitivity, and tag normalization.
- The proposed MVP behavior keeps command targets unambiguous and avoids
  surprising movement or creation under multiple tagged items.
- Smokey coverage requirements are identified before implementation.

# Comments

- 2026-08-10: Added while discussing selector and workflow refinements. Tags
  may be useful for search and reporting, but using them as command targets
  could collide with slug/ID selector semantics and needs separate design.

# Outcome
