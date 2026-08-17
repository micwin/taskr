---
title: Collect release notes from completed tickets
status: cancelled
created_at: 2026-08-10T17:56:10Z
updated_at: 2026-08-17T08:34:12Z
designing_at: 2026-08-10T17:56:23Z
developing_at: 2026-08-17T08:28:22Z
reviewing_at: 2026-08-17T08:22:35Z
cancelled_at: 2026-08-17T08:34:12Z
---

# Description

Make release-note intent part of completing Taskr dogfood tickets for Taskr's
own release process. A closed dogfood ticket should provide either a concise
user-facing release note or an explicit decision that the ticket needs no
release note. The decision and note are stored in the existing ticket marker
file inside the Taskr root.

Taskr's own release preparation collects pending notes from completed Taskr
dogfood items and builds the Taskr changelog/release body from that data. This
ticket does not define any public Taskr product release behavior. Release code,
release-note collection, and release-specific validation belong in Taskr's
repository release tooling, not in `src/taskr`, public commands, command help,
completion, API behavior, or product Doctor behavior.

# Acceptance

- The design chooses a machine-readable representation inside the existing
  marker file, comparing an optional `# Release Notes` section with frontmatter
  metadata before implementation begins.
- Taskr dogfood closure policy requires exactly one of a release note or an
  explicit no-release-note decision for newly completed tickets.
- This ticket does not add `taskr status`, `taskr doctor`, or any other public
  Taskr command/flag for release handling.
- Release notes are entered by editing the existing Taskr dogfood marker file.
- Release notes describe user-visible effects and do not duplicate the full
  technical `# Outcome`.
- The design explicitly defines whether the rule applies to tasks, subtasks,
  milestones, or a subset of those item types.
- Existing `done` items without release-note metadata remain readable and have
  a documented migration or leniency rule.
- Release tooling omits tickets marked with the canonical explicit
  no-release-note marker.
- Release tooling fails when no release notes are available for the selected
  release boundary.
- Missing or contradictory release-note intent remains a Taskr governance
  problem for release preparation, but is not implemented in product Doctor in
  this ticket.
- Release preparation identifies notes completed since the previous published
  release and does not repeat already released notes.
- The release boundary is derived from version-control release metadata or is
  recorded inside Taskr items; no external project-specific data structure is
  mandatory.
- `scripts/release.sh` or a private helper script called by it renders the
  collected notes for Taskr's GitHub Release workflow.
- Taskr still maintains its repository `CHANGELOG.md`, but the release entry is
  generated from Taskr dogfood ticket release-note sections during Taskr's own
  release process.
- `AGENTS.md` requires release-note intent to be recorded in the same commit
  that moves a ticket to `done`.
- Smokey covers release-note rendering, explicit omission, no-note failure,
  changelog generation through Taskr's release script, and release-boundary
  selection.
- Release documentation is reviewed and updated. Product command help,
  completion, API behavior, and examples must remain unchanged because this
  ticket has no public Taskr command surface.

# Comments

- 2026-08-10: The repository's `## [Unreleased]` changelog section was
  initially considered as the staging area. That would impose a file outside
  the Taskr root on every managed project, so ticket marker files are the
  canonical source instead.
- 2026-08-10: A release note and an Outcome serve different audiences. The
  Outcome records what was delivered and verified; the release note is a short
  user-facing consequence suitable for aggregation.
- 2026-08-10: Candidate aggregation models are comparison with the previous
  release tag or persistent `released_in` metadata. The latter is explicit but
  requires a preparation change before the frozen release commit; tag-based
  collection avoids ticket mutation but must handle moves, archives, and legacy
  timestamps reliably.
- 2026-08-10: Doctor must enforce the completion invariant for `done` items.
  The exact release-note/no-release-note representation remains deliberately
  open during designing. Legacy completed tickets without either decision are
  migrated by `doctor --fix` to explicit no-release-note entries.
- 2026-08-17: Clarified scope with Michael: this is not a new general `taskr`
  command. The immediate need is Taskr's own release process collecting release
  notes from Taskr dogfood tickets into the Taskr changelog/release notes.
- 2026-08-17: Michael clarified further that release concerns have no place in
  Taskr product code at all. Release handling belongs to repository release
  tooling and governance only.
- 2026-08-17: Cancelled because the release-note/tooling work needs to wait
  for the dedicated release-process review in ticket 102.

# Outcome

Implemented as Taskr repository release tooling only:

- Added `scripts/collect-taskr-release-notes.sh` to collect `# Release Notes`
  sections from completed Taskr dogfood marker files.
- Kept release handling out of `src/taskr`, public Taskr commands, command
  help, completion, API behavior, and product Doctor behavior.
- Updated `scripts/release.sh` to generate the current `CHANGELOG.md` release
  entry from dogfood release notes when the exact `VERSION+BUILD` entry is
  missing.
- Updated `RELEASING.md` to describe the dogfood release-note source and
  generated changelog behavior.
- Updated `AGENTS.md` so Taskr dogfood closure commits record release-note
  intent in the same dedicated `done` commit.
- Added Smokey coverage for release-note collection, explicit no-release-note
  omission, no-note failure, release-boundary selection by Git tag, and
  changelog generation through `scripts/release.sh`.

# Release Notes

Taskr's release script now builds changelog release entries from completed
Taskr dogfood ticket release notes while keeping release handling out of the
Taskr product CLI.
