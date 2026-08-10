---
title: Add reviewing status
status: done
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Introduce a `reviewing` status between active development and `done` so work
can be implemented, tested, and reviewed before closure.

# Acceptance

- The status model includes `reviewing`.
- Documentation explains when to use `reviewing`.
- The CLI accepts `reviewing` wherever statuses are accepted.
- Status filtering and shell completion include `reviewing`.
- Smokey fixtures and tests are updated if needed.
- Agent policy describes that implemented tickets normally move to `reviewing`
  before they move to `done`.
- Agent policy in `AGENTS.md` states that when an agent considers a ticket
  complete, it sets the ticket to `reviewing`; `done` and `cancelled` are used
  only after an explicit user instruction.
- Agent policy in `AGENTS.md` states that once a ticket is in `reviewing`,
  further semantic changes to the ticket, Smokey test logic, code behavior,
  documentation behavior, or process outcome require explicit user instruction.

# Comments

- 2026-08-10: Search found no existing `in_review` status. Current built-in
  statuses are `open`, `designing`, `active`, `blocked`, `done`, and
  `cancelled`.
- 2026-08-10: Moved from `Refinement` to `Governance` because this changes the
  status model and ticket lifecycle.
- 2026-08-10: Renamed the proposed status from `in_review` to `reviewing` to
  match the `designing` and `developing` status naming style.
- 2026-08-10: Added Smokey expectations for `reviewing` in status changes,
  status filtering, shell completion, and test configuration.

# Outcome

Implemented `reviewing` as a built-in status. The CLI accepts it for status
changes and filters, shell completion suggests it, documentation describes its
place in the lifecycle, AGENTS.md defines the agent review handoff rule, and
Smokey covers status, filtering, and completion behavior.
