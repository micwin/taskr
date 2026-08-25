---
title: Generate site with mounted roots
status: developing
created_at: 2026-08-25T17:20:21Z
updated_at: 2026-08-25T19:04:17Z
designing_at: 2026-08-25T17:20:21Z
developing_at: 2026-08-25T19:04:17Z
---

# Description

Extend `taskr site generate` and `taskr site open` output so generated sites
include mount objects and mounted items.

# Acceptance

- Generated site data includes mount objects.
- Generated site data includes mounted items with mount-ID-prefixed identity.
- Site overview displays mounted roots.
- Site search finds mounted IDs, slugs, titles, and tags without colliding with
  local identity.
- Site status/tag filters include mounted items.
- Displayed IDs of mounted milestones, tasks, and subtasks provide an
  additional clickable mount-ID segment. Activating that segment opens the
  shared results page with a mount filter/search context that lists every
  milestone, task, and subtask from that mounted root.
- Mount-filter result pages include the mounted root's transitive mounted
  roots and their items, using the same identity semantics as `list` and
  `tree`.
- Multiple result pages or browser tabs keep their mount filter context in the
  URL, not in shared browser storage.
- Ticket pages for mounted items show source identity.
- Unavailable mounts fail clearly during generation/open regeneration.
- Help, docs, and examples cover generated sites with mounts.
- Smokey covers generated data, overview presence, search data, filters, item
  page links, transitive mounts, cycles, and unavailable mount failure.

# Comments

- 2026-08-25: Site-specific slice of ticket 099.
- 2026-08-25: Mounted item IDs should expose the mount-id part as a separate
  clickable filter affordance. The item link still opens the item; the mount
  link opens the shared results page scoped to that mount and includes
  transitive mounted content.

# Outcome
