---
title: Validate open parents for new items
status: done
created_at: 2026-08-10T10:29:12Z
updated_at: 2026-08-18T06:19:11Z
developing_at: 2026-08-17T13:00:53Z
reviewing_at: 2026-08-17T13:03:20Z
done_at: 2026-08-18T06:19:11Z
---

# Description

Add startup/doctor and create-time validation so new Taskr items can only be
added below open parent context. A closed milestone must not receive new tasks,
and a closed task must not receive new subtasks.

The validation also protects the existing hierarchy invariant: a terminal
parent is only valid when all of its descendants are terminal too. An open,
designing, developing, active, reviewing, or blocked child below a `done` or
`cancelled` parent is an invalid worktree state. Continuing work below a
terminal parent must be an explicit reopen of the parent context, not an
implicit side effect of creating or keeping unfinished children below it.

# Acceptance

- The rule defines which statuses are open for accepting new children.
- The open-for-children statuses are `open`, `designing`, `developing`,
  `active`, `reviewing`, and `blocked`.
- The terminal statuses `done` and `cancelled` are closed for accepting new
  children.
- Creating a task below a closed milestone fails clearly.
- Creating a subtask below a closed task fails clearly.
- Creating a subtask also checks the containing milestone ancestry and fails if
  the milestone is closed.
- `taskr doctor` reports existing violations where a terminal parent contains
  unfinished descendants.
- `taskr doctor` reports existing violations where an item has been added below
  a closed parent context.
- Normal command startup refuses invalid roots with those violations where the
  command needs a valid loaded worktree.
- Users who need to continue work below a terminal parent must reopen the
  parent context first; Taskr must not silently reopen parents during create.
- The validation keeps archive behavior separate from active worktree creation.
- Help or documentation explains that new work can only be added below open
  parent context.
- Smokey tests cover create-time rejection and doctor/startup detection for
  manually corrupted fixtures.
- Smokey tests cover an existing unfinished child below a terminal parent and
  assert that doctor/startup reject it.

# Comments

- 2026-08-10: Added after defining `tree`; closed context should stay stable.
  New tasks belong only under open milestones, and new subtasks belong only
  under open tasks whose milestone context is also open.

# Outcome

Implemented terminal parent validation for create-time and worktree-load paths.
`done` and `cancelled` parents now reject new child creation, and loaded roots
are invalid when terminal parents contain unfinished descendants.

Updated `create` and `doctor` help text to document the closed parent context
rule.

Verified with `go test ./src/taskr` and `smokey --tests-dir tests.d`: 32/32
Smokey tests passed.
