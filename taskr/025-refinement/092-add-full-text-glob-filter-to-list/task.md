---
title: Add full-text glob filter to list
status: designing
created_at: 2026-08-13T20:11:30Z
updated_at: 2026-08-13T20:11:30Z
designing_at: 2026-08-13T20:11:30Z
---

# Description

Add `taskr list --glob <pattern>` as a full-text glob filter. The filter matches
against the complete marker file of each item, including frontmatter and all
Markdown sections, rather than being limited to item ID, slug, or title.

The filter extends the existing `list` pipeline and composes with `--type`,
`--status`, `--priority`, `--under`, and `--all`. Marker files remain the source
of truth; Taskr does not introduce a separate search index or duplicated search
data.

# Acceptance

- `taskr list --glob <pattern>` filters items by applying a documented glob
  expression to their complete marker-file text.
- Full-text matching includes frontmatter, Description, Acceptance, Comments,
  Outcome, and any later valid marker sections.
- `--glob` composes predictably with every existing list filter and preserves
  existing unfinished-item defaults unless `--all` is supplied.
- The design defines whether matching is case-sensitive by default and whether
  a case-insensitive option is needed.
- The supported glob grammar is documented before implementation, including
  `*`, `?`, character classes, newline behavior, escaping, malformed patterns,
  and whether an unadorned word implies surrounding wildcards.
- The behavior of repeated `--glob` flags is defined as conjunction,
  disjunction, or rejection before implementation.
- Binary attachments and files below `files.md` containers are not searched;
  only item marker text participates in this filter.
- Output format, priority grouping, and sorting remain those of `taskr list`;
  the filter does not add snippets or alter displayed item lines in the initial
  implementation.
- Shell completion does not attempt to enumerate full-text patterns, but the
  flag and its value contract appear in completion and help.
- Smokey covers matches in frontmatter and each Markdown section, no matches,
  malformed patterns, multiline boundaries, combinations with existing
  filters, closed-item defaults, and the agreed repeated-pattern behavior.
- Help, examples, documentation, Doctor impact, completion, and public API
  impact are reviewed for the final command surface.

# Comments

- 2026-08-13: `--glob` is a full-marker-text filter, not merely an
  ID/slug/title selector.
- 2026-08-13: Search data is read directly from marker files so filtering does
  not create a second source of truth.

# Outcome
