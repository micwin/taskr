---
title: Fix generated release-note wrapping
status: reviewing
created_at: 2026-08-17T09:21:31Z
updated_at: 2026-08-17T09:32:26Z
designing_at: 2026-08-17T09:21:31Z
developing_at: 2026-08-17T09:25:38Z
reviewing_at: 2026-08-17T09:32:26Z
---

# Description

Fix the formatting of generated GitHub Release notes.

The published GitHub Release for `v0.1.0+82` renders wrapped changelog
continuation lines as separate bullet points. Example from the release page:

- `Taskr items can now carry tags...` starts as one bullet.
- The continuation line `output and generated sites...` renders as a second
  bullet.
- The continuation line ``list --tags`...` renders as another bullet.

The release is otherwise attached to the correct `release` commit. The problem
appears to be in release-note text generation or changelog source formatting,
not in tag placement.

Likely areas to inspect:

- `CHANGELOG.md` source wrapping for release notes.
- `scripts/extract-release-notes.sh`, which currently passes release section
  lines through unchanged.
- GitHub Release Markdown rendering of list continuation lines.
- Any release-note collection/preparation logic that turns wrapped prose into
  top-level `- ` lines.

# Acceptance

- Generated GitHub Release notes preserve intended bullets when release-note
  text wraps across multiple source lines.
- Continuation lines inside a bullet are not rendered as separate bullets.
- Release-note extraction keeps distinct bullets distinct.
- Existing versioned changelog sections remain readable Markdown.
- Smokey covers a wrapped bullet in a changelog fixture and verifies the
  extracted release notes render as a single intended bullet, not multiple
  accidental bullets.
- The fix stays in release tooling, documentation, or changelog generation; it
  does not add Taskr product code or CLI behavior.
- `RELEASING.md` documents any formatting convention that release-note authors
  need to follow.

# Comments

- 2026-08-17: Observed on
  `https://github.com/micwin/taskr/releases/tag/v0.1.0%2B82`. The release page
  shows continuation lines from the `0.1.0+82` notes as separate bullets.

# Outcome

Implemented release-note wrapping normalization in
`scripts/extract-release-notes.sh`.

The extractor still passes the requested version section through, but it now
rewrites accidental top-level bullet lines that look like wrapped continuations
into Markdown continuation lines. This covers the observed GitHub rendering
issue where wrapped lines such as `- output...` and ``- `list --tags`...`` were
shown as separate bullets.

Updated `RELEASING.md` to document the preferred changelog formatting rule:
wrapped bullet continuation lines should be indented with two spaces. Smokey
now covers both malformed wrapped bullets and already-correct wrapped bullets.

# Release Notes

GitHub Release notes now normalize accidentally wrapped changelog bullets so
continuation lines render inside the intended bullet instead of as separate
items.
