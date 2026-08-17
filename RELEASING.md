# Releasing Taskr

Taskr development happens on `develop`. Releases are prepared on the dedicated
`release` branch. The `release` branch is the publication trigger: pushing it
runs GitHub Actions, which verifies, packages, tags, and publishes that exact
commit.

Release concerns belong to repository tooling and documentation, not Taskr
product commands.

## Prerequisites

- Work from a clean `develop` branch with no untracked files.
- Push the intended development commit to `origin/develop`.
- Confirm `VERSION` and `BUILD` contain the version to publish. Release builds
  do not increment either value.
- Keep `CHANGELOG.md` with a `## [Unreleased]` heading.
- Ensure completed Taskr dogfood tickets with user-visible changes contain a
  `# Release Notes` section. Tickets without user-visible release impact use
  `release_note: no-release-note` in frontmatter.
- Ensure local Go, Doctor, and Smokey verification is green before release
  preparation.

Normal builds increment `BUILD`. Release and CI builds instead use:

```bash
scripts/build.sh all --keep-build-count
```

`--keep-build-count` preserves both `VERSION` and `BUILD`, so the source
commit, embedded binary version, Debian version, artifact names, tag, and
GitHub Release all describe the same build.

## Prepare

From clean synchronized `develop`, run:

```bash
git push origin develop
```

Then run:

```bash
scripts/prepare-release.sh
```

The user is responsible for pushing `develop`; `prepare-release.sh` verifies
that local `develop` matches `origin/develop`. The script then switches to or
creates local `release`, fast-forwards it to the intended `develop` commit, and
prepares tracked release files there. It may modify files such as
`CHANGELOG.md`.

`prepare-release.sh` does not commit, push, tag, or publish. Review its changes
on `release` before continuing.

## Publish

From the prepared `release` branch, run:

```bash
scripts/release.sh
```

The script verifies the prepared release state, creates the release-preparation
commit on `release`, rejects an already published tag, and pushes `release`.
It does not modify `develop`.

The `Taskr Release` workflow then:

1. Reads the committed `VERSION+BUILD`.
2. Runs Go tests, Go vet, Doctor, and the complete Smokey suite.
3. Builds the Linux binary and Debian package with `--keep-build-count`.
4. Verifies embedded, package, and filename versions.
5. Generates SHA-256 checksums.
6. Creates or verifies tag `vVERSION+BUILD` on the release commit.
7. Publishes a GitHub Release with changelog notes and all artifacts.

GitHub Pages is not part of this workflow.

## Post Release

After GitHub Actions has published the release successfully, run:

```bash
scripts/post-release.sh
```

The script returns to `develop`, merges the released `release` branch back into
`develop`, raises the next development version, and commits that post-release
state. Patch is the default raise:

```bash
scripts/post-release.sh --raise-patch
scripts/post-release.sh --raise-minor
scripts/post-release.sh --raise-major
```

The version raise changes `VERSION` only. `BUILD` is preserved.

## Verification

After a successful Action run:

- Confirm the tag targets the expected release commit.
- Confirm the GitHub Release version matches `VERSION+BUILD`.
- Download the binary, Debian package, and checksum file.
- Verify checksums and run `taskr version` from the downloaded binary.

## Failed Releases

If preparation fails before `release` is pushed, fix the issue and rerun
`scripts/prepare-release.sh`.

If GitHub Actions fails before the tag step, fix the problem on `develop`,
prepare a new release branch state, and rerun `scripts/release.sh`.

If the tag exists and points to the correct commit, use GitHub Actions to rerun
the failed workflow. The workflow accepts that tag only when it resolves to the
same commit. Never move an existing release tag.

If the tag points to a different commit, stop and investigate. Both the local
release script and the Action intentionally refuse to overwrite it.
