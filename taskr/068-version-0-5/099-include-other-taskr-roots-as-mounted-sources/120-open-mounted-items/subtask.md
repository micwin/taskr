---
title: Open mounted items
status: developing
created_at: 2026-08-25T17:30:59Z
updated_at: 2026-08-25T19:21:04Z
designing_at: 2026-08-25T17:30:59Z
developing_at: 2026-08-25T19:21:04Z
---

# Description

Extend `taskr open` so it accepts mounted item selectors and local-root
prefixed selectors.

Opening a mounted item must respect mount mode. Default editor mode implies an
editable marker and must reject read-only mounted roots. `--system` uses the
platform opener and may open read-only mounted roots because the command does
not promise write access.

# Acceptance

- `taskr open <mount-id>:<item>` opens the mounted item's marker path when the
  mount chain is read-write.
- `taskr open .:<item>` opens the local item's marker path.
- Read-only mounted roots fail clearly in default editor mode.
- Read-only mounted roots open successfully with `--system`.
- Mounted item selection reports source identity in command output.
- Missing, ambiguous, cyclic, unavailable, and duplicate-ID mount paths fail
  clearly.
- Local `open` behavior remains unchanged.
- Help, docs, examples, and shell completion cover mounted `open` selectors.
- Smokey covers read-write mounted open, read-only editor rejection,
  read-only `--system` open, `.:` selectors, invalid mounted selectors, and
  completion.

# Comments

- 2026-08-25: Added after reviewing 099 command coverage.
- 2026-08-25: Default editor mode is treated as writable. `--system` is
  treated as a display/open operation and may target read-only mounted roots.

# Outcome
