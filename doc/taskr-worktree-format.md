# Taskr Worktree Format

Taskr stores work as directories with Markdown marker files.

The worktree is the source of truth. Every MVP workflow must be possible with
only the Taskr CLI and a text editor. Taskr must not require users to duplicate
role, ID, parent, status, or outcome information in multiple places.

# Items

The MVP supports three work-item markers:

```text
milestone.md
task.md
subtask.md
```

A work-item directory must contain exactly one work-item marker. Its directory
name must start with a globally unique item ID, followed by `-` and a readable
slug:

```text
001-mvp/
  milestone.md
  002-directory-structure/
    task.md
```

The marker filename defines the role. The directory ID before the first `-`
defines local identity. Directory nesting defines parent/child relationships.
The marker frontmatter must not repeat role, ID, or parent.

IDs are unique across the whole root, not only among siblings. If the same ID is
found twice, Taskr refuses commands that need an unambiguous worktree. `taskr
doctor --fix` can repair duplicate IDs when the rest of the worktree is
loadable.

ID width is not semantically important. `1-foo`, `01-foo`, and `001-foo` are
different spellings of numeric IDs. A future repair command may normalize ID
width across the root when requested.

Slugs are unique per role across the root. Two milestones must not share the
same slug, but a milestone and a task may share one.

# Hierarchy

Taskr does not hard-code one universal work-item hierarchy. At startup, it
derives allowed parent/child role pairs from the existing tree. The first
observed relationship for a role pair makes that relationship valid for the
current root.

Root items are always allowed. File containers are always allowed directly below
the root or below an item and do not participate in hierarchy rules.

When creating new items, Taskr must reject parent/child role pairs that are not
already present in the derived hierarchy. This keeps an existing root consistent
while still allowing early projects to discover their structure by creating the
first examples.

# Marker Body

Marker files are Markdown with YAML frontmatter.

Required frontmatter:

```yaml
---
title: Define directory structure
status: active
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---
```

Required body sections:

```markdown
# Description

# Acceptance

# Comments

# Outcome
```

`# Outcome` is the final section. It is the canonical result record for that
item. While work is not done, the section may be empty.

# Files

Files that belong to the root or an item live below a directory containing
`files.md`:

```text
taskr/
  files/
    files.md
    root-note.md

002-directory-structure/
  task.md
  notes/
    files.md
    research.md
```

A file-container directory does not need an ID prefix, does not count as a work
item, and does not affect completion. It may live directly below the root or
below an item. Taskr parses `files.md`, then ignores all other content below
that directory for worktree validation.

# Completion

Completion is structural:

- A leaf work item is complete when its own status is `done`.
- A non-leaf work item is complete only when all completion children are
  complete.

No task dependency links exist in the MVP model.

# Closing Work

Closing an item is a content change, not a move:

1. Write the result into the item's `# Outcome` section.
2. Set `status: done` when the item shipped or was decided.
3. Set `status: cancelled` when the item is intentionally abandoned.
4. Keep the item in place while its parent is still active.

`closed` is a view category, not an MVP status. Items with `done` or
`cancelled` are closed.

# Archive

Archived work remains ordinary Taskr data. Archiving moves completed item
directories below the root archive directory without rewriting their marker
format. The default archive directory is `archive/` below the Taskr root.
`--to 2026` means `archive/2026` below the root.

The marker's `# Outcome` section remains the canonical result record.

Archive only completed subtrees whose parent context is also ready to leave the
active work tree. Do not archive a completed task out of an active milestone just
to mark it done; that would remove useful context from the active tree.
