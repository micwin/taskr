---
title: Require Smokey tests to cite covered tickets
status: designing
created_at: 2026-08-25T17:38:00Z
updated_at: 2026-08-25T17:38:00Z
designing_at: 2026-08-25T17:38:00Z
---

# Description

Require Smokey test cases to state which Taskr ticket they protect.

Taskr's Smokey suites are executable workflow documentation. As the suite grows,
readers need to understand why a test exists without reconstructing the dogfood
history from git commits or ticket archaeology. Each meaningful test block
should name the ticket ID it covers in a nearby comment.

The rule applies to new and substantially changed Smokey tests immediately.
Existing Smokey tests must also be assigned to covered Taskr ticket IDs in a
follow-up pass, even when they are not otherwise being changed.

# Acceptance

- `AGENTS.md` documents that every new or substantially changed Smokey test
  block cites the covered Taskr ticket ID in a nearby comment.
- The guidance allows one comment to cover a coherent multi-assertion block.
- Existing Smokey tests are audited and assigned to covered Taskr ticket IDs.
- The retrofit may be done in a dedicated cleanup ticket if it would make this
  policy change too large.
- Tests added while this ticket is still open follow the rule immediately.

# Comments

- 2026-08-25: Added while preparing mounted-root tests for ticket 108. Michael
  asked that tests explain which ticket they protect.
- 2026-08-25: Existing tests must also be assigned to tickets after the policy
  is accepted; this is expected to generate follow-up work.

# Outcome
