---
title: Open generated project site
status: developing
created_at: 2026-08-10T18:03:26Z
updated_at: 2026-08-13T20:13:57Z
designing_at: 2026-08-10T18:03:31Z
developing_at: 2026-08-13T20:13:57Z
---

# Description

Add `taskr site open [search terms...]`. The command serves an existing
generated site from the persistent directory configured by `taskr site init`,
opens it in a browser, and remains in the foreground until interrupted. It does
not regenerate by default. `--regenerate` performs one full generation before
serving. Optional watch mode keeps the preview synchronized with Taskr source
changes.

# Acceptance

- `taskr site open` uses Taskr's normal root discovery and initialized site
  directory and requires no target argument.
- Normal `site open` validates and opens the existing generated `index.html`
  without modifying the generated site. A missing generated index fails with
  an actionable instruction to run `taskr site generate` or use
  `site open --regenerate`.
- `--regenerate` runs one full generation through the implementation from task
  `081` before opening the resulting index.
- The browser is selected in this order: personal Taskr configuration,
  `$BROWSER`, then the platform-default system opener. It does not use
  `$EDITOR`.
- A configured browser may include command arguments. Executable lookup honors
  `PATH`; Taskr does not require an absolute browser executable path.
- Personal YAML configuration uses one flat `browser` string, for example
  `browser: firefox --private-window`. Taskr parses command and arguments with
  shell-like quoting rules but executes them directly without a shell.
- Browser configuration and `$BROWSER` may contain one `{url}` placeholder to
  control argument position. Without the placeholder, Taskr appends the path or
  URL as the final argument.
- Browser invocation receives the complete local HTTP URL, including scheme,
  host, selected port, and `/index.html` path.
- With no search terms, Taskr opens `/index.html`. Positional terms are joined
  with spaces, URL-encoded, and open the shared result page as
  `/results.html?q=<query>`.
- Positional search uses the generated site's search semantics rather than CLI
  selector resolution: case-insensitive title and slug substrings plus numeric
  IDs without leading zeroes. The existing result page opens a unique match
  directly and displays the common paginated table for multiple matches.
- `site open` always starts a loopback HTTP server and remains in the foreground
  until interrupted. `--watch` adds source observation, regeneration, and
  automatic reload; it does not control whether the server exists.
- Watch mode observes the Taskr source tree, not the generated site. A relevant
  source change triggers a full regeneration through task `081`.
- Relevant source files are `milestone.md`, `task.md`, `subtask.md`, and the
  root-local `taskr.toml`. `files.md` containers and attachments are not part
  of the current generated site and do not trigger regeneration.
- `--watch` alone opens the existing generated site and starts watching without
  an initial regeneration. Combining `--watch --regenerate` performs one full
  generation before opening and then regenerates on later source changes.
- The preview server first attempts port 80. If that port is occupied or cannot
  be bound without additional privileges, Taskr selects an available dynamic
  port. `--port <number>` requests one exact port and fails rather than falling
  back when that port cannot be bound.
- `--port` is valid with and without `--watch`. Before invoking the browser,
  command output reports the complete effective URL so it can also be opened
  manually.
- `--no-browser` starts and reports the server normally but suppresses browser
  invocation, supporting headless sessions and deliberate manual opening.
- Watch mode observes relevant Taskr marker and related-file changes, debounces
  bursts, regenerates through the same generator used by `site generate`, and
  reports regeneration errors without silently serving stale output as fresh.
- Watch mode polls relevant source paths every 500 milliseconds and debounces a
  detected burst for 250 milliseconds before regenerating.
- Automatic browser reload is enabled only for `--watch`. After a successful
  regeneration, the served page detects the new generation and reloads. A
  failed regeneration prints the available error to stderr, keeps serving the
  last successful output without reloading it, and continues watching for the
  next source change.
- Watch mode may use periodic source polling and complete regeneration rather
  than incremental output synchronization. Browser refresh may likewise poll
  or reload generated `file:` content; a loopback server is not required unless
  direct file refresh proves unreliable in supported browsers.
- The design defines the polling interval, browser refresh mechanism, browser
  selection, noninteractive sessions, opener failures, interruption, and clean
  shutdown before implementation starts.
- Failure to find or generate the initialized site or start the opener/preview
  produces a nonzero exit and an actionable error.
- A browser startup failure stops the preview server and exits nonzero. A user
  who does not want browser startup uses `--no-browser` explicitly.
- If `taskr.toml` changes during watch and resolves to a different site output
  directory, Taskr reports the ownership-boundary change and stops instead of
  silently switching the server root.
- An explicitly configured browser that cannot be parsed, resolved through
  `PATH`, or started fails immediately. Taskr does not silently fall through to
  `$BROWSER` or the system opener after an invalid explicit configuration.
- `Ctrl-C` shuts down the preview server and watcher cleanly and exits with
  status 0.
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
- 2026-08-13: Normal open does not regenerate implicitly. `--regenerate` opts
  into a full generation. Browser selection uses personal Taskr configuration,
  then `$BROWSER`, then the platform default. Watch mode uses a local HTTP
  server rather than relying on reload behavior for `file:` URLs.
- 2026-08-13: Watch observes Taskr source and regenerates after changes, but
  does not regenerate initially unless combined with `--regenerate`. The local
  preview attempts port 80 and falls back to a dynamic port; explicit `--port`
  disables fallback. Browser commands may include arguments and use `PATH`.
- 2026-08-13: Personal browser configuration is one flat YAML string with
  shell-like argument quoting and no shell execution. Watch is limited to item
  marker files and `taskr.toml`; attachments do not affect the current site.
- 2026-08-13: Watch uses 500 millisecond polling with 250 millisecond debounce.
  Only watch pages reload automatically. Regeneration errors preserve the last
  successful page, suppress reload, print to stderr, and leave the watcher
  running. Invalid explicit browser configuration fails fast.
- 2026-08-13: Browser commands support an optional `{url}` argument-position
  placeholder. A changed configured site directory stops an active watcher
  rather than switching its server root implicitly.
- 2026-08-13: Local HTTP serving is now the base `site open` behavior rather
  than a watch-only mechanism. The server stays in the foreground until
  interrupted; watch adds only regeneration and reload. `--port` works in both
  modes and output includes the complete effective URL.
- 2026-08-13: Added `--no-browser` for headless or manually opened previews.
  Browser startup failures stop the server and fail the command; `Ctrl-C`
  performs a clean successful shutdown.
- 2026-08-13: Optional positional search terms select the shared generated
  result page. Multiple words may be passed separately, are joined with spaces,
  and use exactly the same matching and unique-result behavior as site search.

# Outcome
