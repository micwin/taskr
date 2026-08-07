---
title: Add minimal Taskr binary
status: open
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

# Outcome
