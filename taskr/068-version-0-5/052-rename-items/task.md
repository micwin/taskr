---
title: Rename items
status: designing
created_at: 2026-08-10T10:41:47Z
updated_at: 2026-08-10T10:41:47Z
---

# Description

Add a CLI workflow for renaming Taskr items without manual directory moves.
Renaming should update the item title and, when requested or by default, the
directory slug while preserving the numeric item id and the existing subtree.

# Acceptance

- A command or flag supports renaming milestone, task, and subtask items by
  selector.
- The numeric id is preserved during rename.
- The marker title is updated consistently with the requested new title.
- The directory slug is updated consistently unless the final command design
  explicitly separates title-only and slug changes.
- Existing children, files directories, comments, outcomes, and related content
  remain intact.
- Rename rejects target paths that would collide with an existing sibling.
- Rename fails clearly when the selector matches zero or multiple items.
- Documentation, help, examples, and completion are updated for the rename
  workflow.
- Smokey tests cover title/slug rename, title-only behavior if supported,
  child preservation, selector failures, and collision rejection.

# Comments

- 2026-08-10: Added after manually correcting the slug of ticket `028` while it
  was still in `designing`; future item renames should be available through
  Taskr itself.

# Outcome
