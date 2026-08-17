---
title: Review and gate Taskr release process
status: designing
created_at: 2026-08-17T08:31:52Z
updated_at: 2026-08-17T08:31:52Z
designing_at: 2026-08-17T08:31:52Z
---

# Description

Review and specify Taskr's release process as its own governed workflow before
changing release tooling further.

The work that introduced release-note collection mixed three concerns:

- creating or changing release helper scripts,
- preparing or executing an actual release,
- and adding release governance/policy.

That overlap made it too easy to patch `scripts/release.sh` opportunistically
while implementing a related but narrower ticket. This ticket exists to stop
that pattern: release behavior must have an explicit process contract, policy,
and gate before more release-script changes are made.

Release concerns remain outside Taskr product code. The scope here is Taskr's
repository release process, including scripts, GitHub Actions, changelog
generation, release-note collection, branch/tag handling, and local/CI gates.

# Acceptance

- The current release workflow is documented end to end, including what happens
  locally, what happens in GitHub Actions, and where release notes/changelog
  content comes from.
- The process explicitly separates:
  - release-tooling development,
  - release preparation,
  - release execution,
  - and release verification.
- The policy defines when release scripts may be changed and which active
  ticket must authorize those changes.
- The policy prevents opportunistic release-script edits while working on
  adjacent governance or release-note tickets.
- The gate defines the checks required before a release can be executed,
  including clean worktree, synchronized branches, release-note/changelog
  state, Doctor, Smokey, and CI expectations.
- The gate defines whether local release tooling may create commits, push
  commits, create or move branches, create tags, or only prepare output for the
  user to commit/push manually.
- The release process defines how generated changelog entries are reviewed and
  committed.
- The release process defines how `VERSION` and `BUILD` are treated and when
  they may change.
- The release process defines rollback/failure behavior for partial local or
  CI release attempts.
- Smokey or another automated check covers the agreed release gate where
  practical.
- `AGENTS.md`, `RELEASING.md`, and release-related tests are updated only after
  the process contract is agreed.
- No Taskr product command, product Doctor check, product help, product
  completion, or `src/taskr` release feature is added by this ticket.

# Comments

- 2026-08-17: Created after noticing that release-note collection work and
  release-script behavior had been mixed too freely. Michael wants release as a
  separate governed process with a policy and gate before more script changes.

# Outcome
