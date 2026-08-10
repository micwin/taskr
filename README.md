# Taskr

Taskr is a local-first task manager for command-line workflows. The first
implementation target is a Go CLI built with Cobra.

This repository dogfoods Taskr data under `taskr/`. These files are design
fixtures until the CLI exists.

Taskr's MVP workflows must be fully usable with the CLI and a text editor. The
worktree is the source of truth; information should not be duplicated across
paths, marker filenames, frontmatter, and prose.

The normative MVP worktree format is documented in
[`doc/taskr-worktree-format.md`](doc/taskr-worktree-format.md).

## MVP Model

Taskr starts with these MVP item roles:

```text
milestone
task
subtask
```

An item is a directory with exactly one work-item marker file:

```text
milestone.md
task.md
subtask.md
```

The item ID is the directory prefix before the first `-`. The readable slug is
everything after it. IDs are unique across the whole root.

```text
taskr/
  001-mvp/
    milestone.md
    002-directory-structure/
      task.md
      notes/
        files.md
        sketch.txt
    003-define-workflows/
      task.md
    004-first-commands/
      task.md
```

For example, `004` identifies `004-first-commands/` regardless of where that
directory is nested. Allowed parent/child role pairs are derived from the
existing root at startup.

## Item Files

Files that belong to the root or an item live in file-container directories. A
file container is a directory with a `files.md` marker. It does not need an ID
prefix, does not count as a work item, and does not affect completion.

```text
002-directory-structure/
  task.md
  notes/
    files.md
    research.md
  examples/
    files.md
    mockups/
      list-output.txt
```

Taskr parses `files.md` as the container marker, then ignores everything else
below that directory for work-tree validation. Moving the parent item directory
moves its local files with it.

## Marker Format

Marker files are Markdown with YAML frontmatter. The filename defines the role.
The path defines the parent. Neither is repeated in frontmatter. Work-item
markers use `milestone.md`, `task.md`, and `subtask.md`; file containers use
`files.md`.

Required frontmatter:

```yaml
---
title: Define workflows
status: designing
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---
```

Taskr may also store optional RFC3339 transition metadata such as
`designing_at`, `developing_at`, `done_at`, and `reopened_at`. Each status field
records the most recent entry into that status. Missing transition fields are
valid for compatibility with existing markers.

Tasks may store `priority: high` or `priority: low`. An omitted priority means
`normal`; Taskr does not persist redundant `priority: normal`. Priority is not
valid on milestones or subtasks. Normal `show` output includes `high` and `low`
priorities; `show --meta` also displays effective `normal`.

Required body structure:

```markdown
# Description

Describe the work in human terms.

# Acceptance

- The result can be verified.

# Comments

- 2026-06-03: Design note or decision.

# Outcome

Empty until the item is done. When complete, summarize what actually shipped or
was decided.
```

`# Outcome` is always the last section. `# Comments` is the place for
discussion notes, decisions, and later corrections.

Comments can be appended from the CLI without opening an editor:

```bash
taskr comment 002 "Reviewed with Michael"
printf 'first detail\nsecond detail\n' | taskr comment 002 --stdin
```

## Status Lifecycle

Built-in statuses are `open`, `designing`, `developing`, `active`,
`reviewing`, `blocked`, `done`, and `cancelled`. `developing` is the normal
state for work that has left design and is being implemented. `reviewing` is
the normal state for implemented work that an agent considers complete; `done`
and `cancelled` are final closure states.

The outcome is written into the marker file of the item it belongs to. It does
not move to a separate archive log. If an item is archived later, the whole item
directory moves and keeps its marker, outcome, comments, children, and file
containers together.

## Completion

Completion is structural:

- A leaf work item is complete when its own status is `done`.
- A non-leaf work item is complete only when all completion children are
  complete.

No task dependency links exist in the MVP model.

Use `taskr tree` to inspect the work hierarchy in the terminal. By default it
uses indentation and hides completed leaf items; use `taskr tree --all` to
include done and cancelled work, or `taskr tree --ascii` for branch markers.

## Archive

Archived work remains ordinary Taskr data. Archiving moves completed item
directories below the root archive directory without rewriting their marker
format. The default archive directory is `archive/` below the Taskr root.
`--to 2026` means `archive/2026` below the root. The marker's `# Outcome`
section remains the canonical result record.
Items are closed in place first by filling `# Outcome` and setting `status:
done` or `status: cancelled`; archive is a later move for completed subtrees.

## Roots

Taskr can use personal configuration, an explicit config file, or a directory:

```bash
taskr
taskr --config-file ./custom-taskr.yml
taskr ./tasks
taskr .
```

Personal config defaults to:

```text
${XDG_CONFIG_HOME:-~/.config}/taskr/config.yaml
```

Personal data defaults to:

```text
${XDG_DATA_HOME:-~/.local/share}/taskr
```

When a directory is passed, Taskr searches that directory and a direct `taskr/`
child. For `taskr .`, candidates are:

```text
./
./taskr/
```

A Taskr root is a directory whose work tree contains valid item directories.
Every non-root work-tree directory must contain exactly one recognized marker
file unless it is below a `files.md` container. Work-item directories must use
a root-unique ID prefix. File-container directories do not need an ID prefix.
Zero or multiple marker files are invalid and stop the tool.

## Doctor

`taskr doctor` validates the checks currently enforced while loading a Taskr
root:

- Every non-root work-tree directory outside file containers has exactly one
  recognized marker file.
- Every work-item directory name starts with a root-unique ID and `-`.
- File-container directories contain `files.md`, need no ID prefix, and do not
  count as completion children.
- Item IDs are unique across the whole root.
- Every marker parses as Markdown with YAML frontmatter.
- Every marker has the frontmatter fields used by the loader: `title` and a
  valid `status` when `status` is present.
- Status values are allowed by personal config or built-in defaults.

`taskr doctor --fix` currently repairs only duplicate item IDs. It renames
later colliding item directories to the next free root-wide IDs and reports
each changed path. The worktree must be loadable apart from duplicate IDs;
unsupported marker or structure errors leave the worktree unchanged.

## Smokey

User-visible behavior is tested through directory-based Smokey suites under
`tests.d/`.

The full suite is always run through Smokey:

```bash
smokey --tests-dir tests.d
```

Tests must write generated roots, configs, logs, and binaries below
`${SMOKEY_STATE_DIR}`.
