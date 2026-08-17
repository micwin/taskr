---
title: Handle version raise flags in release preparation
status: designing
created_at: 2026-08-17T09:35:24Z
updated_at: 2026-08-17T09:35:24Z
designing_at: 2026-08-17T09:35:24Z
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

The design must clarify whether version raising belongs to:

- `prepare-release.sh` before preparing the release,
- `post-release.sh` after publishing, or
- both, with different semantics.

Current known policy: `post-release.sh` already raises the next development
version, with patch as default and explicit `--raise-minor`/`--raise-major`.

# Acceptance

- `prepare-release.sh` rejects unknown arguments instead of ignoring them.
- The workflow explicitly documents whether `prepare-release.sh` supports
  `--raise-major`, `--raise-minor`, and `--raise-patch`.
- If `prepare-release.sh` supports raise flags, the script updates `VERSION` on
  the `release` branch before generating the release changelog entry, while
  preserving `BUILD`.
- If `prepare-release.sh` does not support raise flags, it exits non-zero with
  a clear message that version raising belongs to `post-release.sh` or another
  documented step.
- Smokey covers the chosen behavior for `prepare-release.sh --raise-minor`.
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
