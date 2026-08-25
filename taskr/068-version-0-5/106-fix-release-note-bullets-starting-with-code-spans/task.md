---
title: Fix release note bullets starting with code spans
status: reviewing
created_at: 2026-08-23T12:42:08Z
updated_at: 2026-08-25T16:21:37Z
designing_at: 2026-08-23T12:42:08Z
developing_at: 2026-08-25T16:17:11Z
reviewing_at: 2026-08-25T16:21:37Z
---

# Description

Fix release-note extraction so separate release-note bullets that start with a
code span remain separate bullets in the GitHub Release body.

During the `0.3.0+82` release, the generated `CHANGELOG.md` section was
manually corrected to three Markdown bullets, but the published GitHub Release
body collapsed the second and third bullets into continuations of the first
bullet because those lines started with backticks. That behavior comes from the
release-note normalization added for accidentally wrapped bullet lines and is
too aggressive for intentional bullets that begin with code spans.

# Acceptance

- Release-note extraction preserves distinct bullets whose text starts with a
  code span, such as ``- `taskr move` ...``.
- Lowercase wrapped continuation normalization still works for genuinely
  wrapped lines that are not intended as separate bullets.
- Backtick-starting wrapped continuation behavior is either made explicit and
  tested or removed if it cannot distinguish intentional bullets from wrapped
  continuation lines.
- Smokey coverage reproduces the `0.3.0+82` release-note shape and asserts
  that the generated GitHub Release notes contain separate bullets.
- `RELEASING.md` documents the supported release-note bullet wrapping rules if
  those rules change.

# Comments

- 2026-08-23: Observed after publishing `v0.3.0+82`. The GitHub Release exists
  and the assets are correct, but the release body grouped code-span-starting
  bullets as continuations of the first bullet.

# Outcome

Implemented release-note bullet preservation for code-span-starting bullets.

- `scripts/collect-taskr-release-notes.sh` now preserves existing Markdown
  bullet lines from ticket `# Release Notes` sections instead of prefixing every
  collected line with another bullet marker.
- `scripts/extract-release-notes.sh` no longer treats backtick-starting bullet
  text as an accidental wrapped continuation.
- Lowercase accidental continuation normalization remains in place.
- `RELEASING.md` documents the supported ticket and changelog bullet wrapping
  rules.
- Smokey covers both the existing release workflow and a fixture matching the
  `0.3.0+82` code-span release-note shape.

# Release Notes

Taskr release tooling now preserves GitHub Release bullets that start with code
spans such as ``- `taskr move` ...`` instead of rendering them as continuations
of the previous bullet.
