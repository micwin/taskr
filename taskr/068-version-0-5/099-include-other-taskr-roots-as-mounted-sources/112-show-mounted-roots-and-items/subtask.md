---
title: Show mounted roots and items
status: blocked
created_at: 2026-08-25T17:20:19Z
updated_at: 2026-08-25T20:13:08Z
designing_at: 2026-08-25T17:20:19Z
developing_at: 2026-08-25T18:27:51Z
blocked_at: 2026-08-25T20:13:08Z
---

# Description

Extend `taskr show` so it can display mount objects and mounted items by
ID-prefixed selectors.

# Acceptance

- `taskr show <mount-id>` shows the virtual mount object metadata.
- `taskr show <mount-id>:<item-id-or-slug>` shows the mounted item.
- Local selectors keep current behavior.
- Ambiguous unprefixed selectors fail with candidates that include enough
  source identity to choose a prefixed selector.
- Mounted item output includes source/mount identity.
- Read-only mounted items are displayed without attempting mutation.
- Help, docs, examples, and shell completion cover mounted show selectors.
- Smokey covers showing a mount object, showing a mounted item, local/mounted
  collision behavior, missing mounted selector, and completion.

# Comments

- 2026-08-25: Show-specific slice of ticket 099.

- 2026-08-25 22:13: Blocked on branch show-mounted-roots-and-items: accepted completion checks use grep '\t' in a basic regular expression, which does not match tab-delimited completion output. The branch uses Bash tab quoting.

# Outcome
