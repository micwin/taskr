---
title: Release via GitHub Actions
status: designing
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Publish release artifacts from a release branch through GitHub Actions, GitHub
Releases, and a changelog.

# Acceptance

- A GitHub Actions workflow builds release artifacts for supported platforms.
- Releases are created from a release branch and semantic version tag.
- GitHub Releases receive the built artifacts.
- A changelog entry is generated or maintained for the release.
- The release process is documented with required commands and prerequisites.

# Comments

- 2026-06-03: Release branch workflow and artifacts are part of the MVP delivery
  path.

# Outcome
