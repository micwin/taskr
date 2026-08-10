---
title: Manage project configuration
status: designing
created_at: 2026-08-10T18:21:51Z
updated_at: 2026-08-10T18:21:51Z
designing_at: 2026-08-10T18:21:51Z
---

# Description

Add a general CLI for inspecting and changing project-local `taskr.toml`
configuration. The command replaces feature-specific reconfiguration flags;
the first concrete use case is changing `[site].directory` after `site init`.

# Acceptance

- The command surface supports reading, setting, and removing supported
  project configuration values without direct file editing.
- Operations use typed schema keys rather than unrestricted textual TOML
  mutation.
- Changes preserve unrelated supported tables, keys, and comments.
- Invalid keys, values, paths, and malformed existing configuration fail
  without partially rewriting `taskr.toml`.
- The design defines command names and syntax, including whether the surface is
  `taskr config get|set|unset|list`.
- Site-directory changes validate ownership and explain what happens to the
  previous generated directory without deleting it implicitly.
- Smokey covers reads, writes, removals, preservation, validation failures, and
  completion for known keys and values.
- Help, examples, completion, Doctor, documentation, and API behavior are
  updated for the final command surface.

# Comments

- 2026-08-10: Created instead of adding `site init --reconfigure`. Project
  configuration should have one reusable manipulation workflow as additional
  `taskr.toml` tables appear.

# Outcome
