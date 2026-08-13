# Changelog

All notable Taskr changes are recorded here. Release headings use the exact
committed `VERSION+BUILD` value.

## [Unreleased]

- Added strict project-local `taskr.toml` configuration with initial site
  settings and Doctor validation.
- Added `taskr site init` with safe output-directory ownership, explicit
  creation, idempotent configuration, and Doctor validation.
- Added `taskr site generate` for atomic, self-contained project sites with
  status views, search, paginated results, and complete ticket pages.

## [0.1.0+40] - 2026-08-10

- Made published SHA-256 checksum files directly verifiable beside downloaded
  GitHub Release assets.

## [0.1.0+39] - 2026-08-10

- Added the Cobra-based Taskr CLI and local-first Markdown worktree model.
- Added create, show, list, tree, status, priority, move, rename, comment,
  report, archive, doctor, completion, init, and version workflows.
- Added Debian packaging with embedded semantic version and monotonic build
  metadata.
- Added complete Smokey workflow coverage for the supported command surface.
