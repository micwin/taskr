# Releasing Taskr

Taskr development happens on `develop`. The dedicated `release` branch is a
publication trigger: `scripts/release.sh` fast-forwards it to the already
committed and pushed `develop` head. GitHub Actions then verifies, packages,
tags, and publishes that exact commit.

## Prerequisites

- Work on `develop` and push the intended release commit to `origin/develop`.
- Keep the worktree and index clean, including untracked files.
- Confirm `VERSION` and `BUILD` contain the version to publish. The release
  process does not increment either value.
- Add a `CHANGELOG.md` heading in the form `## [VERSION+BUILD]`, for example
  `## [0.1.0+37]`.
- Ensure local Go, Doctor, and Smokey verification is green before release.

Normal builds increment `BUILD`. Release and CI builds instead use:

```bash
scripts/build.sh all --keep-build-count
```

`--keep-build-count` preserves both `VERSION` and `BUILD`, so the source
commit, embedded binary version, Debian version, artifact names, tag, and
GitHub Release all describe the same build.

## Publish

From a clean and synchronized `develop` branch, run:

```bash
scripts/release.sh
```

The script fetches `origin`, rejects unpushed or divergent `develop` work,
checks the changelog entry, rejects an already published tag, checks out or
creates `release`, requires a fast-forward from `develop`, pushes `release`,
and returns to `develop`.

The `Taskr Release` workflow then:

1. Reads the committed `VERSION+BUILD`.
2. Runs Go tests, Go vet, Doctor, and the complete Smokey suite.
3. Builds the Linux binary and Debian package with `--keep-build-count`.
4. Verifies embedded, package, and filename versions.
5. Generates SHA-256 checksums.
6. Creates or verifies tag `vVERSION+BUILD` on the release commit.
7. Publishes a GitHub Release with changelog notes and all artifacts.

GitHub Pages is not part of this workflow.

## Verification

After a successful Action run:

- Confirm the tag targets the expected release commit.
- Confirm the GitHub Release version matches `VERSION+BUILD`.
- Download the binary, Debian package, and checksum file.
- Verify checksums and run `taskr version` from the downloaded binary.

## Failed Releases

If verification or packaging fails before the tag step, fix the problem on
`develop`, update `BUILD` through a normal build, update the changelog heading,
commit and push, then run `scripts/release.sh` again.

If the tag exists and points to the correct commit, use GitHub Actions to rerun
the failed workflow. The workflow accepts that tag only when it resolves to the
same commit. Never move an existing release tag.

If the tag points to a different commit, stop and investigate. Both the local
release script and the Action intentionally refuse to overwrite it.
