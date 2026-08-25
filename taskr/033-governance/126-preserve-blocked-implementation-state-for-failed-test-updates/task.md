---
title: Preserve blocked implementation state for failed test updates
status: done
release_note: no-release-note
created_at: 2026-08-25T19:35:24Z
updated_at: 2026-08-25T19:38:10Z
open_at: 2026-08-25T19:35:24Z
designing_at: 2026-08-25T19:35:33Z
done_at: 2026-08-25T19:38:10Z
---

# Description

Define the agent workflow for implementation tickets that cannot reach
`reviewing` without changing already accepted Smokey test logic.

Accepted tests define the ticket contract after `designing`. If implementation
shows that the contract itself must change, the agent must preserve the current
implementation state separately and report the blocked ticket instead of
silently editing the accepted tests on `develop`.

# Acceptance

- `AGENTS.md` documents that an implementation ticket blocked by necessary test
  changes gets a branch named from the ticket slug.
- That branch contains the implementation changes so far plus the proposed test
  change.
- The original implementation ticket that requires the test change is set to
  `blocked` on `develop`.
- That blocked ticket receives a comment naming the branch and explaining why
  the ticket could not reach `reviewing`.
- For stacked ticket work, a blocked ticket's failing test may be commented out
  in one focused commit with a descriptive message so later tickets can run.
- The final agent report for stacked work lists every unfinished ticket with a
  one-line reason.
- The rule does not permit silent semantic changes to accepted tests after
  `designing`.

# Comments

- 2026-08-25: Added after preparing the 099 mounted-root implementation stack.
  Michael requested a branch-preservation rule for tickets that cannot be
  driven to review without touching accepted tests.

# Outcome

Added the agent policy to `AGENTS.md`: if an implementation ticket cannot reach
`reviewing` without changing accepted tests, preserve the work on a
ticket-slug-named branch, mark the original ticket `blocked` on `develop`, and
document the branch and reason in that ticket.
