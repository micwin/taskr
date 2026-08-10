---
title: Analyze automatic branching
status: designing
created_at: 2026-08-10T12:35:49Z
updated_at: 2026-08-10T12:35:49Z
---

# Description

Analyze how Taskr could automate Git branching around Taskr tickets so work can
start, continue, review, and close with consistent branch names and fewer manual
Git steps.

The design should decide whether branching belongs in Taskr itself, in agent
policy, in external scripts, or in a combination of those.

# Acceptance

- The analysis defines use cases for automatic branching, such as starting work
  on a ticket, resuming a ticket, moving a ticket to review, and closing or
  abandoning work.
- The analysis proposes branch naming rules based on Taskr item IDs, slugs,
  milestones, and ticket type.
- The analysis covers when branches are created, checked out, reused, merged,
  deleted, or left untouched.
- The analysis covers dirty worktrees, uncommitted changes, unrelated user
  changes, and existing branches.
- The analysis covers how automatic branching interacts with the current rule
  that commits are created only after explicit user instruction.
- The analysis covers how branching should interact with `develop`, feature
  branches, release branches, GitHub integration, and future PR workflows.
- The analysis covers whether Taskr commands should call Git directly or only
  report recommended Git commands.
- The analysis covers agent policy changes needed in `AGENTS.md`.
- Smokey or integration-test requirements are identified before implementation.
- No branching implementation is added until the design is accepted.

# Comments

- 2026-08-10: Added after remembering branching as a potential Taskr
  automation feature. This should be designed separately because it can affect
  Git state, agent workflow, and user control over commits.

# Outcome
