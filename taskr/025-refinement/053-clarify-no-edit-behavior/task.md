---
title: Clarify no-edit behavior
status: designing
created_at: 2026-08-10T10:50:04Z
updated_at: 2026-08-10T10:50:04Z
---

# Description

Clarify the purpose and default behavior of `--no-edit` for item creation.
Current examples often end with `--no-edit`, which may make the normal CLI
workflow look more verbose than intended and may hide the expected editor-first
behavior.

# Acceptance

- The intended default for `taskr create` is explicitly decided: open editor by
  default, do not open editor by default, or use context/config-dependent
  behavior.
- The relationship between `--edit`, `--no-edit`, `$EDITOR`, and personal
  Taskr config is documented.
- Examples show the normal interactive workflow without unnecessary ceremony.
- Examples still show non-interactive/scripted creation where `--no-edit` is
  useful.
- Help text clearly describes when `--no-edit` should be used.
- Smokey tests cover the chosen default create behavior and explicit
  `--no-edit` behavior.
- Any command behavior change updates documentation, help, examples, completion
  if needed, and public workflow docs before closure.

# Comments

- 2026-08-10: Added after noticing that many examples use `--no-edit`, which
  may be correct for tests but questionable as the primary user-facing
  workflow.

# Outcome
