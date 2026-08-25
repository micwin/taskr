---
title: Generate site with mounted roots
status: designing
created_at: 2026-08-25T17:20:21Z
updated_at: 2026-08-25T17:20:21Z
designing_at: 2026-08-25T17:20:21Z
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
- Ticket pages for mounted items show source identity.
- Unavailable mounts fail clearly during generation/open regeneration.
- Help, docs, and examples cover generated sites with mounts.
- Smokey covers generated data, overview presence, search data, filters, item
  page links, transitive mounts, cycles, and unavailable mount failure.

# Comments

- 2026-08-25: Site-specific slice of ticket 099.

# Outcome
