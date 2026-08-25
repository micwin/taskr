---
title: Reconfigure mount objects
status: developing
created_at: 2026-08-25T17:20:18Z
updated_at: 2026-08-25T17:57:55Z
designing_at: 2026-08-25T17:20:18Z
developing_at: 2026-08-25T17:57:55Z
---

# Description

Implement `taskr reconfigure mount <searchterm/slug/id>` for updating virtual
mount objects in `taskr.toml`.

Reconfiguration accepts one or more parameters from the `create mount` surface
and changes only the provided values. Supported parameters are `--name`,
`--path`, `--mode`, `--id`, and `--auto-adjust-id`.

Changing `--mode` validates the mounted root before storing the new mode. Every
mode change verifies readability; changing to `read-write` also verifies
writability by creating and removing a short temporary probe file.

`--auto-adjust-id` derives the mount ID from the current or newly provided
`--name` using the same first-word progressive lowercase rule as
`taskr create mount`. The mount's own current ID must not be treated as a
collision while checking candidate availability. `--id` and `--auto-adjust-id`
are mutually exclusive.

# Acceptance

- `taskr reconfigure mount <selector> --name <name>` updates the display name.
- `taskr reconfigure mount <selector> --path <path>` resolves and updates the
  mounted Taskr root path.
- `taskr reconfigure mount <selector> --mode <mode>` updates mode to
  `read-only` or `read-write`.
- `taskr reconfigure mount <selector> --id <id>` updates the mount ID when the
  new ID is valid and unused.
- `taskr reconfigure mount <selector> --auto-adjust-id` derives a mount ID from
  the mount name using the same rule as `create mount`.
- `--auto-adjust-id` may be combined with `--name`; the new name is used for
  ID derivation.
- `--auto-adjust-id` does not reject the mount's existing ID as a collision
  when the derived ID is unchanged.
- `--id` and `--auto-adjust-id` are mutually exclusive.
- Reconfiguring `--mode` checks readability for every mode and writability when
  the resulting mode is `read-write`.
- Multiple parameters may be changed in one invocation.
- At least one update parameter is required.
- `--name` accepts quoted values with spaces.
- Invalid selector, ambiguous selector, invalid mode, invalid path, and
  unchanged/empty update requests fail clearly.
- Help, docs, examples, and shell completion cover `reconfigure mount` and
  mount selectors.
- Smokey covers single-field updates, multi-field updates, quoted names,
  path resolution, mode validation, explicit ID change, auto-adjusted ID,
  auto-adjusted unchanged ID, `--id`/`--auto-adjust-id` exclusivity, invalid
  values, missing update parameters, and ambiguity.

# Comments

- 2026-08-25: Command-specific slice of ticket 099.
- 2026-08-25: Michael added mode access validation, explicit ID changes, and
  `--auto-adjust-id`.

# Outcome
