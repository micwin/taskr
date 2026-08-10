---
title: Open generated project site
status: designing
created_at: 2026-08-10T18:03:26Z
updated_at: 2026-08-10T18:03:31Z
designing_at: 2026-08-10T18:03:31Z
---

# Description

Add `taskr site open`. The command creates a temporary target directory,
generates the same static project site as `taskr site generate`, and opens its
`index.html` with the system browser or opener.

# Acceptance

- `taskr site open` uses Taskr's normal root discovery and requires no target
  directory argument.
- The temporary site is created through the operating system's standard
  temporary-directory mechanism rather than a project-local work directory.
- The command invokes the configured or platform-default browser/system opener
  with the generated `index.html`; it does not use `$EDITOR`.
- Browser invocation receives a local file path or `file:` URL that works with
  the generated relative links and assets.
- `site open` calls the same generator used by `site generate`.
- The design defines browser selection, behavior in noninteractive sessions,
  opener failures, and the temporary directory's cleanup lifetime before
  implementation starts.
- The temporary site remains available long enough for the browser to load all
  generated assets and is not deleted prematurely when the opener returns.
- Failure to create the temporary directory, generate the site, or start the
  opener produces a nonzero exit and an actionable error.
- Smokey uses controlled temporary directories and a fake opener to verify the
  complete workflow without starting a real graphical browser.
- Help, examples, completion, documentation, Doctor impact, and public API
  impact are reviewed for the final command and flags.

# Comments

- 2026-08-10: This is a convenience preview for generated static output, not a
  live Taskr server. Persistent site output belongs to task `081`.

# Outcome
