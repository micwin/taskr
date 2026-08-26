---
title: Archive mounted items
status: blocked
created_at: 2026-08-25T17:31:00Z
updated_at: 2026-08-25T20:13:10Z
designing_at: 2026-08-25T17:31:00Z
developing_at: 2026-08-25T19:29:35Z
blocked_at: 2026-08-25T20:13:10Z
---

# Description

Extend `taskr archive` so closed subtrees in read-write mounted roots can be
archived in that mounted root.

# Acceptance

- `taskr archive <mount-id>:<item>` archives inside the mounted root when the
  mount chain is read-write.
- `taskr archive .:<item>` targets the local root explicitly.
- The archive destination is the mounted root's archive area, not the parent
  root's archive area.
- Read-only mounted roots fail clearly and leave every root unchanged.
- Existing closed-subtree rules remain enforced.
- Missing, ambiguous, cyclic, unavailable, and duplicate-ID mount paths fail
  clearly.
- Help, docs, examples, and shell completion cover mounted `archive` selectors.
- Smokey covers read-write mounted archive, read-only rejection, archive
  destination, unchanged parent root, and completion.

# Comments

- 2026-08-25: Added after reviewing 099 command coverage.

- 2026-08-25 22:13: Blocked on branch archive-mounted-items: the accepted transitive archive check first creates the same relative archive path in the direct mount and then requires that path not to exist. The branch gives the transitive case an isolated destination.

# Outcome
