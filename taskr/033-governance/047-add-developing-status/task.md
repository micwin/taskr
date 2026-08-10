---
title: Add developing status
status: done
created_at: 2026-08-10T10:33:05Z
updated_at: 2026-08-10T10:33:05Z
---

# Description

Introduce a `developing` status for work that has left `designing` and is
actively being implemented. This separates design/refinement from actual code,
documentation, test, or process changes.

# Acceptance

- The status model includes `developing`.
- Documentation explains when to use `designing`, `developing`, `reviewing`,
  and `done`.
- The CLI accepts `developing` wherever statuses are accepted.
- Status filtering and shell completion include `developing`.
- The existing Taskr dogfood database is updated to use the new lifecycle where
  appropriate.
- Smokey fixtures and tests are updated if needed.
- Smokey tests cover the new status value independently from dogfood data.
- Agent policy describes that implementation work normally moves from
  `designing` to `developing` before implementation changes begin.
- The relationship to ticket `028-reviewing-status` is documented.

# Comments

- 2026-08-10: Added while refining the status lifecycle around
  `028-reviewing-status`; `developing` should distinguish active
  implementation from design/refinement.
- 2026-08-10: Updated references from `in_review` to `reviewing`, matching the
  accepted status name from ticket `028`.
- 2026-08-10: Implemented as a built-in default status only. Configurable
  workflows remain separate in `059-analyze-configurable-workflows`.

# Outcome

Implemented `developing` as a built-in status. The CLI accepts it for status
changes and filters, shell completion suggests it, documentation describes its
place between design and review, AGENTS.md tells agents to move tickets to
`developing` when implementation starts, and Smokey covers status, filtering,
completion, and parent completion blocking behavior.
