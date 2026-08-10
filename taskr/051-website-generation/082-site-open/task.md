---
title: Open generated project site
status: designing
created_at: 2026-08-10T18:03:26Z
updated_at: 2026-08-10T18:03:31Z
designing_at: 2026-08-10T18:03:31Z
---

# Description

Add `taskr site open`. The command opens the generated `index.html` from the
persistent site directory configured by `taskr site init`. An optional watch
mode keeps the preview synchronized with Taskr source changes.

# Acceptance

- `taskr site open` uses Taskr's normal root discovery and initialized site
  directory and requires no target argument.
- Normal `site open` performs one full generation through the implementation
  from task `081` before opening `index.html`; an uninitialized root fails with
  an actionable instruction to run `taskr site init`.
- The command invokes the configured or platform-default browser/system opener
  with the generated `index.html`; it does not use `$EDITOR`.
- Browser invocation receives a local file path or `file:` URL that works with
  the generated relative links and assets.
- `--watch` performs an initial generation, opens the browser once, and remains
  in the foreground until interrupted.
- Watch mode observes relevant Taskr marker and related-file changes, debounces
  bursts, regenerates through the same generator used by `site generate`, and
  reports regeneration errors without silently serving stale output as fresh.
- Watch mode may use periodic source polling and complete regeneration rather
  than incremental output synchronization. Browser refresh may likewise poll
  or reload generated `file:` content; a loopback server is not required unless
  direct file refresh proves unreliable in supported browsers.
- The design defines the polling interval, browser refresh mechanism, browser
  selection, noninteractive sessions, opener failures, interruption, and clean
  shutdown before implementation starts.
- Failure to find or generate the initialized site or start the opener/preview
  produces a nonzero exit and an actionable error.
- Smokey uses a controlled site directory, file changes, and a fake opener to
  verify normal and watch workflows without starting a graphical browser.
- Help, examples, completion, documentation, Doctor impact, and public API
  impact are reviewed for the final command and flags.

# Comments

- 2026-08-10: Replaced the temporary-preview model with the persistent site
  directory configured by task `085`. Normal open remains a static file
  workflow; watch may use a loopback server only to provide reliable live
  reload during preview.
- 2026-08-10: Watch does not depend on deferred incremental sync. It may detect
  source changes and regenerate the complete owned output while the browser
  periodically reloads the generated filesystem content.

# Outcome
