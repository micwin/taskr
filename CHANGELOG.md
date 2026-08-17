# Changelog

All notable Taskr changes are recorded here. Release headings use the exact
committed `VERSION+BUILD` value.

## [Unreleased]

## [0.2.0+82]

- Taskr releases now use separate prepare, release, and post-release scripts so
- release preparation can be reviewed before the release branch is committed and
- published.

## [0.1.0+82]

- Taskr items can now carry tags in marker frontmatter. Tags are visible in CLI
- output and generated sites, searchable with `show '#tag'`, filterable with
- `list --tags`, completed by the shell, and validated by Doctor.
- Generated Taskr sites now include status filters. Done and cancelled work is
- hidden by default, can be toggled back on, and milestones stay visible whenever
- they contain visible work.

- Added `taskr site open` with loopback serving, browser selection, positional
  site search, optional regeneration, and live watch reload.
- Added repeatable, case-insensitive `taskr list --glob` filtering over complete
  marker text.
- Added root-local `[defaults]` creation statuses with explicit, type-specific,
  common, and built-in precedence.
- Added `taskr create --status` for selecting a validated non-closed initial
  status with consistent creation and status timestamps.
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
