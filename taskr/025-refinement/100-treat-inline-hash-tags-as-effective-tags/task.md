---
title: Treat inline hash tags as effective tags
status: designing
created_at: 2026-08-17T07:44:11Z
updated_at: 2026-08-17T07:44:11Z
designing_at: 2026-08-17T07:44:11Z
---

# Description

Treat inline `#tag` occurrences in ticket Markdown sections as effective tags
for read-only tag behavior. Structured frontmatter tags remain the canonical
explicit metadata, but tags found in ticket text, comments, acceptance,
outcome, and similar body sections should be merged into the displayed and
searchable effective tag set.

Inline tags use the same tag name rules as structured tags: letters only,
case-insensitive, normalized to lowercase. Effective output deduplicates tags
that appear both in frontmatter and body text.

# Acceptance

- Taskr extracts inline `#tag` occurrences from marker Markdown body sections,
  including Description, Acceptance, Comments, Outcome, and future equivalent
  sections.
- Inline tag extraction follows the same validation and normalization rules as
  structured tags: ASCII letters only and lowercase effective values.
- `show`, `list`, `tree`, `report`, shell completion, and generated sites use
  the deduplicated effective tag set for display and read-only lookup/filtering.
- Structured frontmatter tags and inline body tags are deduplicated in output.
- Invalid inline hash text that does not match the tag syntax is ignored as
  plain text rather than making Doctor fail.
- Doctor continues to validate structured frontmatter tags strictly.
- Smokey covers inline-only tags, structured-plus-inline deduplication, invalid
  inline hash text, and read-only lookup/filter/display behavior.

# Comments

- 2026-08-17: Added after clarifying that `list --tags website` currently only
  uses structured frontmatter tags. Desired behavior is that visible inline
  `#tags` in ticket text behave like effective tags for display and read-only
  filtering, without replacing structured metadata.

# Outcome
