---
title: Include other Taskr roots as mounted sources
status: reviewing
created_at: 2026-08-17T07:23:50Z
updated_at: 2026-08-26T16:12:27Z
designing_at: 2026-08-25T17:18:02Z
developing_at: 2026-08-25T19:30:33Z
blocked_at: 2026-08-25T20:16:03Z
reviewing_at: 2026-08-26T16:12:27Z
---

# Description

Implement support for mounting other Taskr roots into the current Taskr root so
external work can be shown and, when explicitly configured, edited from the
parent root.

Mounts are virtual Taskr objects stored in project configuration, not marker
files. They live at the root level. Their ID is the configured `id`, and that
ID is also used to qualify every mounted item ID and slug shown to the user or
accepted as a selector.

Mounted roots behave like attached subtrees for display, selectors, search,
reports, and generated sites while preserving clear source identity.
Mounts may be read-only or read-write. Read-only mounts can be listed and
inspected but must reject mutating commands with clear messages. Read-write
mounts allow supported mutations to be applied to the mounted root itself.

Mounts are attached only at the current root level, not inside arbitrary
milestones, tasks, or subtasks. Each mounted root has an explicit ID used as a
prefix in displays, selectors, slugs, and search terms to avoid ID and slug
collisions across roots.

Mount paths may point either directly at a Taskr root or at the parent
directory that contains a `taskr` subdirectory. In both cases Taskr stores the
resolved Taskr root path in `taskr.toml`, not the looser input path.

Mounts are transitive. If a mounted root also defines mounts, those mounted
roots are included as well. Cyclic mount references are errors. Cycles are not
fixable by `doctor --fix` because removing an arbitrary edge would be a
semantic decision.

Mount IDs must be unique across the complete transitive mount graph. If two
local or transitive mounts use the same ID, Taskr aborts with a clear error.
Doctor must detect those collisions. They are not fixable by `doctor --fix`
because choosing a replacement ID would be a semantic decision.
Future collision-resolution mechanisms such as aliases or temporary
replacements are tracked separately in ticket 107.

Example identity shape to evaluate:

- local item `003`
- mount object `vendor`
- mounted item `vendor:003`
- local slug `workflow`
- mounted slug `vendor:workflow`

This ticket owns the mounted-root feature as one cohesive change. The
configuration schema, virtual mount objects, read-only views, read-write
mutation routing, doctor checks, generated site support, reports, completion,
documentation, help, examples, and Smokey coverage belong here.
Implementation is tracked by command- and surface-specific subtickets under
this ticket.

The command surface treats mounts as Taskr objects:

- `taskr create mount <path> --id vendor --name "Vendor Project"`
- `taskr create mount <path> --name "Vendor Project"`
- `taskr create mount <path> --id vendor --name "Vendor Project" --mode read-write`
- `taskr create task "Local work" --mount . --under .:003`
- `taskr create task "New work" --mount vendor --under 003`
- `taskr create subtask "Follow-up" --mount vendor --under vendor:003`
- `taskr list --type mount`
- `taskr show vendor`
- `taskr open vendor:003`
- `taskr comment vendor:003 "Needs vendor input"`
- `taskr move vendor:004 --under vendor:003 --retype`
- `taskr archive vendor:003`
- `taskr reconfigure mount vendor --mode read-write`
- `taskr reconfigure mount vendor --path ../vendor/taskr`
- `taskr reconfigure mount vendor --name "Vendor Tickets" --mode read-only`
- `taskr remove mount vendor`

`taskr reconfigure mount <searchterm/slug/id>` accepts one or more mount
parameters from the `create mount` surface and updates only those values.
Supported parameters include `--name`, `--path`, and `--mode`. The `--name`
value follows normal shell quoting rules, so names with spaces are accepted
when quoted.

`taskr remove mount <id>` removes only the mount entry from local
`taskr.toml`. It must not delete, modify, archive, or otherwise touch the
mounted Taskr root.

The selector prefix `.` is reserved for the current local root. It may be used
where a mount ID is accepted, for example `--mount .`, and in item selectors
such as `.:005`. Shell completion must include `.` and transitive mount IDs
where relevant.

