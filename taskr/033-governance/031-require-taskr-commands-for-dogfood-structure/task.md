---
title: Require Taskr commands for dogfood structure changes
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Update the Taskr agent policy so Taskr dogfood items are created and moved with
Taskr commands instead of direct filesystem manipulation. Direct text editing
inside existing marker files remains allowed for ticket wording, comments, and
outcomes.

# Acceptance

- `AGENTS.md` says Taskr dogfood item creation must use `taskr create` once the
  command can satisfy the needed operation.
- `AGENTS.md` says Taskr dogfood item moves must use `taskr move` once the
  command can satisfy the needed operation.
- `AGENTS.md` allows direct text editing inside existing marker files for
  `# Description`, `# Acceptance`, `# Comments`, and `# Outcome` according to
  the ticket lifecycle rules.
- `AGENTS.md` defines when direct filesystem manipulation is still acceptable,
  such as before a supporting Taskr command exists or after explicit user
  approval.
- The policy keeps `taskr doctor` as the validation gate after structural
  dogfood changes.

# Comments

- 2026-08-10: Added after a duplicate root-wide ID was traced to manual or
  stale dogfood ticket creation instead of normal sequential `taskr create`.
- 2026-08-10: Moved from `Refinement` to `Governance` because this changes
  agent workflow policy.

# Outcome
