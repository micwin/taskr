---
title: Move items between parents
status: done
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Define and implement a CLI command for moving an existing Taskr item to another
parent by moving its directory.

# Acceptance

- The command shape for moving an item is defined before implementation.
- The command shape is `taskr move <selector> --under <parent-selector>` for
  moving below another item.
- The command shape is `taskr move <selector> --root` for moving an item to the
  root level.
- `--under` and `--root` are mutually exclusive, and one of them is required.
- Moving an item preserves the item's directory name, marker file, children,
  file containers, comments, and outcome.
- Moving an item validates the source selector and destination parent selector.
- Moving an item refuses ambiguous, missing, invalid, self, or self-descendant
  destinations.
- Moving an item refuses moves that would make the worktree invalid.
- Moving an item reports the old and new root-relative paths.
- `taskr move --help` documents `--under` and `--root`.
- Shell completion includes the `move` command, completes the source selector,
  and completes `--under` selectors.
- Smokey coverage verifies a successful move and representative failure cases.
- `doctor`, command help, shell completion, and any public API remain current.

# Comments

- 2026-08-10: This command is needed before we can dogfood moving GitHub-related
  work out of the MVP milestone into a later public-release milestone.
- 2026-08-10: Proposed shape: `taskr move <selector> --under <parent-selector>`.
- 2026-08-10: Include `--root` now so future root-level moves do not need a
  second command-shape change.
- 2026-08-10: Started implementation against the already defined Smokey
  workflow.

# Outcome

Implemented `taskr move`.

Behavior:

- `taskr move <selector> --under <parent-selector>` moves an item directory
  below another item.
- `taskr move <selector> --root` moves an item directory to the Taskr root.
- `--under` and `--root` are mutually exclusive, and exactly one is required.
- Move preserves the directory name, marker file, children, file containers,
  comments, and outcome.
- Move rejects missing or ambiguous selectors through the shared selector
  resolver.
- Move rejects self moves and self-descendant destinations.
- Move rejects invalid parent/child role pairs and existing destination paths.
- After moving, Taskr reloads the root with the normal validation path; if the
  move made the tree invalid, Taskr attempts to roll back the filesystem move.
- Successful moves print the item ID plus old and new root-relative paths.

Pre-close checks:

- `bash -n scripts/build.sh` passes.
- `go test ./...` passes.
- `taskr --help` and `taskr move --help` render successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes (`16/16`) with final teardown executed.
- No public API exists yet.
