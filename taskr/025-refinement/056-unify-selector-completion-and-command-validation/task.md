---
title: Unify selector completion and command validation
status: designing
created_at: 2026-08-10T11:54:29Z
updated_at: 2026-08-10T11:54:29Z
---

# Description

Analyze and design how selector completion rules and command parameter
validation rules can be unified so Taskr does not maintain separate, drifting
logic for the same hierarchy constraints.

Examples include `move --under`, where completion should suggest only valid
parents for the selected source item, and runtime validation should reject the
same invalid parent choices through the same rule model.

# Acceptance

- The analysis identifies every current code path that decides whether an item
  ID or slug is valid for a command argument or flag.
- The analysis identifies every current code path that decides whether an item
  ID or slug should appear in shell completion.
- The proposed design defines one shared rule model for selector surfaces,
  including all-items selectors, tree-root selectors, display parent selectors,
  create parent selectors, and move parent selectors.
- The proposed design explains how command validation and shell completion use
  the same rule model without duplicating hierarchy logic.
- The proposed design covers source-dependent rules such as moving tasks only
  under milestones and subtasks only under tasks.
- The proposed design includes a test strategy that verifies both runtime
  validation and completion behavior from the same expected rule cases where
  practical.
- The analysis calls out cases where completion may intentionally be broader or
  narrower than validation, if any.
- No behavior is changed by this ticket unless implementation is explicitly
  added after the analysis is accepted.

# Comments

- 2026-08-10: Added while refining selector completion coverage. The current
  code has separate completion filters and runtime validation checks; they
  should be analyzed for possible unification before the rules grow further.

# Outcome
