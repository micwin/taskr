---
title: Translate user docs examples to English
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Remove German wording from user-facing README and documentation examples so the
published docs are consistently English.

# Acceptance

- `README.md` uses English example slugs.
- `doc/taskr-worktree-format.md` uses English example slugs.
- `doc/taskr-workflows.md` contains no German wording.
- Historical dogfood ticket paths and committed Smokey fixtures are not renamed
  as part of this documentation cleanup.
- A search verifies that README and `doc/` no longer contain German words or
  umlauts.

# Comments

- 2026-08-07: Repo-wide search still finds German slugs in historical dogfood
  ticket paths and Smokey fixtures. Those are item identities/test fixtures and
  should only be renamed through a separate migration ticket.

# Outcome

Translated remaining German example slugs in user-facing docs:

- `002-verzeichnisstruktur` -> `002-directory-structure`
- `003-workflows-definieren` -> `003-define-workflows`
- `004-erste-kommandos` -> `004-first-commands`

Updated files:

- `README.md`
- `doc/taskr-worktree-format.md`

Verification:

- Searched `README.md` and `doc/` for German umlauts and known German example
  words; no matches remain.
- Repo-wide search still finds historical German slugs in dogfood ticket paths
  and Smokey fixtures. Those are item identities/test fixtures and were left
  unchanged.
