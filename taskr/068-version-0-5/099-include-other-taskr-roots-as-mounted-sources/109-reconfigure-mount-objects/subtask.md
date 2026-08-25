---
title: Reconfigure mount objects
status: blocked
created_at: 2026-08-25T17:20:18Z
updated_at: 2026-08-25T20:13:07Z
designing_at: 2026-08-25T17:20:18Z
developing_at: 2026-08-25T17:57:55Z
blocked_at: 2026-08-25T20:13:07Z
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
- Invalid selector, ambiguous selector, duplicate ID, invalid mode or path, and
  empty update values fail clearly.
- Update requests whose resulting values are unchanged succeed as no-op
  reconfigurations.
- Help, docs, examples, and shell completion cover `reconfigure mount` and
  mount selectors.
- Smokey covers single-field updates, multi-field updates, quoted names,
  path resolution, mode validation, explicit ID change, auto-adjusted ID,
  auto-adjusted unchanged ID, `--id`/`--auto-adjust-id` exclusivity, invalid
  values, duplicate ID, missing update parameters, unchanged no-op requests,
  empty update values, and ambiguity.
- Negative permission-denied cases for unreadable roots and unwritable
  read-write roots require robust Smokey permission fixtures and are deferred
  until that Smokey-side support exists. The implementation still must perform
  the runtime readability and writability checks.

# Comments

- 2026-08-25: Command-specific slice of ticket 099.
- 2026-08-25: Michael added mode access validation, explicit ID changes, and
  `--auto-adjust-id`.
- 2026-08-25: Chmod-based unreadable/unwritable Smokey cases are not part of
  this suite because permission behavior depends on the test runner
  environment. Robust permission fixture support is tracked in the Smokey
  project.
- 2026-08-25: Unchanged reconfigure requests are no-op successes, not errors.
  Here, unchanged means provided parameters resolve to the mount's existing
  values.
- 2026-08-25: Empty update values such as `--name ""` and `--id ""` are errors.
  Explicit `--id` changes must also reject IDs already used by another mount.

- 2026-08-25 22:13: Blocked on branch reconfigure-mount-objects: the accepted suite creates mount-reconfigure-multiple-target twice and the second setup fails before reconfigure can run. The branch separates the two fixture targets.

# Outcome
