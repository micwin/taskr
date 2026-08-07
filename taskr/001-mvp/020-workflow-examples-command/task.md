---
title: Add workflow examples command
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Add a command that prints concise standard workflow examples for common Taskr
operations.

# Acceptance

- A user can run `taskr examples` to see common workflows.
- Examples cover initializing a root, creating a milestone, creating a ticket,
  creating a subtask, editing an item, closing work, reporting work, and
  archiving closed work.
- The examples use real current command names and flags.
- The command appears in help and shell completion.
- Smokey coverage verifies the examples output.

# Comments

- 2026-08-07: A `help workflows` subcommand would fight Cobra's built-in help
  command. Use `taskr examples` as the stable user-facing command.

# Outcome

Implemented `taskr examples`.

The command prints concise standard workflows for:

- initializing a project worktree
- creating a milestone
- creating a ticket below a milestone
- creating a subtask below a ticket
- editing an item
- inspecting/listing/reporting work
- listing tickets by open, active, done, or cancelled status, optionally below a
  selected milestone
- closing work with `taskr status <selector> done`
- archiving closed work

`taskr examples` is included in root help and Cobra completion.

Pre-close checks:

- `bash -n scripts/build.sh` passes.
- `go test ./...` passes.
- `taskr --help` and `taskr examples` render successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes (`14/14`) with final teardown executed.
- No public API exists yet.
