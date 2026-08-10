---
title: Propagate ticket refinements into accepted sections
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
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
- The policy preserves the lifecycle rule that after `designing`, changes to
  `# Description`, `# Acceptance`, or Smokey test program logic require
  explicit user interaction.
- The policy defines comments as supporting context, not the canonical source
  for agreed requirements.
- Existing tickets that rely on comments for accepted behavior are identified
  or corrected when this policy is implemented.

# Comments

- 2026-08-10: Added for later. During refinement, decisions should not remain
  hidden only in comment history when they are part of agreed behavior.

# Outcome
