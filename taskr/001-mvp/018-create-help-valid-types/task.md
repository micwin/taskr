---
title: Show valid create types in help
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Improve `taskr create --help` so users can see which item types are accepted
without having to trigger an error.

# Acceptance

- `taskr create --help` lists the valid create types: `milestone`, `task`, and
  `subtask`.
- The help explains that the marker filename is derived from the type.
- Invalid type errors keep naming the invalid value.
- Shell completion/help remains current.
- Smokey or unit coverage verifies the help text.

# Comments

- 2026-08-07: Found while dogfooding: `taskr create <type> <title>` requires a
  type but the help output does not say what valid values are.

# Outcome

Improved `taskr create --help` with the valid types directly in usage:

```text
taskr create {milestone|task|subtask} <title>
```

The help now explains that the item type determines the marker filename. Invalid
type errors still include the invalid value through the existing create
validation.

Pre-close checks:

- `bash -n scripts/build.sh` passes.
- `go test ./...` passes.
- `taskr --help` and `taskr create --help` render successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes (`13/13`) with final teardown executed.
- No public API exists yet.
