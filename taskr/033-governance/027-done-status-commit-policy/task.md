---
title: Require done status in a separate commit
status: done
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-14T10:29:20Z
developing_at: 2026-08-13T20:35:40Z
reviewing_at: 2026-08-13T20:47:59Z
done_at: 2026-08-14T10:29:20Z
---

# Description

Update the Taskr agent policy so code changes and ticket closure are not
committed together. A ticket should move to `done` in its own commit after the
implementation commit has landed and the user explicitly asks for closure.

# Acceptance

- `AGENTS.md` says implementation commits and `status: done` commits are
  separate.
- `AGENTS.md` preserves the rule that commits happen only after explicit user
  request.
- Implementation ends in `reviewing`. Implementation commits contain the
  delivered code, tests, documentation, help, examples, completed Outcome,
  applicable release note, and the ticket's `reviewing` state.
- Review corrections are committed before closure and leave the ticket in
  `reviewing` until the user accepts the result.
- Only after an explicit user instruction does a dedicated closure commit move
  the ticket from `reviewing` to `done`.
- The closure commit contains only the ticket status/timestamp update and the
  repository's required `BUILD` update. It does not mix implementation or
  review corrections into the acceptance commit.
- The rule applies specifically to delivery closure with `done`; it does not
  automatically impose the same commit shape on `cancelled`.
- Existing policy text that conflicts with this rule is removed or rewritten.
- No code behavior changes are required.

# Comments

- 2026-08-10: Current policy still says a `done` ticket status and the changes
  that make it done belong in the same commit. That should change.
- 2026-08-10: Moved from `Refinement` to `Governance` because this changes
  agent commit policy and needs explicit joint refinement.
- 2026-08-13: Agreed that implementation reaches `reviewing` with code, tests,
  docs, Outcome, and release-note work committed. User acceptance then moves
  only the ticket metadata plus required `BUILD` to `done` in a dedicated
  closure commit. `cancelled` is outside this specific rule.

# Outcome

`AGENTS.md` now separates implementation and acceptance commits. Complete
implementation work is committed in `reviewing` with its code, tests,
documentation, Outcome, and release note. Only an explicit user instruction
may then produce a dedicated `done` commit containing the ticket metadata and
the required `BUILD` update.
