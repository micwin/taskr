---
title: Add developing status
status: designing
created_at: 2026-08-10T10:33:05Z
updated_at: 2026-08-10T10:33:05Z
---

# Description

Introduce a `developing` status for work that has left `designing` and is
actively being implemented. This separates design/refinement from actual code,
documentation, test, or process changes.

# Acceptance

- The status model includes `developing`.
- Documentation explains when to use `designing`, `developing`, `in_review`,
  and `done`.
- The CLI accepts `developing` wherever statuses are accepted.
- Status filtering and shell completion include `developing`.
- The existing Taskr dogfood database is updated to use the new lifecycle where
  appropriate.
- Smokey fixtures and tests are updated if needed.
- Smokey tests cover the new status value independently from dogfood data.
- Agent policy describes that implementation work normally moves from
  `designing` to `developing` before implementation changes begin.
- The relationship to ticket `028-in-review-status` is documented.

# Comments

- 2026-08-10: Added while refining the status lifecycle around
  `028-in-review-status`; `developing` should distinguish active
  implementation from design/refinement.

# Outcome
