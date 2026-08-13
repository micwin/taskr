---
title: Require docs help and examples before command closure
status: developing
created_at: 2026-08-10T10:03:30Z
updated_at: 2026-08-13T20:24:32Z
developing_at: 2026-08-13T20:24:32Z
---

# Description

Update the Taskr agent/project policy so tickets that add or change commands,
subcommands, flags, or user-visible command behavior cannot move to
`reviewing` until documentation, command help, and examples are complete.

This rule applies to Taskr project work. It should prevent command behavior
from shipping with stale or missing docs/help/examples.

# Acceptance

- `AGENTS.md` states that Taskr command and flag tickets require current docs
  before closure.
- `AGENTS.md` states that command help must document new or changed commands,
  subcommands, flags, inputs, and relevant behavior before closure.
- `AGENTS.md` states that examples must cover each new or changed command,
  subcommand, flag, and important command variant before closure.
- The examples rule follows the scope described in ticket `043`: at least one
  normal example and one advanced or edge-case example where the command has
  flags, subcommands, or non-trivial input modes.
- The policy applies before setting a ticket to `reviewing`; a ticket is not
  review-ready while required documentation, help, or examples are incomplete.
- The user-controlled transition from `reviewing` to `done` does not defer
  documentation work that should already have been part of implementation.
- The policy does not require user-facing docs to label examples as normal,
  advanced, expert, or edge-case.
- The policy fits with the existing rule that doctor, help, completion, and API
  must be checked before closing relevant code tickets.

# Comments

- 2026-08-10: Added after creating ticket `043` for an examples coverage check.
  This ticket is the human/agent closure policy counterpart: command work is
  not done until docs, help, and examples are current.
- 2026-08-13: Moved the enforcement point from `done` to `reviewing`. Reviewing
  means the agent considers implementation complete, so stale or missing docs,
  help, or examples must block that transition rather than wait for user
  approval of `done`.

# Outcome
