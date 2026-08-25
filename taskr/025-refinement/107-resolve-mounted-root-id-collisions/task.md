---
title: Resolve mounted root ID collisions
status: designing
created_at: 2026-08-25T17:14:59Z
updated_at: 2026-08-25T17:14:59Z
designing_at: 2026-08-25T17:14:59Z
---

# Description

Analyze and design a user-controlled way to resolve mounted-root ID collisions
across transitive mount graphs.

Ticket 099 deliberately treats duplicate mount IDs across local and transitive
mounts as hard, non-fixable errors for the initial mounted-root implementation.
That keeps identity safe, but it also means a user cannot use two otherwise
valid external Taskr roots when their mount graphs contain the same mount ID.

Taskr needs a later mechanism that lets users resolve those collisions without
changing the external roots directly. Candidate approaches include local
aliases, temporary replacements, path-scoped ID rewrites, or another explicit
mapping stored in the parent root's `taskr.toml`.

The design must preserve stable selectors and avoid silent identity changes.
Any replacement or alias must be visible in displays, diagnostics, generated
sites, reports, completion, and mutating-command routing.

# Acceptance

- Describe the collision problem for transitive mounted roots with concrete
  examples.
- Compare at least aliases, temporary replacements, and path-scoped ID rewrites.
- Decide where collision-resolution mappings are stored.
- Define how resolved IDs appear in selectors, slugs, list, tree, show, report,
  generated sites, completion, and diagnostics.
- Define how read-only and read-write mounted roots interact with local alias
  or replacement mappings.
- Define whether mappings affect only the parent root view or are ever written
  into mounted roots.
- Define how `doctor` reports unresolved collisions and validates configured
  collision-resolution mappings.
- Define how `doctor --fix` behaves; it must not invent semantic replacement
  IDs automatically.
- Identify Smokey coverage needed before implementation.

# Comments

- 2026-08-25: Added after defining 099's baseline rule that transitive mount ID
  collisions are detected and rejected, but not fixable. Michael noted that the
  conflict must eventually be resolvable through temporary replacements,
  aliases, or a similar explicit mechanism.

# Outcome
