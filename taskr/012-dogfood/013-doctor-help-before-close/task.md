---
title: Require doctor, help, completion, and API checks before closing code tickets
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Require agents to check whether `doctor`, command help, shell completion, and
any public API cover relevant code changes before closing a Taskr ticket.

# Acceptance

- `AGENTS.md` tells agents to verify `doctor` coverage before closing tickets
  after relevant code changes.
- `AGENTS.md` tells agents to verify command-help coverage before closing
  tickets after relevant code changes.
- `AGENTS.md` tells agents to verify shell-completion coverage before closing
  tickets after relevant code changes.
- `AGENTS.md` tells agents to verify public API coverage before closing tickets
  after relevant code changes when a public API exists.
- Missing `doctor`, help, completion, or API coverage must be fixed in the
  active ticket before closing it.

# Comments

- 2026-08-07: Added because Taskr behavior changes should stay discoverable via
  CLI help and guarded by `doctor` where relevant.
- 2026-08-07: Tightened the rule: stale `doctor` or help coverage blocks
  closing the active ticket instead of becoming a follow-up ticket.
- 2026-08-07: Extended the rule to shell completion and public API surfaces.
  Taskr has Cobra shell completion already, no separate tabtab integration, and
  no public API yet.

# Outcome

Added the pre-close `doctor`, command-help, shell-completion, and public-API
coverage check to `AGENTS.md`. When relevant code changes are made, an agent
must check whether those surfaces already reflect the changes before closing the
ticket. Missing coverage must be implemented inside the active ticket before
closure.
