---
title: Define implementation scope policy
status: done
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
- Status changes that close delivery work are committed together with the
  changes and outcome that justify the new status.

# Comments

- 2026-08-07: Created after `010-minimal-binary` exposed a scope boundary:
  adding command flags was useful and aligned with prior command design, but it
  reached beyond the narrowest reading of the ticket.
- 2026-08-07: Moved from the MVP implementation subtree to the Dogfood
  milestone because Taskr process-policy tickets are dogfood work.
- 2026-08-07: Added the policy to `AGENTS.md` so future implementation work can
  apply it before making changes.
- 2026-08-07: Added commit coupling for ticket status changes: when delivery
  work is closed as done, the status, outcome, and intended file changes belong
  in the same commit.

# Outcome

Defined the implementation scope policy in `AGENTS.md`.

The policy says agents must work from the active Taskr ticket and keep changes
close to that ticket's description and acceptance criteria. Directly required
supporting work and small same-surface corrections may be done inside the active
ticket. Discovered behavior, model, command, flag, workflow, validation,
release, or agent-process changes outside the active ticket must become new
Taskr tickets instead of being implemented silently. Ambiguous scope and
semantic changes require asking the user before editing.

The policy also requires status-changing decisions to be committed with their
corresponding file changes. When a ticket is closed as `done`, the same commit
must contain the status update, `# Outcome`, and the changes that make the
ticket done. Non-delivery closures such as `cancelled` do not need accompanying
implementation changes.
