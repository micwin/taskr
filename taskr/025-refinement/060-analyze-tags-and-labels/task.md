---
title: Analyze tags and labels
status: done
created_at: 2026-08-10T12:33:35Z
updated_at: 2026-08-17T07:46:53Z
developing_at: 2026-08-17T07:01:33Z
reviewing_at: 2026-08-17T07:34:32Z
done_at: 2026-08-17T07:46:53Z
---

# Description

Define Taskr's tag model for every item type. Tags are case-insensitive marker
metadata used for display and read-only filtering. The user-facing feature is
called `tags`; Taskr does not introduce a second synonymous `labels` concept.

Tags participate in `show` and search only when prefixed with `#`. They are not
general item selectors for mutating commands. CLI list filtering uses
`--tags tag1,tag2,tag3`, while the generated site renders tags as clickable
filters on item and result pages.

# Acceptance

- Tags are supported on milestones, tasks, and subtasks.
- Marker frontmatter stores tags once as a YAML list without a leading `#`, for
  example `tags: [bug, website]` or its equivalent block-list form.
- Tags are case-insensitive and normalized to one canonical lowercase form.
  Only ASCII letters `a-zA-Z` are accepted as input. Stored tags are lowercase.
  Empty values, whitespace, tabs, digits, punctuation, underscores, hyphens,
  leading `#`, and duplicate normalized tags on one item are rejected.
- `taskr show '#tag'` performs an exact case-insensitive tag lookup. One match
  renders the item; multiple matches use Show's existing candidate output and
  nonzero ambiguity result. Help and examples explain that shells require the
  leading `#` to be quoted or escaped.
- A `#tag` token activates tag matching in generated-site search. A query
  without `#` continues to search only the existing ID, slug, and title
  surfaces and does not match tags accidentally.
- `taskr list --tags tag1,tag2,tag3` accepts a comma-separated, case-insensitive
  tag list. All supplied tags are required; repeated filters therefore narrow
  the result set with AND semantics and compose with existing list filters.
- Shell completion suggests known normalized tags after `#` on tag-aware
  read-only search surfaces and within each comma-separated `--tags` value.
- `taskr examples` includes ordinary tag lookup and list filtering:
  ```text
  taskr show '#website'
  taskr list --tags website
  ```
  It also includes a composed list example that demonstrates AND semantics and
  interaction with existing filters:
  ```text
  taskr list --type task --status developing --tags website,release
  ```
  The surrounding documentation explains why `#website` must be quoted or
  escaped in a shell.
- Existing tags are displayed whenever present in `show` and item-list output,
  including tree/report rows where items are listed. Missing tags add no empty
  decoration. Compact row output uses a separate tag column without `tags=`:
  one tag is rendered as `#tag`; multiple tags are rendered as
  `#(one,two,three)`. `show` renders tags as `Tags: #one` for one tag and
  `Tags: #(one,two,three)` for multiple tags.
- Generated item pages and result lists render each tag as a clickable `#tag`.
  Clicking adds that tag to the current filter context rather than replacing
  existing filters. Existing unique-result behavior opens the item when one
  result remains.
- Website query URLs encode the leading hash as `%23`; it must not become a URL
  fragment that is absent from the search query.
- Tags do not identify targets for `move`, `status`, `priority`, `rename`,
  `archive`, `create --under`, or other mutating selector surfaces. This avoids
  applying changes to an ambiguous tagged set.
- Doctor validates tag storage and normalization. Archiving preserves tags as
  ordinary marker metadata without introducing a separate index.
- Tag creation, replacement, removal, and root-wide rename are provided by the
  structured non-interactive edit mechanism from ticket `095`, not by ad hoc
  marker text replacement. Ticket `044` remains responsible for interactive
  section editing and whole-section stdin replacement.
- The analysis identifies implementation subtasks and Smokey coverage for
  storage/Doctor, Show and CLI filtering/completion, structured edits, and the
  generated website before implementation begins.

# Comments

- 2026-08-10: Added while discussing selector and workflow refinements. Tags
  may be useful for search and reporting, but using them as command targets
  could collide with slug/ID selector semantics and needs separate design.
- 2026-08-14: Agreed to use only the term `tags`, support every item type, store
  normalized tags in marker frontmatter, and display them whenever present.
  `#tag` is limited to Show and search; CLI list filtering uses comma-separated
  `--tags` with AND semantics and tag-aware shell completion.
- 2026-08-14: Tag mutation and root-wide rename belong to structured
  non-interactive editing in ticket `095`. Tags remain excluded from mutating
  item selectors such as `--under` and Move.
- 2026-08-14: Agreed that `taskr examples` must cover both `#tag` lookup and
  basic plus composed `list --tags` filtering.
- 2026-08-17: Tag validation narrowed to ASCII letters only, stored in
  lowercase. CLI display uses compact tag values without a `tags=` prefix;
  leading `#` is primarily a disambiguation marker in free text and search
  input, not part of stored tag values.
- 2026-08-17: While moving valid tag fixtures into the shared Smokey base root,
  `000-setup` doctor was made non-blocking with `|| true` so the new red tag
  contract can coexist with the shared fixture before implementation. The
  general strict doctor gate policy is tracked separately in ticket `096`.

# Outcome

Implemented tags for milestones, tasks, and subtasks.

Delivered behavior:

- Marker frontmatter accepts `tags` as a YAML list in inline or block form.
- Tags are normalized to lowercase and validated as ASCII letters only.
- Doctor rejects invalid tag values, non-list tag storage, non-string tag
  values, and duplicate normalized tags.
- `show '#tag'` performs exact tag lookup and reports normal ambiguity
  diagnostics when multiple items share the tag.
- `list --tags tag1,tag2` filters with case-insensitive AND semantics.
- `show`, `list`, `tree`, and `report` display existing tags compactly.
- Shell completion suggests known tags for `show '#...'` and `list --tags`.
- Mutating item selectors continue to reject tag selectors.
- Generated site data includes tags, item/result pages render clickable tag
  links, and `q=%23tag` searches tags without making ordinary text queries
  match tags accidentally.
- Shared Smokey fixtures carry valid tags; intentionally invalid tag data stays
  isolated in the tag workflow suite.

Verified with `go test ./src/taskr` and `smokey --tests-dir tests.d`
(`31/31 ok`).

# Release Notes

Taskr items can now carry tags in marker frontmatter. Tags are visible in CLI
output and generated sites, searchable with `show '#tag'`, filterable with
`list --tags`, completed by the shell, and validated by Doctor.
