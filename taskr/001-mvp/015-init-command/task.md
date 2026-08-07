---
title: Add init command
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Add an `init` command that prepares a Taskr worktree without requiring the user
to create directories or marker files by hand.

# Acceptance

- `taskr init` creates a `taskr/` worktree below the current directory.
- `taskr <dir> init` creates or initializes the explicitly selected worktree
  directory.
- Init creates the initial root file container marker `files/files.md`.
- Init is idempotent for an already initialized valid worktree.
- Init validates the resulting worktree with the same structure rules as
  `doctor`.
- Help and shell completion include the new command.
- Smokey coverage verifies default init, explicit init, idempotent init, and
  follow-up `doctor`.

# Comments

- 2026-08-07: Defaulting `taskr init` to `./taskr` keeps ordinary project
  directories with source code, docs, and build files out of the Taskr worktree
  parser.

# Outcome

Implemented `taskr init`.

Behavior:

- `taskr init` initializes `./taskr` below the current directory.
- `taskr <dir> init` initializes the explicitly selected worktree directory.
- Init creates `files/files.md` with the standard Markdown/frontmatter section
  layout.
- Re-running init on a valid initialized root is idempotent and reports
  `created=false`.
- Init validates the resulting root through the normal worktree scanner before
  reporting success.

Pre-close checks:

- `go test ./...` passes.
- `taskr --help` and `taskr init --help` render successfully.
- `taskr completion bash` renders successfully and includes the Cobra command
  surface.
- `taskr <tmp-dir> init` followed by `taskr <tmp-dir> doctor` succeeds.
- `smokey --tests-dir tests.d` passes (`10/10`) with final teardown executed.
- No public API exists yet.
