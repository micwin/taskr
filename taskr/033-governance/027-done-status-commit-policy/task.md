---
title: Require done status in a separate commit
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
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
- `AGENTS.md` defines what belongs in the implementation commit.
- `AGENTS.md` defines what belongs in the closure commit.
- Existing policy text that conflicts with this rule is removed or rewritten.
- No code behavior changes are required.

# Comments

- 2026-08-10: Current policy still says a `done` ticket status and the changes
  that make it done belong in the same commit. That should change.
- 2026-08-10: Moved from `Refinement` to `Governance` because this changes
  agent commit policy and needs explicit joint refinement.

# Outcome
