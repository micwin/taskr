---
title: Discover taskr subdirectory by default
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Make commands without an explicit root usable from a normal project directory
after `taskr init` created `./taskr`.

# Acceptance

- Commands with an explicit root keep using that directory.
- Commands without an explicit root use `.` when the current directory is a
  valid Taskr root.
- Commands without an explicit root use `./taskr` when the current directory is
  not a Taskr root and `./taskr` is a valid Taskr root.
- Normal project directories with unrelated subdirectories do not break
  commands after `taskr init`.
- Smokey coverage verifies `taskr init` followed by `taskr report` from the
  project directory.
- Help and shell completion remain current.

# Comments

- 2026-08-07: Found during dogfooding in another project: `taskr init` created
  `./taskr`, then `taskr report` scanned the project root and failed on
  `.sync-state`.

# Outcome

Implemented default root discovery for commands without an explicit root:

- Explicit root arguments still select that exact directory.
- Without an explicit root, Taskr first uses `.` when it looks like a Taskr
  root.
- Otherwise, Taskr uses `./taskr` when that subdirectory looks like a Taskr
  root.
- If neither candidate looks like a Taskr root, Taskr falls back to `.` and the
  normal validation error is reported.

This fixes the dogfooding case where `taskr init` in a normal project creates
`./taskr`, but `taskr report` should not scan unrelated project directories
such as `.sync-state`.

Pre-close checks:

- `bash -n scripts/build.sh` passes.
- `go test ./...` passes.
- `taskr --help` renders successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes (`11/11`) with final teardown executed.
- No public API exists yet.
