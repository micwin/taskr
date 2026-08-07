---
title: Add minimal Taskr binary
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Create the smallest Go and Cobra executable that provides a real `taskr` binary
and routes the MVP command names without implementing the workflows yet.

# Acceptance

- A Go module exists for the Taskr CLI.
- The CLI builds a `taskr` binary from source under `src/`.
- Cobra is used for command routing from the start.
- The binary recognizes `doctor`, `create`, `show`, `list`, `status`, `open`,
  `report`, `archive`, and `version`.
- Unimplemented MVP commands fail with a controlled not-implemented message and
  non-zero exit code instead of `command not found`.
- `taskr --help` and subcommand help render successfully.
- Smokey setup can build or point to the binary so later tests fail on missing
  behavior rather than missing executable.

# Comments

- 2026-08-07: This is the minimal implementation slice before real workflow
  behavior. It should not implement storage, selectors, reports, or archive.
- 2026-08-07: Implemented the minimal Cobra command surface and wired Smokey
  setup to build the binary into `${SMOKEY_STATE_DIR}/bin/taskr`.

# Outcome

Added a minimal Go/Cobra CLI:

```text
go.mod
src/taskr/main.go
```

The binary recognizes:

```text
doctor
create
show
list
status
open
report
archive
version
```

`version` prints a stable development version. MVP workflow commands are routed
and fail with controlled `taskr: <command> not implemented...` messages and
exit code `2`.

Smokey setup now builds the current source into `${SMOKEY_STATE_DIR}/bin/taskr`
and test runners default to that binary. The full Smokey suite remains red for
the expected next reason: workflow behavior is not implemented yet, but there
are no longer `command not found` or unknown-flag failures.

Verification:

```bash
go test ./...
go build -o work/bin/taskr ./src/taskr
work/bin/taskr --help
work/bin/taskr create --help
work/bin/taskr version
work/bin/taskr . doctor
smokey --tests-dir tests.d
```
