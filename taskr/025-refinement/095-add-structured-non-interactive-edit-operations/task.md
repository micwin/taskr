---
title: Add structured non-interactive edit operations
status: designing
created_at: 2026-08-14T12:36:25Z
updated_at: 2026-08-14T12:36:25Z
designing_at: 2026-08-14T12:36:25Z
---

# Description

Add a structured non-interactive edit mode for changing marker metadata and
performing explicit bulk transformations without opening an editor or treating
Markdown/YAML as unstructured text.

This complements ticket `044`, which edits Markdown sections interactively or
replaces complete section content through stdin. The structured mode owns
metadata operations such as setting scalar values, adding or removing list
members, and renaming one normalized value across a selected scope. Ticket
`060` depends on this mechanism for tag mutation and root-wide tag rename.

# Acceptance

- Taskr provides a non-interactive edit command surface for structured marker
  fields; its exact verb and flag grammar are refined with the user before
  Smokey logic is committed.
- Operations include setting or clearing an allowed scalar field, adding and
  removing values from an allowed list field, and replacing one list value
  with another across an explicitly selected scope.
- The first required list field is `tags`. Users can add, remove, replace, and
  clear tags without manually editing YAML.
- Root-wide tag rename is one atomic structured operation. It normalizes old
  and new names, reports every affected item, and does not rewrite unrelated
  marker content.
- Single-item operations use Taskr's normal unambiguous ID/slug selector
  behavior. Bulk operations require an explicit bulk scope and never happen
  merely because an ordinary selector matches multiple items.
- The command parses marker frontmatter structurally, preserves Markdown body
  sections, and writes valid canonical metadata rather than using textual
  search-and-replace.
- Validation is field-aware and reuses the same domain rules as Doctor and the
  feature that owns the field. Invalid fields, values, operations, or ambiguous
  targets fail before any marker is changed.
- Multi-item edits are atomic from the user's perspective: validation and the
  complete change plan finish before writes begin, and a write failure does not
  leave a silently partial transformation.
- Output supports a dry-run/change-plan form before mutation and stable rows
  suitable for scripting and Smokey assertions.
- A no-op succeeds clearly without changing `updated_at`. A real edit updates
  `updated_at` consistently on every changed item while preserving unrelated
  status timestamps.
- Help, examples, documentation, and shell completion cover fields,
  operations, selectors, bulk scope, and candidate values.
- After command grammar is fixed, `taskr examples` includes one single-item tag
  mutation and one root-wide tag rename in both dry-run and execution form.
- Smokey covers single-item add/remove/set/clear, root-wide tag rename, no-op,
  invalid input, ambiguity, dry run, timestamp behavior, body preservation,
  and rollback or preflight behavior for failed bulk edits.

# Comments

- 2026-08-14: Created while refining tags. This is deliberately separate from
  ticket `044`: section editing handles human-authored Markdown blocks, while
  this ticket handles typed metadata and controlled multi-item
  transformations.
- 2026-08-14: Candidate syntax resembles structured `set`, `add`, `remove`,
  `clear`, and `replace` operations, but command grammar remains open until it
  is discussed and fixed together with Smokey tests.

# Outcome
