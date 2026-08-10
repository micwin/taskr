---
title: Support local agent instructions
status: designing
created_at: 2026-08-10T16:57:29Z
updated_at: 2026-08-10T16:57:30Z
designing_at: 2026-08-10T16:57:30Z
---

# Description

Define a local extension mechanism for repository `AGENTS.md` instructions.
The local policy must apply to agents working in this checkout while remaining
outside version control, comparable to repository-specific ignore rules in
`.git/info/exclude`.

The design must choose a discoverable local file location and make the tracked
`AGENTS.md` instruct agents to load it when present. Local instructions extend
the shared repository policy; precedence and conflict handling must be explicit
so a private overlay cannot silently invalidate required project safeguards.

# Acceptance

- The design compares a file below `.git/info/` with an ignored working-tree
  overlay and selects one canonical location.
- The local instruction file is repository-specific and is not committed or
  shown as an untracked working-tree file during normal use.
- The tracked `AGENTS.md` documents how and when agents discover and read the
  local extension.
- Missing local instructions are a normal no-op and do not produce warnings.
- Precedence between global, tracked repository, nested, and local instructions
  is defined explicitly.
- Local instructions may add machine- or user-specific guidance but may not
  weaken security, secret-handling, commit, lifecycle, or destructive-operation
  safeguards from tracked policy.
- Behavior for a malformed, unreadable, or unexpectedly versioned local file is
  defined.
- Setup and verification instructions allow a user to create and inspect the
  local policy without exposing its contents in commits or command output.
- The design determines whether Taskr needs a supporting command or whether a
  documented Git/agent convention is sufficient.
- Relevant governance documentation and agent checks are updated before the
  ticket is closed.

# Comments

- 2026-08-10: Added while implementing GitHub Releases. The requested model is
  analogous to `.git/info/exclude`: checkout-local agent guidance that extends
  the committed `AGENTS.md` without entering Git history.

# Outcome
