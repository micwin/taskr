---
title: Rename items
status: developing
created_at: 2026-08-10T10:41:47Z
updated_at: 2026-08-10T16:07:46Z
developing_at: 2026-08-10T16:07:46Z
---

# Description

Add a CLI workflow for renaming Taskr items without manual directory moves.
The command contract is:

```text
taskr rename <selector> <new-title>
taskr rename <selector> <new-title> --slug <custom-slug>
taskr rename <selector> <new-title> --keep-slug
```

By default, renaming updates the item title and derives a new directory slug
from that title. `--slug` overrides the derived slug, while `--keep-slug`
changes only the title. A slug-only operation is deliberately not provided.
The numeric item id and existing subtree remain unchanged.

# Acceptance

- `taskr rename <selector> <new-title>` renames milestone, task, and subtask
  items selected by any supported unambiguous selector.
- The numeric id is preserved during rename.
- The marker title is updated to `<new-title>`.
- By default, the directory slug is derived from `<new-title>` using the same
  normalization as `create`.
- `--slug <custom-slug>` uses a normalized custom slug instead of the derived
  title slug.
- `--keep-slug` changes the title without changing the directory slug.
- `--slug` and `--keep-slug` are mutually exclusive.
- Rename rejects an empty title or a slug that becomes empty after
  normalization.
- Existing children, files directories, comments, outcomes, and related content
  remain intact.
- Rename rejects target paths that would collide with an existing sibling.
- Rename fails clearly when the selector matches zero items. When it matches
  multiple items, the error lists each candidate's id and title and exits with
  status `2`.
- A real rename updates `updated_at`; a rename that changes neither title nor
  slug leaves the marker untouched.
- Documentation, help, examples, and completion are updated for the rename
  workflow.
- Selector completion offers milestones, tasks, and subtasks wherever
  `rename` accepts an item selector.
- Doctor remains clean after successful renames.
- Smokey tests cover default title/slug rename, a custom slug, title-only
  behavior, no-op timestamps, child and related-content preservation, selector
  failures, mutually exclusive flags, invalid input, collision rejection,
  completion, help, examples, and Doctor consistency.

# Comments

- 2026-08-10: Added after manually correcting the slug of ticket `028` while it
  was still in `designing`; future item renames should be available through
  Taskr itself.
- 2026-08-10: Agreed on a verb-first `rename` command. Title and slug change
  together by default; `--slug` overrides the derived slug and `--keep-slug`
  provides a title-only operation. Slug-only rename is intentionally omitted.

# Outcome
