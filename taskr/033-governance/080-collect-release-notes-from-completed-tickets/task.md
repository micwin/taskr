---
title: Collect release notes from completed tickets
status: developing
created_at: 2026-08-10T17:56:10Z
updated_at: 2026-08-17T08:11:53Z
designing_at: 2026-08-10T17:56:23Z
developing_at: 2026-08-17T08:11:53Z
---

# Description

Make release-note intent part of completing a Taskr ticket. A transition to
`done` must provide either a concise user-facing release note or an explicit
decision that the ticket needs no release note. The decision and note are
stored in the existing ticket marker file inside the Taskr root.

Taskr's own release preparation collects pending notes from completed Taskr
dogfood items and builds the Taskr changelog/release body from that data. This
ticket does not define a general public `taskr release-notes` command for every
managed project; that broader product surface needs separate design.

# Acceptance

- The design chooses a machine-readable representation inside the existing
  marker file, comparing an optional `# Release Notes` section with frontmatter
  metadata before implementation begins.
- The `done` transition requires exactly one of a release note or an explicit
  no-release-note decision for newly completed tickets.
- Closing Taskr dogfood tickets supports both decisions without requiring
  direct marker-file edits; proposed forms are `status ... done --release-note
  <text>` and `status ... done --no-release-note`.
- Multiline release notes have a documented stdin or file-input workflow.
- Release notes describe user-visible effects and do not duplicate the full
  technical `# Outcome`.
- The design explicitly defines whether the rule applies to tasks, subtasks,
  milestones, or a subset of those item types.
- Existing `done` items without release-note metadata remain readable and have
  a documented migration or leniency rule.
- Doctor checks every applicable `done` item for exactly one valid release-note
  decision: either release-note content or the explicit no-release-note marker.
- Doctor reports missing, empty, malformed, or contradictory release-note
  decisions with the affected item ID and marker path.
- `doctor --fix` migrates every applicable `done` item that has no release-note
  decision by adding the canonical explicit no-release-note marker.
- `doctor --fix` does not replace existing release-note content and does not
  silently resolve contradictory or malformed release-note decisions as
  no-release-note.
- Before writing, `doctor --fix` performs a complete preflight and prints every
  detected release-note problem, including contradictory or malformed values.
- If preflight finds any release-note problem that cannot be fixed safely, the
  command exits without modifying any ticket file; fixable missing decisions
  are not written partially.
- Release-note migration follows Doctor's existing temporary-worktree and
  atomic-apply behavior so a failed validation cannot leave a partially
  migrated Taskr root.
- Doctor fix output reports which item IDs were migrated and how many explicit
  no-release-note markers were added.
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
- Smokey covers note-bearing completion, explicit omission, missing intent,
  mutually exclusive flags, multiline input, legacy tickets, release-boundary
  selection, and prevention of duplicate notes.
- Doctor, help, completion, API behavior, release documentation, and examples
  are reviewed and updated for the final command surface.

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

# Outcome
