---
title: Require doctor and help check before closing code tickets
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Require agents to check whether `doctor` and command help cover relevant code
changes before closing a Taskr ticket.

# Acceptance

- `AGENTS.md` tells agents to verify `doctor` coverage before closing tickets
  after relevant code changes.
- `AGENTS.md` tells agents to verify command-help coverage before closing
  tickets after relevant code changes.
- Missing `doctor` or help coverage is handled in-scope when appropriate or
  captured as a follow-up ticket before closing.

# Comments

- 2026-08-07: Added because Taskr behavior changes should stay discoverable via
  CLI help and guarded by `doctor` where relevant.

# Outcome

Added the pre-close `doctor` and command-help coverage check to `AGENTS.md`.
When relevant code changes are made, an agent must check whether `doctor` and
help already reflect those changes before closing the ticket. Missing coverage
must be implemented inside the ticket when in scope or recorded as a follow-up
ticket before closure.
