---
title: Handle version raise flags in release preparation
status: done
created_at: 2026-08-17T09:35:24Z
updated_at: 2026-08-17T09:53:47Z
designing_at: 2026-08-17T09:35:24Z
developing_at: 2026-08-17T09:45:09Z
reviewing_at: 2026-08-17T09:46:58Z
done_at: 2026-08-17T09:53:47Z
---

# Description

Clarify and implement how release preparation handles version raise flags.

Observed behavior:

```bash
scripts/prepare-release.sh --raise-minor
```

currently ignores `--raise-minor` because `prepare-release.sh` does not parse
arguments. It then switches to `release` and reports the already prepared
current release version, for example:

```text
release already prepared version=0.1.0+82
```

That is misleading. If a release-preparation script receives a flag, it must
either implement that flag deliberately or reject it. Silent flag ignoring is
not acceptable for release tooling.

Version raising belongs to both release preparation and post-release, with
different semantics:

- `prepare-release.sh --raise-major` and `--raise-minor` select the version to
  release now.
- `post-release.sh` raises the next development version after the release has
  been published.

Current known policy: `post-release.sh` already raises the next development
version, with patch as default and explicit `--raise-minor`/`--raise-major`.

For release preparation, starting from `VERSION=1.2.3`:

- `--raise-major` prepares `2.0.0`.
- `--raise-minor` prepares `1.3.0`.
- Smaller version components are reset to `0`.
- `BUILD` remains unchanged.

# Acceptance

- `prepare-release.sh` rejects unknown arguments instead of ignoring them.
- `prepare-release.sh` supports `--raise-major` and `--raise-minor`.
- `prepare-release.sh` does not support implicit patch raising; with no raise
  flag, it prepares the current `VERSION+BUILD`.
- `prepare-release.sh --raise-major` increments major and resets minor and
  patch to `0`.
- `prepare-release.sh --raise-minor` increments minor and resets patch to `0`.
- `prepare-release.sh` preserves `BUILD` for every raise mode.
- `prepare-release.sh` updates `VERSION` on the `release` branch before
  generating the release changelog entry.
- `--raise-major` and `--raise-minor` are mutually exclusive.
- Smokey covers the chosen behavior for `prepare-release.sh --raise-minor`.
- Smokey covers `prepare-release.sh --raise-major`.
- Smokey covers mutually exclusive raise flags.
- Smokey covers at least one unknown flag and verifies it fails before
  switching branches or modifying files.
- `RELEASING.md` documents the chosen behavior.
- The fix stays in release tooling/tests/documentation and does not change
  Taskr product code.

# Comments

- 2026-08-17: Created after Michael ran `scripts/prepare-release.sh
  --raise-minor` and the script silently ignored the flag, switched to
  `release`, and reported the existing prepared version.

# Outcome

Implemented argument handling for `scripts/prepare-release.sh`.

- Unknown options now fail before branch switching or file modification.
- `--raise-major` and `--raise-minor` are supported and mutually exclusive.
- `--raise-major` increments major and resets minor and patch to `0`.
- `--raise-minor` increments minor and resets patch to `0`.
- `BUILD` remains unchanged.
- The selected `VERSION` is written on the `release` branch before generating
  the release changelog entry.
- `RELEASING.md` documents the prepare-time raise flags.
- Smokey covers minor raise, major raise, mutually exclusive flags, unknown
  flags, branch behavior, changelog headers, and unchanged `BUILD`.

# Release Notes

`scripts/prepare-release.sh` now supports explicit major and minor release
version raises and rejects unknown or conflicting options instead of silently
ignoring them.
