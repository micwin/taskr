---
title: Define implementation scope policy
status: open
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Define how narrowly implementation work must follow the active Taskr ticket and
how to handle related issues discovered while implementing.

# Acceptance

- The policy distinguishes direct ticket work from follow-up work.
- Close supporting work may be completed inside the active ticket when required
  to satisfy its acceptance criteria.
- Behavior, model, command, flag, or workflow changes outside the active ticket
  are captured as new Taskr tickets instead of being implemented silently.
- Ambiguous scope or semantic model changes require asking the user before
  editing.
- The policy is documented where future implementation tickets can reference it.

# Comments

- 2026-08-07: Created after `010-minimal-binary` exposed a scope boundary:
  adding command flags was useful and aligned with prior command design, but it
  reached beyond the narrowest reading of the ticket.
- 2026-08-07: Moved from the MVP implementation subtree to the Dogfood
  milestone because Taskr process-policy tickets are dogfood work.

# Outcome
