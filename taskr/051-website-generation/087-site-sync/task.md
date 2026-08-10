---
title: Synchronize generated site incrementally
status: designing
created_at: 2026-08-10T18:21:50Z
updated_at: 2026-08-10T18:21:51Z
designing_at: 2026-08-10T18:21:51Z
---

# Description

Add deferred incremental synchronization for generated project sites. Unlike
the initial full replacement in task `081`, sync updates Taskr-owned output,
removes stale generated files, and preserves unrelated files in the initialized
site directory.

# Acceptance

- The command surface defines `taskr site generate --sync` and its relationship
  to full replacement behavior.
- Taskr tracks generated-file ownership without treating unrelated files as its
  own content.
- Sync updates changed output and removes stale generated output while
  preserving files such as manually managed deployment metadata.
- Interrupted or failed synchronization does not leave a partially updated site
  presented as current.
- The design decides whether `[site]` in `taskr.toml` may select sync as the
  project default.
- Smokey covers changed, removed, unchanged, conflicting, and unrelated files
  plus recovery from a failed synchronization.
- Help, examples, completion, Doctor, documentation, and API impact are updated
  for the final flags and configuration.

# Comments

- 2026-08-10: Deferred from the initial site generator because safe ownership
  manifests and partial-update recovery are materially more complex than full
  atomic replacement. `site open --watch` does not depend on this task.

# Outcome
