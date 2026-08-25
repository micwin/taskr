---
title: Open mounted items
status: designing
created_at: 2026-08-25T17:30:59Z
updated_at: 2026-08-25T17:30:59Z
designing_at: 2026-08-25T17:30:59Z
---

# Description

Extend `taskr open` so it accepts mounted item selectors and local-root
prefixed selectors.

Opening a mounted item must respect mount mode. A read-only mounted root must
not be opened in a way that implies editable writes without explicit policy.

# Acceptance

- `taskr open <mount-id>:<item>` opens the mounted item's marker path when the
  mount chain is read-write.
- `taskr open .:<item>` opens the local item's marker path.
- Read-only mounted roots either fail clearly for editor mode or use an
  explicitly documented read-only/system-open behavior.
- Mounted item selection reports source identity in command output.
- Missing, ambiguous, cyclic, unavailable, and duplicate-ID mount paths fail
  clearly.
- Local `open` behavior remains unchanged.
- Help, docs, examples, and shell completion cover mounted `open` selectors.
- Smokey covers read-write mounted open, read-only behavior, `.:` selectors,
  invalid mounted selectors, and completion.

# Comments

- 2026-08-25: Added after reviewing 099 command coverage.

# Outcome
