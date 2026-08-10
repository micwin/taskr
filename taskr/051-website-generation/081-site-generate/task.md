---
title: Generate project site
status: designing
created_at: 2026-08-10T18:03:26Z
updated_at: 2026-08-10T18:03:30Z
designing_at: 2026-08-10T18:03:30Z
---

# Description

Add `taskr site generate`. The command renders the project managed by the
selected Taskr root as a static site in the persistent output directory
configured by `taskr site init`. The generated `index.html` must be directly
usable with a browser and must not require a Taskr process or web server after
generation.

# Acceptance

- `taskr site generate` uses Taskr's normal root discovery and the initialized
  project-local site directory; an uninitialized root fails with an actionable
  instruction to run `taskr site init`.
- The output directory is read from `[site]` in `<taskr-root>/taskr.toml`;
  relative paths resolve against the Taskr root.
- Successful generation creates `<configured-site-directory>/index.html`.
- Every successful generation records its generation time in UTC using RFC3339
  and renders it visibly on the generated start page as an HTML `<time>` value
  with a matching machine-readable `datetime` attribute.
- The generation timestamp belongs only to generated output and command output;
  it is not written back into marker files or `taskr.toml`.
- Generated pages, links, styles, and assets work when `index.html` is opened
  through a local `file:` URL without a web server.
- Generation does not modify marker files or other source data in the Taskr
  root.
- Site generation reuses one rendering implementation that can also support
  `taskr site open`; the two commands do not maintain separate site formats.
- Initial generation atomically replaces the complete initialized site output
  and may run only when Taskr can verify ownership of the target directory.
- Incremental `--sync` behavior, preservation of unrelated files, generated
  manifests, and configurable generation modes are deferred to task `087`.
- The design defines behavior for a missing, existing empty, existing nonempty,
  nested, unwritable, moved, or source-overlapping configured directory before
  implementation starts.
- Partial output is not presented as a successful site when rendering fails.
- Command output reports the generated index path in a script-friendly form.
- Command output includes the same generation timestamp rendered into the site.
- Smokey verifies ownership protection, atomic full replacement, stale
  generated-file removal, generated structure, and representative project
  content using a configured target under Smokey-managed state.
- Help, examples, completion, documentation, Doctor impact, and public API
  impact are reviewed for the final command and flags.

# Comments

- 2026-08-10: Replaced the original per-invocation target argument with the
  persistent directory configured by task `085`. Preview and browser behavior
  belong to task `082`.
- 2026-08-10: Deferred incremental `--sync` behavior to task `087`. The initial
  generator performs a complete atomic replacement of its owned output.
- 2026-08-10: Generation time is mandatory. One UTC RFC3339 value is captured
  per generation and reused for the visible, machine-readable start-page time
  and script-friendly command result.

# Outcome
