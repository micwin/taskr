---
title: Include other Taskr roots as mounted sources
status: designing
created_at: 2026-08-17T07:23:50Z
updated_at: 2026-08-25T14:38:44Z
designing_at: 2026-08-17T07:23:50Z
---

# Description

Define and implement support for mounting other Taskr roots into the current
Taskr root so external work can be shown and, when explicitly configured,
edited from the parent root.

Mounted roots should behave like attached subtrees for display, selectors,
search, reports, and generated sites while preserving clear source identity.
Mounts may be read-only or read-write. Read-only mounts can be listed and
inspected but must reject mutating commands with clear messages. Read-write
mounts allow supported mutations to be applied to the mounted root itself.

The feature needs a command to manage mounts, a `taskr.toml` configuration
schema, rules for where mounts can be attached, and a stable identity model.
Initial thinking: mounted roots are attached only at the current root level, not
inside arbitrary milestones/tasks/subtasks. Each mounted root needs an explicit
identifier used in displays, selectors, and search terms to avoid ID and slug
collisions across roots.

Example identity shape to evaluate:

- local item `003`
- mounted item `vendor:003`
- local slug `workflow`
- mounted slug `vendor:workflow`

The exact separator and allowed identifier syntax must be decided before
implementation.

# Acceptance

- Define the `taskr.toml` schema for mounted roots, including at least
  identifier, path, and mode (`read-only` or `read-write`).
- Define the CLI command surface for managing mounts, including adding,
  listing, updating/removing, and validating mounted roots.
- Define whether mounted-root paths are resolved relative to the working
  directory, current Taskr root, or config file location.
- Decide whether mounts are allowed only at the root level or can be attached
  below specific local items. The current working assumption is root-level only.
- Define allowed mount identifier syntax and how identifiers appear in list,
  tree, show, report, generated site, errors, shell completion, and selectors.
- Define selector syntax for mounted IDs and slugs and how ambiguity is reported
  across local and mounted roots.
- Define how read-only mounted items participate in display, selector
  completion, full-text search, tag filtering, reports, generated sites, and
  references.
- Define which mutating commands are allowed for read-write mounts and which
  remain local-only.
- Mutating commands against read-only mounted items fail clearly without
  modifying either root.
- Read-write mutations target the mounted root's files, not shadow copies in
  the parent root.
- Root-local validations such as doctor must distinguish local-root errors from
  mounted-root errors and report the mount identifier in diagnostics.
- ID and slug collisions across roots do not make the combined view ambiguous
  when a mount identifier is used.
- Decide whether mounted-root failures block normal parent-root operation or
  can be degraded for read-only display.
- Identify whether this must be split into implementation subtickets, likely
  config/schema, mount command, read-only display/selectors, read-write
  mutation routing, doctor validation, generated site support, and Smokey
  workflow coverage.
- Identify Smokey coverage before implementation begins, including collision,
  read-only mutation rejection, read-write mutation routing, and unavailable
  mounted roots.

# Comments

- 2026-08-17: Added while discussing references between Taskr trees and the
  possibility of read-only imported tickets.
- 2026-08-25: Michael refined the requirement from read-only include to mounted
  roots with read-only/read-write modes. A parent root should be able to show
  and optionally edit another Taskr root as if it were part of the visible tree,
  while mounted items remain distinguishable by a root identifier such as a
  prefix before IDs/slugs.

# Outcome
