---
title: Propagate ticket refinements into accepted sections
status: reviewing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-13T20:48:22Z
developing_at: 2026-08-13T20:36:05Z
reviewing_at: 2026-08-13T20:48:22Z
---

# Description

Define the policy that agreed ticket refinements must be reflected in the
ticket's main content, not only recorded as comments. Once consensus exists,
the ticket description, acceptance criteria, and Smokey tests should represent
the accepted behavior.

# Acceptance

- `AGENTS.md` explains that `# Comments` can record discussion history, but
  agreed refinements must be propagated into `# Description`, `# Acceptance`,
  and applicable Smokey tests.
- Once the user and agent reach consensus, propagation happens during the same
  refinement work rather than being deferred until implementation or closure.
- The policy preserves the lifecycle rule that after `designing`, changes to
  `# Description`, `# Acceptance`, or Smokey test program logic require
  explicit user interaction.
- The policy defines comments as supporting context, not the canonical source
  for agreed requirements.
- Existing tickets are not migrated in one repository-wide rewrite. A ticket
  whose accepted behavior exists only in Comments is corrected when that
  ticket is next actively refined, implemented, reviewed, or explicitly
  audited.
- Opportunistic migration must not change an inactive ticket's semantics
  without user interaction.

# Comments

- 2026-08-10: Added for later. During refinement, decisions should not remain
  hidden only in comment history when they are part of agreed behavior.
- 2026-08-13: Agreed that accepted refinements are propagated immediately.
  Existing tickets are corrected when next actively handled or audited rather
  than through a broad migration that could silently alter old semantics.

# Outcome

`AGENTS.md` now makes Description, Acceptance, and applicable Smokey logic the
canonical home of agreed requirements. Comments remain supporting history,
accepted refinements are propagated immediately, and existing tickets are
corrected when actively handled rather than through an unsafe bulk rewrite.
