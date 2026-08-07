---
title: Define first commands
status: done
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Derive the first Cobra commands from the MVP workflows.

# Acceptance

- The initial command tree is documented with command names, arguments, and flags.
- Commands cover root discovery, item creation, listing, showing, completion, and doctor.
- Output formats and non-zero exit cases are specified for each command.
- Cobra command boundaries match the documented workflows.
- Command definitions are written directly into this task outcome.
- Command sequences rely only on the CLI plus editor and avoid duplicate entry
  of information already encoded by path, marker filename, or frontmatter.

# Comments

- 2026-06-03: Commands should be derived from documented workflows, not invented
  independently.
- 2026-06-03: Use `doc/taskr-workflows.md` as the fixed outcome from
  `003-workflows-definieren`.

# Outcome

Initial commands use verb-first shape:

```text
taskr [root] <verb> [type] [selector] [flags]
```

`root` is optional. If present, it is a directory argument such as `.` or
`./tasks`. Commands that accept selectors must use the shared selector behavior
from `doc/taskr-workflows.md`: no match fails, multiple matches fail and print
candidates.

IDs are root-unique single IDs, not path IDs. Commands should display `id=002`,
not `id=001/002`. Path is separate output. If duplicate IDs exist, every command
except `doctor` and a future repair command must fail.

## Root And Doctor Workflow

Speculative command sequence:

```bash
taskr . doctor
taskr ./taskr doctor
taskr --config-file "${SMOKEY_STATE_DIR}/config.yaml" doctor
```

Expected success output:

```text
ok root=... items=... files=...
```

Expected failure tests:

```bash
taskr ./missing doctor
taskr . doctor
```

The first command fails because the root does not exist. The second failure
case is created by Smokey with an invalid worktree directory containing zero or
multiple marker files.

## Create Item Workflow

Speculative command sequence:

```bash
taskr . create milestone "MVP" --no-edit
taskr . create task "Define directory structure" --under 001 --no-edit
taskr . create task "Define workflows" --under 001 --no-edit
taskr . create subtask "Define selectors" --under 003 --no-edit
taskr . create subtask "Define Rubbish" --under 001 --no-edit
taskr . create milestone "Define More Rubbish" --under 002 --no-edit

```

Expected output:

```text
created item id=001 path=001-mvp marker=milestone.md opened=false
created item id=002 path=001-mvp/002-define-directory-structure marker=task.md opened=false
created item id=003 path=001-mvp/003-define-workflows marker=task.md opened=false
created item id=004 path=001-mvp/003-define-workflows/004-define-selectors marker=subtask.md opened=false
cannot create item 'Define Rubbish' since milestones cannot hold subtasks
cannot create item 'Define More Rubbish' since tasks cannot hold milestones
```

Editor behavior:

```bash
EDITOR=true taskr . create task "Open in editor" --under 001 --edit
```

Expected output includes `opened=true` and the marker path.

Expected failure tests:

```bash
taskr . create task "No parent"
taskr . create task "Ambiguous parent" --under workflow
taskr . create milestone "Duplicate" --slug mvp
```

The first fails because task creation needs a parent. The second fails when the
selector matches more than one item. The third fails when the target directory
already exists.

## Shared Selector Workflow

Speculative command sequence:

```bash
taskr . show 001
taskr . show mvp
taskr . show "Define workflows"
taskr . show workflows
```

Expected success output:

```text
id=001 type=milestone status=active title="MVP"
```

Expected failure tests:

```bash
taskr . show does-not-exist
taskr . show workflow
```

The first fails with not found. The second fails when Smokey creates more than
one matching item and prints candidates.

## Show And List Workflow

Speculative command sequence:

```bash
taskr . list
taskr . list --under 001
taskr . list --type task --status active
taskr . show 003
```

Expected `list` output is deterministic text with one item per line:

```text
001 milestone active MVP
002 task done Define directory structure
003 task active Define workflows
```

Expected `show` output contains:

```text
id: 003
type: task
status: active
title: Define workflows
path: 001-mvp/003-workflows-definieren
```

Expected failure tests:

```bash
taskr . list --status nonsense
taskr . show workflow
```

Unknown filters fail. Ambiguous selectors fail with candidates.

## Change Status Workflow

Speculative command sequence:

```bash
taskr . status 003 done
taskr . status 004 done
taskr . status 003 done
```

The first command fails because task `003` still has unfinished child `004`.
After `004` is done, setting `003` to `done` succeeds.

Expected success output:

```text
status id=004 old=designing new=done effective=done
status id=003 old=active new=done effective=done
```

Expected failure tests:

```bash
taskr . status 001 done
taskr . status 003 nonsense
```

The first fails while the milestone has unfinished children. The second fails
because the status is unknown.

## Open Item Workflow

Speculative command sequence:

```bash
EDITOR=true taskr . open 003
taskr . open 003 --system
```

Expected output:

```text
opened path=001-mvp/003-workflows-definieren/task.md opener=editor
opened path=001-mvp/003-workflows-definieren/task.md opener=system
```

Expected failure tests:

```bash
EDITOR= taskr . open 003
taskr . open missing
```

The first fails when no editor/opener can be resolved. The second fails with no
selector match.

## Report Workflow

Speculative command sequence:

```bash
taskr . report --under 001
taskr . report --under 001 --type task --status done
taskr . report --under 001 --type task --status done --output "${SMOKEY_STATE_DIR}/done.txt"
```

Expected stdout report:

```text
report root=... under=001 type=task status=done count=1
002 done Define directory structure
```

Expected file report output:

```text
wrote report path=.../done.txt count=1
```

Expected failure tests:

```bash
taskr . report --under missing
taskr . report --status nonsense
taskr . report --output /not-writable/report.txt
```

Missing parent, unknown filter, and unwritable target all fail.

## Archive Workflow

Speculative command sequence:

```bash
taskr . archive 002 --to 2026
taskr . list --under archive/2026
```

Expected success output:

```text
archived id=002 from=001-mvp/002-verzeichnisstruktur to=archive/2026/002-verzeichnisstruktur items=1
```

Expected failure tests:

```bash
taskr . archive 001
taskr . archive 003
```

The first fails while the milestone has active children. The second fails while
the selected task is not closed.
