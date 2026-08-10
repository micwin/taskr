---
title: Cover selector completion surfaces
status: done
created_at: 2026-08-10T11:31:47Z
updated_at: 2026-08-10T11:31:47Z
---

# Description

Extend Smokey coverage so every command argument or flag that accepts a Taskr
item selector is tested for ID and slug shell completion. The implementation
already uses shared selector completion helpers, but tests currently cover only
representative surfaces.

# Acceptance

- Smokey tests assert selector completion by ID and slug for `comment
  <selector>`.
- Smokey tests assert selector completion by ID and slug for `show <selector>`.
- Smokey tests assert selector completion by ID and slug for `tree [selector]`,
  limited to milestones and tasks with subtasks.
- Smokey tests assert selector completion by ID and slug for `status
  <selector>`.
- Smokey tests assert selector completion by ID and slug for `move <selector>`.
- Smokey tests assert `move <selector>` completion only suggests movable items:
  tasks and subtasks, but not milestones.
- Smokey tests assert selector completion by ID and slug for `open <selector>`.
- Smokey tests assert selector completion by ID and slug for `archive
  <selector>`.
- Smokey tests assert selector completion by ID and slug for `list --under` and
  `report --under`, limited to milestones and tasks with subtasks.
- Smokey tests assert selector completion by ID and slug for `create --under`,
  limited to possible parent items: milestones and tasks, including leaf tasks,
  but not subtasks.
- Smokey tests assert selector completion by ID and slug for `move --under`,
  limited by the source item type: tasks can move only under milestones, and
  subtasks can move only under tasks.
- Smokey tests assert move validation rejects moving tasks under tasks and
  subtasks under milestones.
- The tests keep using dedicated Smokey fixtures and do not depend on the
  Taskr dogfood database.
- `AGENTS.md` states that every new or changed command argument or flag that
  accepts Taskr IDs or slugs must wire shell completion for those values.
- `AGENTS.md` states that Smokey must test completion at the exact command
  argument or flag surface where IDs or slugs are accepted, not only through a
  representative shared helper.
- Documentation/help changes are only needed if the tests expose a mismatch in
  current behavior.

# Comments

- 2026-08-10: Added after confirming that all selector surfaces use the shared
  selector completion helper, while Smokey only checks `show` and
  `create --under` directly.
- 2026-08-10: Expanded to include an agent policy rule requiring completion and
  exact-surface Smokey coverage for every ID/slug selector surface.
- 2026-08-10: Added Smokey expectations for each selector argument and
  `--under` flag surface.
- 2026-08-10: Added coverage for rootless hidden Cobra completion calls such as
  zsh invoking `taskr __complete tree ""` from inside a Taskr root.
- 2026-08-10: Refined completion expectations: `tree` and read-only `--under`
  surfaces complete useful tree roots only, while write `--under` surfaces
  complete possible parent items and exclude subtasks.
- 2026-08-10: Refined `move --under` completion and tests to match the actual
  hierarchy constraints for task and subtask moves.
- 2026-08-10: Added a red Smokey expectation that `move <selector>` source
  completion excludes milestones because milestones are not movable in the
  current model.
- 2026-08-10: Implemented `move <selector>` completion to suggest only tasks
  and subtasks.

# Outcome

Selector completion coverage was expanded across all current ID/slug selector
surfaces. Completion behavior now distinguishes direct selectors, tree roots,
read-only parent filters, create parents, move sources, and move targets.
`AGENTS.md` requires exact-surface Smokey coverage for future ID/slug selector
surfaces.