When `taskr create mount` omits `--id`, Taskr derives an ID candidate from the
first word of `--name`: first letter lowercased, then the first two letters,
then the first three, and so on until the first word has been tried. The first
unused valid candidate is selected. If every candidate from that word is already
used or invalid, creation fails with a clear English error such as
`could not derive mount id: too many attempts`.

# Acceptance

- `taskr.toml` stores mounted roots with at least `id`, `name`, `path`, and
  mode (`read-only` or `read-write`).
- Mounts are virtual root-level Taskr objects. They are created with
  `taskr create mount`, shown with normal read surfaces, updated with
  `taskr reconfigure mount`, and removed from local configuration with
  `taskr remove mount` without touching the external root.
- Mounted-root paths have one documented resolution rule and do not depend on
  the shell's current working directory after being stored.
- `taskr create mount` accepts paths that point directly at a Taskr root and
  paths that point at the parent directory of a `taskr` subdirectory; stored
  configuration uses the resolved Taskr root path.
- Mount IDs have one documented validation rule. They appear in list, tree,
  show, report, generated site, errors, shell completion, and selectors.
- `taskr create mount <path> --id <id> --name <name>` creates a virtual
  root-level mount object in `taskr.toml`.
- `taskr create mount` accepts `--mode`, defaulting to `read-only` when omitted.
- `taskr create mount <path> --name <name>` derives a unique mount ID from the
  first word of the name by trying progressively longer lowercase prefixes.
- ID derivation fails clearly when all candidates from the first name word are
  already used or invalid.
- `taskr create milestone|task|subtask ... --mount <id>` creates work items in
  a read-write mounted root.
- `taskr create milestone|task|subtask ... --mount .` targets the current local
  root explicitly.
- `taskr create ... --mount <id> --under <selector>` resolves the parent inside
  the selected mounted root. Selectors may be written with or without the mount
  ID prefix when they are unambiguous inside that mount.
- `.:<selector>` addresses items in the current local root and works anywhere a
  mount-prefixed item selector is accepted.
- Creating work items through a read-only mount fails clearly without modifying
  any root.
- Creating work items through transitive read-write mounts is supported when
  the complete mount chain is writable.
- `taskr list --type mount` and `taskr show <id>` expose mount objects.
- `taskr reconfigure mount <searchterm/slug/id>` updates one or more mount
  parameters from the create surface, including `--name`, `--path`, and
  `--mode`.
- `taskr reconfigure mount` accepts quoted names containing spaces.
- `taskr remove mount <id>` removes only the local mount config entry and does
  not modify the mounted root.
- Mounted item selectors use the mount ID as a prefix, for example
  `vendor:003` and `vendor:workflow`.
- Local selectors keep their current behavior. ID and slug collisions across
  roots do not make the combined view ambiguous when a mount ID is used.
- Configured read-only mounted roots are loaded for `list`, `tree`, and `show`.
- Mounts are loaded transitively when mounted roots contain their own mounts.
- Cyclic mount references fail clearly and are not fixable by `doctor --fix`.
- Mount IDs are unique across the complete transitive mount graph.
- Transitive mount ID collisions fail clearly and are not fixable by
  `doctor --fix`.
- Resolving transitive mount ID collisions through aliases, temporary
  replacements, or similar explicit mappings is out of scope here and tracked
  in ticket 107.
- Mount objects are shown in overview output as root-level virtual items.
- Read-only mounted items participate in display, selector completion,
  full-text search, tag filtering, reports, generated sites, and references.
- Unavailable mounted roots fail with a clear diagnostic.
- Mutating commands against read-only mounted items fail clearly without
  modifying either the local root or the mounted root.
- Read-write mutations target the mounted root's files, not shadow copies in
  the parent root.
- Supported read-write mutations include `create`, `status`, `comment`, `move`,
  and `archive` unless a command-specific subticket explicitly defers behavior
  with user agreement.
- `open` supports mounted item selectors and must not silently open writable
  editors for read-only mounted roots.
- Root-local validations such as doctor distinguish local-root errors from
  mounted-root errors and report the mount ID in diagnostics.
- Default `taskr doctor` validates local structure, mount configuration, mount
  readability, and read-write mount writability, but does not deeply validate
  mounted item structure unless requested.
- `taskr doctor --include-mounts` follows mounts and validates mounted item
  structure. Read-only mounts are never fixed in place.
- `taskr doctor --fix` removes clearly broken local mount configuration entries
  when they are fixable.
