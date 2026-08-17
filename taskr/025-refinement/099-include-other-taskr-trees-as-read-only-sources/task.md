---
title: Include other Taskr trees as read-only sources
status: designing
created_at: 2026-08-17T07:23:50Z
updated_at: 2026-08-17T07:23:50Z
designing_at: 2026-08-17T07:23:50Z
---

# Description

Analyze support for including other Taskr roots as read-only sources. Included
trees could provide external tickets, milestones, references, search results, or
context without allowing local commands to mutate those external items.

This likely introduces a more general read-only item model and must define how
selectors, listing, reports, generated sites, and write commands distinguish
local writable items from imported read-only items.

# Acceptance

- Define configuration for included Taskr roots.
- Decide whether included roots participate in selectors, list/report output,
  generated sites, references, or search.
- Define read-only behavior for mutating commands and useful error messages.
- Clarify identity and collision handling between local and included items.
- Identify whether this needs separate subtickets for read-only items and
  included roots.
- Identify Smokey coverage before implementation begins.

# Comments

- 2026-08-17: Added while discussing references between Taskr trees and the
  possibility of read-only imported tickets.

# Outcome
