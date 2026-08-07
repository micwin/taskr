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

# Outcome