- `taskr doctor --fix --include-mounts` fails when a read-only mounted root
  would need an in-place fix.
- `taskr doctor --fix` also respects mount mode for transitively mounted roots.
  It must not write through a read-only mount anywhere in the mount chain.
- Unavailable or unreadable mounted roots fail clearly by default.
- `taskr report` includes mounted-root work with source identity.
- Generated sites include mount objects and mounted items with mount-prefixed
  identity.
- Site search can find mounted IDs, slugs, and titles without colliding with
  local identity.
- Shell completion covers mount IDs and mounted item selectors at every command
  surface that accepts them.
- Shell completion covers the local-root placeholder `.` and transitive mount
  IDs wherever mount IDs or mount-prefixed selectors are accepted.
- Mutating-command completion suggests mounted selectors only when the command
  can legally mutate that mounted item.
- Documentation, help, and examples cover mounted read-only display,
  reconfiguration, removal, opening, commenting, moving, archiving, and
  read-write mutation.
- Smokey coverage includes mount creation, listing, updating, removal,
  mounted-root item creation, opening, commenting, moving, archiving, collision
  behavior, read-only mutation rejection, read-write mutation routing, doctor
  validation, unavailable mounted roots, transitive mounts, cyclic mount
  rejection, transitive mount ID collisions, generated site output, and
  completion.

# Comments

- 2026-08-17: Added while discussing references between Taskr trees and the
  possibility of read-only imported tickets.
- 2026-08-25: Michael refined the requirement from read-only include to mounted
  roots with read-only/read-write modes. A parent root should be able to show
  and optionally edit another Taskr root as if it were part of the visible tree,
  while mounted items remain distinguishable by a root ID used as a prefix
  before IDs and slugs.
- 2026-08-25: Temporarily split into subtasks 107-111, then folded back into
  this ticket after Michael clarified that 099 should carry the requirements
  and expectations directly.
- 2026-08-25: Decided that a mount is a virtual root-level Taskr object. Its
  `id` is the object ID and the selector/display prefix for mounted items.
  `taskr create mount` belongs to the object creation surface.
- 2026-08-25: If `create mount` has no explicit `--id`, derive it from the
  first word of `--name`; fail if that word cannot produce a free valid ID.
- 2026-08-25: `remove mount` means unmounting the external root from this Taskr
  root. It does not delete or alter the external root.
- 2026-08-25: Reconfiguration uses `taskr reconfigure mount <selector>` with
  one or more create-surface parameters. `create mount` and `reconfigure mount`
  both support `--mode`.
- 2026-08-25: `doctor --fix --include-mounts` must fail when a read-only
  mounted root would need an in-place fix.
- 2026-08-25: `create mount` may receive the parent directory of a Taskr root;
  the stored config path is the resolved Taskr root.
- 2026-08-25: Mount loading is transitive. Cyclic references are reported as
  non-fixable errors. Doctor fix mode must respect read-only mode across the
  whole transitive mount chain.
- 2026-08-25: Mount IDs must be unique across all transitive mounts. Collisions
  are reported by normal operation and doctor, and are not `--fix`-able.
- 2026-08-25: Follow-up ticket 107 tracks future user-controlled collision
  resolution mechanisms.
- 2026-08-25: Split implementation into command- and surface-specific
  subtickets below this ticket while keeping this ticket as the overall
  requirements package.
- 2026-08-25: Added `create ... --mount <id>` for creating milestones, tasks,
  and subtasks inside read-write mounted roots.
- 2026-08-25: Added `.` as the explicit current-root placeholder for mount
  selectors, for example `--mount .` and `taskr show .:005`. Completion must
  include `.` and transitive mount IDs.
- 2026-08-25: Added missing command-specific subtickets for `open`, `comment`,
  `move`, and `archive` surfaces.

- 2026-08-25 22:16: Blocked by accepted Smokey contract defects in subtasks 109, 112, 113, 116, 117, 118, and 123. Proposed corrections are preserved on their ticket-slug branches; nine independent command slices reached reviewing.

# Outcome

Implemented mounted Taskr roots across configuration, commands, validation,
reporting, generated sites, and completion with read-only/read-write routing
and transitive source-qualified identities.

# Release Notes

Taskr roots can now be mounted and used as source-qualified local or remote worktrees.
