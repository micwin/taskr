---
title: Implement until tests are green
status: active
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Build the Go and Cobra implementation until the full Smokey suite passes.

# Acceptance

- The Go module builds a `taskr` CLI using Cobra.
- The CLI reads Markdown marker files with YAML frontmatter.
- The CLI enforces marker-count and directory-ID validation.
- MVP commands satisfy the red Smokey workflow tests.
- `smokey --tests-dir tests.d` passes with final teardown executed.

# Comments

- 2026-06-03: Implementation waits until workflows and command behavior are
  specified.
- 2026-06-04: Red Smokey workflow suite exists under `tests.d/`; implementation
  should make `smokey --tests-dir tests.d` pass.
- 2026-08-07: Implemented the MVP CLI behavior required by the Smokey workflow
  suite.

# Outcome

Implemented the first functional Taskr CLI in `src/taskr/main.go`.

Covered behavior:

- `doctor` validates roots, marker counts, directory IDs, frontmatter status,
  duplicate IDs, file containers, and archive containers.
- `create` creates marker directories, assigns the next root-wide ID, writes the
  Markdown/frontmatter template, validates MVP parent-child combinations, checks
  slug collisions, and optionally opens `$EDITOR`.
- `show`, `list`, and `report` resolve selectors by ID, slug, title, substring,
  or archive path and fail on missing or ambiguous matches.
- `status` updates marker frontmatter and blocks `done` while descendants are
  unfinished.
- `open` launches `$EDITOR` or the system opener and reports the root-relative
  marker path.
- `archive` moves closed subtrees below `archive/`.

Pre-close checks:

- `go test ./...` passes.
- `taskr --help` renders successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes with final teardown executed.
- No public API exists yet.
