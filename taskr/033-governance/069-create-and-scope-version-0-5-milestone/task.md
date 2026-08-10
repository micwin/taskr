---
title: Create and scope Version 0.5 milestone
status: developing
created_at: 2026-08-10T14:18:39Z
updated_at: 2026-08-10T14:20:26Z
designing_at: 2026-08-10T14:18:39Z
developing_at: 2026-08-10T14:20:26Z
---

# Description

Create a dedicated `Version 0.5` milestone and rescope the agreed upcoming work
into it. Perform the structural changes with Taskr commands so root identity,
hierarchy checks, and move constraints remain authoritative.

# Acceptance

- A milestone titled `Version 0.5` exists in status `designing`.
- Task `008` (`Release via GitHub Actions`) is moved from `GitHub integration`
  to `Version 0.5`.
- Task `009` (`Create concise GitHub Pages site`) is moved from
  `GitHub integration` to `Version 0.5`.
- Task `026` (`Move Smokey shared environment setup to preload`) is moved from
  `Refinement` to `Version 0.5`.
- Task `043` (`Require examples for command variants`) is moved from
  `Refinement` to `Version 0.5`.
- Task `046` (`Validate open parents for new items`) is moved from `Governance`
  to `Version 0.5`.
- Task `052` (`Rename items`) is moved from `Refinement` to `Version 0.5`.
- Task `061` (`Analyze priorities`) is moved from `Refinement` to
  `Version 0.5`.
- Every moved task retains its ID, slug, marker content, and `designing` status.
- The existing `GitHub integration` milestone remains in place for an explicit
  later decision even when it has no child tasks.
- `taskr doctor` passes after the rescope operation.
- The ticket creation is committed before the separate commit that records the
  milestone creation, moves, and eventual ticket closure.

# Comments

- 2026-08-10: Planned Version 0.5 scope is `008`, `009`, `026`, `043`, `046`,
  `052`, and `061`; all are currently in `designing`.

# Outcome
