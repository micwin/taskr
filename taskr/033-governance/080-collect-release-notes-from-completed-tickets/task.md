---
title: Collect release notes from completed tickets
status: designing
created_at: 2026-08-10T17:56:10Z
updated_at: 2026-08-10T17:56:23Z
designing_at: 2026-08-10T17:56:23Z
---

# Description

Make release-note intent part of completing a Taskr ticket. A transition to
`done` must provide either a concise user-facing release note or an explicit
decision that the ticket needs no release note. The decision and note are
stored in the existing ticket marker file inside the Taskr root.

Release preparation collects pending notes from completed Taskr items and
builds the release body from that data. Projects must not be required to keep a
Taskr-specific `CHANGELOG.md`, staging file, or directory outside their Taskr
root. The tracked Taskr agent policy must require the same decision before an
agent completes a ticket.

# Acceptance

- The design chooses a machine-readable representation inside the existing
  marker file, comparing an optional `# Release Notes` section with frontmatter
  metadata before implementation begins.
- The `done` transition requires exactly one of a release note or an explicit
  no-release-note decision for newly completed tickets.
- The CLI supports both decisions without requiring direct marker-file edits;
  proposed forms are `--release-note <text>` and `--no-release-note`.
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
- `scripts/release.sh` or a Taskr command called by it renders the collected
  notes for the GitHub Release workflow.
- Projects may still maintain a conventional changelog, but Taskr release-note
  collection does not require one.
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

# Outcome
