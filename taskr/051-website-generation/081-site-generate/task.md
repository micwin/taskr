---
title: Generate project site
status: designing
created_at: 2026-08-10T18:03:26Z
updated_at: 2026-08-12T08:44:19Z
designing_at: 2026-08-12T08:44:19Z
developing_at: 2026-08-12T08:27:17Z
---

# Description

Add `taskr site generate`. The command renders the project managed by the
selected Taskr root as a static site in the persistent output directory
configured by `taskr site init`. The generated `index.html` must be directly
usable with a browser and must not require a Taskr process or web server after
generation.

The generated site provides a report-like project overview, scoped status
views, client-side item search, and complete HTML views of individual tickets.
Milestone, task, and subtask IDs, slugs, and titles act as navigation links
wherever they are displayed.

# Acceptance

- `taskr site generate` uses Taskr's normal root discovery and the initialized
  project-local site directory; an uninitialized root fails with an actionable
  instruction to run `taskr site init`.
- The output directory is read from `[site]` in `<taskr-root>/taskr.toml`;
  relative paths resolve against the Taskr root.
- Successful generation creates `<configured-site-directory>/index.html`.
- The index is comparable to `taskr report`: it contains a project-wide
  summary and sections for individual milestones.
- Displayed status names and counts are links. A status link in the global
  summary opens a result view containing all project items with that status; a
  status link inside a milestone opens the corresponding result restricted to
  that milestone.
- Displayed item IDs, slugs, and titles link to the complete generated view of
  that item.
- The top of the index provides item search over IDs, slugs, and title parts.
  Matching is case-insensitive; slugs and titles match substrings occurring in
  the middle of their values, and numeric IDs match without leading zeroes.
- Search is keyboard-operable: Tab reaches its controls and Enter submits the
  query.
- A single search result opens its item directly. Multiple results open a
  clearly structured table whose item IDs, slugs, and titles link to the
  corresponding item views. More than 25 matches are paginated in pages of 25
  entries. No matches produce an explicit empty result instead of a broken or
  blank page.
- Search results, global status results, milestone-scoped status results, and
  later list-producing links use the same result-page implementation and table
  format rather than separate result views.
- Every result view encodes its complete list context in its URL, including
  search or filter criteria, milestone scope, ordering, and current page where
  applicable. Result state must not depend on one shared mutable browser value.
  Multiple tabs can therefore keep different result lists open independently.
- An individual item view renders the complete marker document as HTML,
  including frontmatter-derived metadata and all Markdown sections.
- Sections in an item view can be expanded and collapsed.
- Plain-text links beginning with `http://`, `https://`, or `www.` are rendered
  as clickable links and open in a new browser tab.
- When an item is opened from a result list, controls beside the main title use
  `<` and `>` to open the previous and next result. A control is omitted or
  disabled when no item exists in that direction. Result links carry the
  complete originating list context into the item view, so navigation uses the
  same filter, scope, and ordering even when multiple result lists are open in
  separate tabs. Directly opened items do not invent a result-list order.
- Search, filtering, pagination, collapsible sections, and previous/next
  navigation work from a local `file:` URL without a Taskr process or web
  server.
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
- 2026-08-12: Defined the initial generated-site experience: report-like
  global and milestone summaries link to scoped status results; item IDs,
  slugs, and titles link to complete item views; client-side search handles
  partial IDs, slugs, and titles; result lists paginate after 25 entries; and
  item views support collapsible sections, external links, and contextual
  previous/next navigation.
- 2026-08-12: Unified search and filter results behind one result-page
  implementation. Complete list context travels in the URL and through item
  links, keeping result lists and previous/next navigation independent across
  multiple browser tabs without shared mutable state.

# Outcome
