---
title: Resolve site init paths from working directory
status: designing
created_at: 2026-08-14T12:07:34Z
updated_at: 2026-08-14T12:07:34Z
designing_at: 2026-08-14T12:07:34Z
---

# Description

Fix `taskr site init <site-directory>` so a relative command-line path is
resolved from the caller's current working directory rather than from the
discovered Taskr root.

This matters when Taskr discovers a `taskr/` child below the current project
directory. From `/home/micwin/Documents/SchweizUpdate`, the command
`taskr site init ./site` must select
`/home/micwin/Documents/SchweizUpdate/site`, not
`/home/micwin/Documents/SchweizUpdate/taskr/site`.

# Acceptance

- A relative `<site-directory>` argument to `taskr site init` resolves relative
  to the process working directory at invocation time.
- An absolute `<site-directory>` argument remains unchanged.
- Root discovery remains independent: Taskr may discover a `taskr/` child
  without changing the meaning of the user's relative site argument.
- The configured `[site].directory` value remains portable. After resolving
  and validating the CLI argument, Taskr stores a path relative to the Taskr
  root when a clean relative representation is available; otherwise it stores
  the absolute path.
- Existing `taskr.toml` semantics remain unchanged: relative persisted
  `[site].directory` values continue to resolve from the Taskr root.
- Overlap checks use the fully resolved source and target paths. A genuine
  overlap with the Taskr root is still rejected.
- `--create-if-missing`, ownership-marker handling, idempotency, and rollback
  retain their existing behavior with the corrected path resolution.
- Help, examples, README, and workflow documentation distinguish CLI argument
  resolution from persisted project-configuration resolution.
- Smokey reproduces the reported layout with `$PWD/taskr` as the discovered
  root and `./site` as the requested sibling output, and also covers absolute
  paths, genuine overlap rejection, persisted path behavior, and repeated
  initialization.

# Comments

- 2026-08-14: Reported from `/home/micwin/Documents/SchweizUpdate` using
  `taskr site init ./site`. Taskr discovered
  `/home/micwin/Documents/SchweizUpdate/taskr` and incorrectly interpreted the
  argument as that root's child, then rejected it as overlapping.

# Outcome
