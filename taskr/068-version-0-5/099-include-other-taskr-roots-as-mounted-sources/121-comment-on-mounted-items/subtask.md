---
title: Comment on mounted items
status: reviewing
created_at: 2026-08-25T17:30:59Z
updated_at: 2026-08-25T20:15:44Z
designing_at: 2026-08-25T17:30:59Z
developing_at: 2026-08-25T19:23:32Z
reviewing_at: 2026-08-25T20:15:44Z
---

# Description

Extend `taskr comment` so comments can be appended to items in read-write
mounted roots.

# Acceptance

- `taskr comment <mount-id>:<item> <text>` appends the comment to the mounted
  root's marker file when the mount chain is read-write.
- `taskr comment .:<item> <text>` targets the local root explicitly.
- Read-only mounted roots fail clearly and leave every root unchanged.
- Comment timestamp and text normalization rules remain unchanged.
- The parent root does not receive shadow copies or duplicated marker data.
- Missing, ambiguous, cyclic, unavailable, and duplicate-ID mount paths fail
  clearly.
- Help, docs, examples, and shell completion cover mounted `comment` selectors.
- Smokey covers read-write mounted comment, read-only rejection, transitive
  read-only rejection, `.:` selectors, unchanged parent root, and completion.

# Comments

- 2026-08-25: Added after reviewing 099 command coverage.

# Outcome

Comments route to direct and transitive writable mounted markers while
read-only chains remain unchanged.

# Release Notes

`taskr comment` supports writable mount-prefixed selectors.
