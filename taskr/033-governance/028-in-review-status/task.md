---
title: Add in_review status
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Introduce an `in_review` status between active development and `done` so work
can be implemented, tested, and reviewed before closure.

# Acceptance

- The status model includes `in_review`.
- Documentation explains when to use `in_review`.
- The CLI accepts `in_review` wherever statuses are accepted.
- Status filtering and shell completion include `in_review`.
- Smokey fixtures and tests are updated if needed.
- Agent policy describes that implemented tickets normally move to `in_review`
  before they move to `done`.

# Comments

- 2026-08-10: Search found no existing `in_review` status. Current built-in
  statuses are `open`, `designing`, `active`, `blocked`, `done`, and
  `cancelled`.
- 2026-08-10: Moved from `Refinement` to `Governance` because this changes the
  status model and ticket lifecycle.

# Outcome
