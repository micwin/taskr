---
title: Reconfigure mount objects
status: designing
created_at: 2026-08-25T17:20:18Z
updated_at: 2026-08-25T17:20:18Z
designing_at: 2026-08-25T17:20:18Z
---

# Description

Implement `taskr reconfigure mount <searchterm/slug/id>` for updating virtual
mount objects in `taskr.toml`.

Reconfiguration accepts one or more parameters from the `create mount` surface
and changes only the provided values.

# Acceptance

- `taskr reconfigure mount <selector> --name <name>` updates the display name.
- `taskr reconfigure mount <selector> --path <path>` resolves and updates the
  mounted Taskr root path.
- `taskr reconfigure mount <selector> --mode <mode>` updates mode to
  `read-only` or `read-write`.
- Multiple parameters may be changed in one invocation.
- At least one update parameter is required.
- `--name` accepts quoted values with spaces.
- Invalid selector, ambiguous selector, invalid mode, invalid path, and
  unchanged/empty update requests fail clearly.
- Reconfiguring the mount ID itself is out of scope; future rename/alias work
  must handle identity changes explicitly.
- Help, docs, examples, and shell completion cover `reconfigure mount` and
  mount selectors.
- Smokey covers single-field updates, multi-field updates, quoted names,
  path resolution, invalid values, missing update parameters, and ambiguity.

# Comments

- 2026-08-25: Command-specific slice of ticket 099.

# Outcome
