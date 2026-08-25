---
title: Expose mounted roots in site report and completion
status: designing
created_at: 2026-08-25T16:28:13Z
updated_at: 2026-08-25T16:28:13Z
designing_at: 2026-08-25T16:28:13Z
---

# Description

Expose mounted roots consistently in generated sites, reports, and shell
completion after the core mounted-root selector model exists.

# Acceptance

- `taskr report` includes mounted-root work with source identity or documents
  any intentionally local-only report behavior.
- Generated site data includes mounted-root items with mount-prefixed identity.
- Site search can find mounted IDs, slugs, and titles without colliding with
  local identity.
- Shell completion suggests mounted selectors at every read-only surface that
  accepts them.
- Mutating-command completion suggests mounted selectors only when the command
  can legally mutate that mounted item.
- Documentation and examples cover mounted read-only display and read-write
  mutation at least once each.
- Smokey covers report output, generated site data, and selector completion for
  mounted roots.

# Comments

- 2026-08-25: Depends on 108 and 109.

# Outcome
