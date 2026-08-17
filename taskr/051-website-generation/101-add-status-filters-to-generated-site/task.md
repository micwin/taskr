---
title: Add status filters to generated site
status: reviewing
created_at: 2026-08-17T07:52:27Z
updated_at: 2026-08-17T08:01:52Z
designing_at: 2026-08-17T07:52:27Z
developing_at: 2026-08-17T07:57:59Z
reviewing_at: 2026-08-17T08:01:52Z
---

# Description

Add interactive status filters to generated Taskr sites. The site should make it
easy to hide completed work while still allowing users to inspect any status on
demand.

By default, `done` and `cancelled` are disabled in the site filter UI. All
other statuses are enabled. Users can toggle individual statuses, including
re-enabling `done` and `cancelled`.

Milestones need special handling: a milestone must remain visible in the
overview when either the milestone itself matches the active filter criteria or
at least one child or descendant item would be visible according to the active
filter criteria. This prevents parent milestones from hiding still-visible work
below them while keeping the rule general for future filters beyond status.

# Acceptance

- Generated `index.html` includes a status filter control listing every known
  status.
- `done` and `cancelled` are disabled by default; all other statuses are enabled
  by default.
- The filter updates visible overview rows without requiring regeneration.
- Search/result pages use the same default status visibility unless a result
  link or query explicitly asks for a status.
- Users can toggle `done` and `cancelled` back on.
- A milestone remains visible when the milestone itself matches the active
  filter criteria.
- A milestone also remains visible when any child or descendant item matches
  the active filter criteria, even if the milestone itself is filtered out.
- Empty milestones that do not match the active filter criteria are hidden.
- Filter state is encoded in the page URL or another browser-visible state so
  refresh/back/forward behavior is predictable.
- Smokey or site tests cover default hiding, re-enabling terminal statuses, and
  milestone visibility when visible children remain.
- Smokey first checks the generated static assets: status filter controls,
  default disabled terminal statuses, URL-driven state, and item hierarchy data.
- Smokey then checks the client-side filter contract with Node against the
  generated JavaScript behavior or an exported filter helper, without requiring
  browser automation for the initial implementation.

# Comments

- 2026-08-17: Added after reviewing the generated site. Desired default matches
  the CLI's unfinished-first behavior while keeping closed parents visible when
  they still contain visible work.
- 2026-08-17: Generalized milestone visibility: show a milestone when it
  matches the filter itself or when at least one child/descendant would be
  visible under the same filter.
- 2026-08-17: Agreed to test this in the site generation suite first. Static
  asset checks prove the controls and state model exist; Node-level JavaScript
  checks prove the filtering rules without requiring a full browser.

# Outcome

Implemented status filters for generated sites.

Delivered behavior:

- `index.html` renders a checkbox filter for every configured status.
- `done` and `cancelled` are disabled by default; all other statuses are
  enabled by default.
- Filter state is reflected in the URL via repeated `status=` query parameters.
- The overview updates visible rows client-side without regeneration.
- Generated item data now includes parent item IDs so client-side hierarchy
  rules can evaluate descendants.
- Milestones remain visible when they match the active filter themselves or
  when any descendant matches.
- Empty milestones that do not match the active filter are hidden.
- Result pages use the same default unfinished-first status visibility unless
  explicit status parameters are present.

Verified with `go test ./src/taskr` and `smokey --tests-dir tests.d`
(`31/31 ok`).

# Release Notes

Generated Taskr sites now include status filters. Done and cancelled work is
hidden by default, can be toggled back on, and milestones stay visible whenever
they contain visible work.
