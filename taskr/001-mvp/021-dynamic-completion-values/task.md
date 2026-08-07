---
title: Complete status, type, and selector values
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Add shell completion values for Taskr item types, statuses, and selectors so
interactive CLI use does not require memorizing valid values or item IDs.

# Acceptance

- `taskr create` completes valid item types: `milestone`, `task`, and
  `subtask`.
- `--type` flags complete valid item types wherever the flag exists.
- `--status` flags complete valid statuses wherever the flag exists.
- `taskr status <selector> <status>` completes valid statuses for the status
  argument.
- Selector arguments complete known item IDs, slugs, and useful display labels
  for `show`, `open`, `status`, and `archive`.
- `--under` completes selectors for commands that accept a parent selector.
- Completion handles missing or invalid roots without breaking shell completion.
- Completion does not print normal command errors into the shell completion
  stream.
- Smokey or unit coverage verifies at least type, status, and selector
  completion behavior.

# Comments

- 2026-08-07: Cobra currently completes command and flag names only. There are
  no `ValidArgsFunction` or `RegisterFlagCompletionFunc` hooks yet.
- 2026-08-07: Added red Smokey coverage through Cobra's hidden `__complete`
  command for type values, status values, selectors, `--under`, and missing-root
  behavior.

# Outcome

Implemented dynamic Cobra completion values.

Covered behavior:

- `taskr create` completes item types: `milestone`, `task`, and `subtask`.
- `--type` flags complete item types on commands that expose the flag.
- `--status` flags complete all valid statuses.
- `taskr status <selector> <status>` completes statuses for the second
  positional argument.
- Selector arguments complete item IDs and slugs with labels containing type,
  status, and title.
- `--under` completes selectors.
- Missing or invalid roots return no completion candidates and do not print
  normal command errors into the completion stream.

Pre-close checks:

- `bash -n scripts/build.sh` passes.
- `go test ./...` passes.
- `taskr --help` renders successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes (`15/15`) with final teardown executed.
- No public API exists yet.
