---
title: Release via GitHub Actions
status: developing
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-08-10T16:53:08Z
developing_at: 2026-08-10T16:53:08Z
---

# Description

Publish verified release artifacts from a dedicated `release` branch through
GitHub Actions and GitHub Releases. Day-to-day work remains on `develop`.

The release uses the exact committed values already present in `VERSION` and
`BUILD`; neither the release script nor GitHub Actions raises either value.
`scripts/build.sh all --keep-build-count` builds that frozen version without
incrementing `BUILD`.

# Acceptance

- `scripts/build.sh` supports `--keep-build-count`, which uses the current
  `VERSION` and `BUILD` values without modifying either file.
- Normal builds continue to increment the global build counter exactly once.
- `scripts/release.sh` runs only from a clean, synchronized `develop` branch,
  verifies release prerequisites, fast-forwards the dedicated `release`
  branch, pushes it, and returns to `develop`.
- Release preparation does not create a version bump. The desired `VERSION`,
  `BUILD`, changelog, and source state must already be committed on `develop`.
- A normal CI workflow verifies pushes and pull requests without publishing a
  release.
- CI and release gates run Go tests, Go vet, Taskr Doctor, and the complete
  Smokey suite before packaging or publishing.
- A push to `release` runs the release workflow and builds through
  `scripts/build.sh all --keep-build-count`.
- The workflow verifies that the binary, Debian package, artifact filenames,
  and release metadata all use the exact committed `VERSION+BUILD` value.
- The release workflow creates the semantic version tag
  `v<major>.<minor>.<patch>+<build>` on the released commit.
- If that tag already exists on another commit, the workflow fails instead of
  silently reusing or moving it.
- GitHub Releases receive at least the Debian package, Linux binary, and a
  checksum file for all published artifacts.
- The changelog entry for the released version is maintained in the repository
  and used for the GitHub Release notes.
- GitHub Pages deployment is outside this ticket and remains tracked by ticket
  `009`.
- The release process is documented with prerequisites, local commands,
  expected Action behavior, verification steps, rerun behavior, and recovery
  from a failed release.
- Smokey covers build-count preservation and locally testable release-script
  behavior; the GitHub workflow receives an appropriate static or local
  workflow validation check.

# Comments

- 2026-06-03: Release branch workflow and artifacts are part of the MVP delivery
  path.
- 2026-08-10: Adopted Smokey's `develop` to `release` branch pattern with
  stricter test and version-consistency gates. Unlike Smokey, Taskr keeps Pages
  separate and publishes the already committed `VERSION+BUILD` without a
  release-time increment. The frozen-build flag is named
  `--keep-build-count`.
- 2026-08-10: GitHub connector inspection confirmed that `micwin/taskr` is
  public, uses `develop` as its default branch, grants the connector admin and
  push access, and has no existing `release` branch. The workflow needs no
  additional repository secret because its scoped `GITHUB_TOKEN` receives
  `contents: write`; branch protection and global Actions policy are not
  exposed through the connector.
- 2026-08-10: Local verification passes with Go tests, Go vet, Doctor,
  actionlint 1.7.7, frozen binary and Debian version checks, and all 23 Smokey
  workflows. The first real GitHub Actions run remains pending until the
  implementation is committed and pushed by explicit user instruction.
- 2026-08-10: CI run `31413032135` passed on GitHub. The first release run
  `31413129475` built and verified `0.1.0+37`, then failed before tagging because
  release-note extraction required an exact changelog heading and did not
  accept the documented date suffix. The parser and regression coverage were
  corrected for release candidate `0.1.0+38`.
- 2026-08-10: Release run `31413818569` passed release-note extraction and
  artifact verification, then failed before creating `v0.1.0+38` because the
  runner had no Git identity for its annotated tag. The workflow now configures
  the local `github-actions[bot]` identity before creating a missing tag.
- 2026-08-10: Release run `31414068183` successfully published `v0.1.0+39`.
  Download verification found that its checksum entries retained the build-time
  `dist/` prefix and therefore were not directly verifiable beside the flat
  GitHub assets. Candidate `0.1.0+40` generates basename-only checksum entries.

# Outcome
