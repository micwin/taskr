---
title: Route mounted item status changes
status: designing
created_at: 2026-08-25T17:20:20Z
updated_at: 2026-08-25T17:20:20Z
designing_at: 2026-08-25T17:20:20Z
---

# Description

Route `taskr status` to mounted items when the selector targets a read-write
mount and reject status mutations through read-only mounts.

# Acceptance

- `taskr status <mount-id>:<item> <status>` updates the mounted root's marker
  file when the mount chain is read-write.
- The parent root does not receive shadow copies or duplicated marker data.
- Status transition rules, timestamp updates, child/parent consistency, and
  terminal-parent rules remain enforced.
- Status changes through read-only mounts fail clearly without modifying any
  root.
- Transitive mount chains respect the strictest read-only mode in the chain.
- Help, docs, examples, and shell completion cover mounted status selectors.
- Smokey covers read-write success, read-only rejection, transitive read-only
  rejection, timestamp update, and unchanged parent root.

# Comments

- 2026-08-25: Status-specific mutation slice of ticket 099.

# Outcome
