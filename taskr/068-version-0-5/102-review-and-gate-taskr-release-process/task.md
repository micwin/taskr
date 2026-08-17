---
title: Review and gate Taskr release process
status: done
created_at: 2026-08-17T08:31:52Z
updated_at: 2026-08-17T09:23:04Z
designing_at: 2026-08-17T08:31:52Z
developing_at: 2026-08-17T08:56:36Z
reviewing_at: 2026-08-17T09:00:47Z
done_at: 2026-08-17T09:23:04Z
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

Target workflow:

1. `scripts/prepare-release.sh` is invoked from a clean `develop` branch.
   After the initial `develop` preflight, it switches to or creates the local
   `release` branch, fast-forwards it to the intended `develop` commit, and
   prepares the release on `release`.
2. `prepare-release.sh` may modify tracked release-preparation files on
   `release`, such as `CHANGELOG.md`, but it does not commit, push, create
   tags, or publish anything.
3. The user reviews the generated `release` branch changes.
4. `scripts/release.sh` runs only on the `release` branch. It verifies the
   prepared release state, creates the release-preparation commit on `release`,
   pushes `release`, and does not modify `develop`.
5. Pushing `release` triggers GitHub Actions, where verification, artifact
   creation, release tagging, and GitHub Release publication happen.
6. `scripts/post-release.sh` runs after a successful release. It returns to
   `develop`, merges the released `release` branch back into `develop`, raises
   the next development version, and leaves or creates the corresponding commit
   according to the documented policy.

# Acceptance

- The current release workflow is documented end to end, including what happens
  locally, what happens in GitHub Actions, and where release notes/changelog
  content comes from.
- The canonical release documentation is `RELEASING.md`. If that document is
  removed or unavailable in the future, the workflow must live in a runbook or
  `README.md` instead.
- `AGENTS.md` refers agents to the canonical release-process documentation
  without duplicating the process inline.
- The documented workflow contains separate `scripts/prepare-release.sh`,
  `scripts/release.sh`, and `scripts/post-release.sh` steps.
- `prepare-release.sh` must be invoked from clean `develop`, but after the
  initial preflight all preparation changes are made on the local `release`
  branch.
- `prepare-release.sh` is allowed to modify preparation files on `release`, but
  must not commit, push, create tags, or publish releases.
- `release.sh` runs only on `release`, verifies the prepared release state,
  creates the release-preparation commit on `release`, pushes `release`, and
  must not modify `develop`.
- `post-release.sh` runs after a successful release, merges `release` back into
  `develop`, and prepares the next development version.
- `post-release.sh` clears the `## [Unreleased]` changelog staging section
  while preserving all versioned changelog sections, and commits that cleanup
  with the next development version.
- Post-release version raising supports `--raise-major`, `--raise-minor`, and
  `--raise-patch`, with `--raise-patch` as the default.
- Tag creation remains in the GitHub Actions release workflow after all release
  verification has passed.
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
- The gate defines exactly which local release step may create commits, push
  commits, create or move branches, or create tags.
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

Implemented the release workflow as a repository-only three-step process:

- Added `scripts/prepare-release.sh`, invoked from clean synchronized
  `develop`, which switches to `release` and prepares release files there
  without committing, pushing, tagging, or publishing.
- Reworked `scripts/release.sh` to run only on `release`, verify the prepared
  changelog/version/tag state, create the release-preparation commit, and push
  `release`.
- Added `scripts/post-release.sh`, which merges the released branch back into
  `develop` and raises the next development `VERSION` with patch as default
  plus `--raise-minor` and `--raise-major`. It also clears the `## [Unreleased]`
  changelog staging section while preserving versioned release entries.
- Updated `RELEASING.md` as the canonical release workflow document.
- Added the `AGENTS.md` pointer to `RELEASING.md` without duplicating the
  workflow inline.
- Updated release Smokey coverage for prepare/release/post-release behavior and
  kept release-note collection in the preparation step.

# Release Notes

Taskr releases now use separate prepare, release, and post-release scripts so
release preparation can be reviewed before the release branch is committed and
published.
