---
title: Review Smokey fixtures for unnecessary special roots
status: designing
created_at: 2026-08-17T06:56:22Z
updated_at: 2026-08-17T06:56:22Z
designing_at: 2026-08-17T06:56:22Z
---

# Description

Review the Smokey suite for unnecessary or hidden fixture special cases. Tests
should use the shared fixture root when they exercise normal Taskr behavior.
Special roots remain appropriate for intentionally invalid structures,
filesystem edge cases, isolation of destructive workflows, release repositories,
or other cases where sharing the normal root would make the test misleading.

The goal is that a reader can quickly tell which tests operate on the common
Taskr world and which tests intentionally use a separate world, with the reason
visible near the test code.

# Acceptance

- Inventory Smokey tests that create or copy their own root fixtures.
- Classify each special root as necessary or unnecessary.
- Convert unnecessary special roots to the shared fixture root or a copy of it.
- Leave intentionally invalid or edge-case roots separate, with a short comment
  explaining why.
- Keep the resulting tests readable; do not replace fixture duplication with
  opaque setup logic.

# Comments

- 2026-08-17: Added after tag tests initially introduced a separate valid
  tag-root. The desired default is to enrich the shared valid fixture for normal
  behavior and reserve special roots for truly special conditions.

# Outcome
