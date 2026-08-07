---
title: Define directory structure
status: done
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Settle the marker-file layout, path-derived hierarchy, directory IDs, and root
discovery rules before implementation starts.

# Acceptance

- Valid item roles are derived only from `milestone.md`, `task.md`, and `subtask.md`.
- Item IDs are parsed from the directory prefix before the first `-`.
- Parent/child relationships are derived only from directory nesting.
- A directory with zero or multiple recognized marker files is specified as invalid.
- Root discovery behavior for `taskr`, `taskr .`, and `taskr ./path` is documented.
- File containers are defined through `files.md`, may live below the root or an
  item, and do not need ID prefixes.
- Outcomes are stored in the item's own marker file under `# Outcome` and move
  with the item when it is archived.

# Comments

- 2026-06-03: Removed root manifests. The work tree is defined by directories
  containing exactly one marker file.
- 2026-06-03: Removed explicit task links. Parent completion is derived from
  child completion.
- 2026-06-03: Promoted the decided format into
  `doc/taskr-worktree-format.md` so later tickets and users can reference it.

# Outcome

The MVP structure is fixed as marker-based directories:

```text
<id>-<slug>/
  milestone.md | task.md | subtask.md
  <files-slug>/
    files.md
```

The marker filename defines the role. The directory ID before the first `-`
defines local identity. Nesting defines parent/child relationships. Every
non-root work-tree directory outside file containers must contain exactly one
recognized marker file.

Marker files must be Markdown with YAML frontmatter followed by `# Description`,
`# Acceptance`, `# Comments`, and `# Outcome`. `# Outcome` is the final section.
Empty outcome is allowed while work is not done.

The `# Outcome` section is the canonical result record for that item. It stays
in the marker file. Archiving moves the whole item directory, so outcome,
comments, children, and file containers remain together.

Files that belong to the root or an item live below a directory containing
`files.md`. The file-container directory may live directly below the root or
below an item, does not need an ID prefix, does not count as a work item, and
does not affect completion. Taskr parses `files.md`, then ignores all other
content below that directory for work-tree validation.

The user-facing specification for this outcome is
`doc/taskr-worktree-format.md`.

Example worktree with two milestones, two tasks per milestone, one subtask, and
marker files included:

```text
taskr/
|
+- files/
|  |
|  +- files.md
|  +- root-note.md
|
+- 001-mvp/
|  |
|  +- milestone.md
|  |
|  +- 002-verzeichnisstruktur/
|  |  |
|  |  +- task.md
|  |
|  +- 003-workflows-definieren/
|     |
|     +- task.md
|     |
|     +- 001-selector-regeln/
|        |
|        +- subtask.md
|
+- 010-release/
   |
   +- milestone.md
   |
   +- 011-semantic-versioning/
   |  |
   |  +- task.md
   |
   +- 012-github-release/
      |
      +- task.md
```
