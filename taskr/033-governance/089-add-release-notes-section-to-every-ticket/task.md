---
title: Add release notes section to every ticket
status: designing
created_at: 2026-08-12T13:05:13Z
updated_at: 2026-08-12T13:05:32Z
designing_at: 2026-08-12T13:05:32Z
---

# Description

Make `# Release Notes` a required section of every Taskr ticket that reaches
`done`. The section records the concise externally relevant consequence of the
ticket when users can notice the delivered change. Tickets without a
user-visible effect record the canonical explicit no-release-note decision in
the same section.

This ticket establishes the marker-format and validation invariant. Task `080`
defines the CLI completion workflow, aggregation, release-boundary handling,
and release-script integration that consume the section.

# Acceptance

- Every task or subtask marker in status `done` contains exactly one
  `# Release Notes` section.
- A ticket that delivers a user-visible behavior, command, output, format,
  workflow, compatibility, or documentation change contains a concise
  user-facing release note in that section.
- A ticket without a user-visible effect contains one canonical explicit
  no-release-note value in the section; an empty section is not sufficient for
  a `done` ticket.
- Tickets that have not reached `done` may contain an empty `# Release Notes`
  section while their release-note decision is still being developed.
- The canonical section position is defined relative to `# Description`,
  `# Acceptance`, `# Comments`, and `# Outcome`, and ticket templates generate
  it consistently.
- Release-note text does not duplicate the complete technical `# Outcome`; it
  describes the effect relevant to users and release readers.
- Doctor validates the required section and its nonempty note or explicit
  no-release-note value for every `done` ticket.
- Existing completed tickets have a documented migration path coordinated
  with task `080`; malformed or contradictory content is not silently treated
  as no release note.
- Taskr documentation and `AGENTS.md` state that a ticket may move to `done`
  only when its release-note section satisfies this invariant.
- Smokey covers a user-visible release note, explicit no-release-note content,
  an empty section, a missing section, duplicate sections, and unfinished
  tickets whose decision remains empty.

# Comments

- 2026-08-12: Clarified that the section is mandatory for every ticket in
  `done`, not only for tickets with user-visible changes. User visibility
  determines whether the section contains release-note text or the canonical
  no-release-note decision.

# Outcome
