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

The tracked `AGENTS.md` must contain repository policy only. References to
Jeff, Memory Castle, local agent infrastructure, and machine-specific contact
commands belong in the untracked local extension instead. The design should
also consider whether names such as `AGENTS.local.md` or `agents-repo.md` make
the distinction clearer than another `AGENTS.md`.

# Acceptance

- The design compares a file below `.git/info/` with an ignored working-tree
  overlay and selects one canonical location.
- The local instruction file is repository-specific and is not committed or
  shown as an untracked working-tree file during normal use.
- The tracked `AGENTS.md` documents how and when agents discover and read the
  local extension.
- Existing Jeff and Memory Castle references are removed from the tracked
  repository instructions and retained locally where needed.
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
- 2026-08-10: Two storage models remain under consideration. A file such as
  `.git/info/AGENTS.local.md` is a direct counterpart to `.git/info/exclude`:
  it is intrinsically checkout-local, cannot appear in normal Git status, and
  needs no ignore rule. Its disadvantages are that it lives in Git's internal
  metadata area, is less visible to humans and agents, is not discovered by
  normal repository file traversal, and needs careful handling for linked
  worktrees or nonstandard Git directories.
- 2026-08-10: A root-level `AGENTS.local.md` placed beside `AGENTS.md` is easier
  to discover, inspect, and explain. Adding it to `.git/info/exclude` keeps it
  local without imposing a shared `.gitignore` rule. Its disadvantages are
  that setup requires both the file and the local exclude entry, and a missing
  or damaged exclude entry can expose the file as untracked. The tracked
  `AGENTS.md` can reference either model generically without containing Jeff,
  Memory Castle, or other machine-specific instructions itself.

# Outcome
