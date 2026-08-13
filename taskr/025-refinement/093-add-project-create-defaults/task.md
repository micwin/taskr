---
title: Add project create defaults
status: developing
created_at: 2026-08-13T20:40:36Z
updated_at: 2026-08-13T20:45:54Z
designing_at: 2026-08-13T20:40:36Z
developing_at: 2026-08-13T20:45:54Z
---

# Description

Add a root-local `[defaults]` section to `taskr.toml` for shared project
defaults that influence item creation. The first required setting controls the
initial status used by `taskr create` when no explicit `--status` is supplied.

Project defaults must remain distinct from personal preferences. Editor,
browser, pager, and other machine- or user-specific behavior stays in personal
configuration rather than the versionable Taskr-root configuration.

# Acceptance

- Root-local `taskr.toml` accepts a strict `[defaults]` table.
- The table supports one common `create_status` plus optional
  `milestone_status`, `task_status`, and `subtask_status` overrides:
  ```toml
  [defaults]
  create_status = "designing"
  task_status = "developing"
  ```
- A type-specific value takes precedence for that item type. Otherwise Taskr
  uses `create_status`, then the built-in `open` fallback.
- With no `taskr create --status`, Taskr uses the configured project default.
- An explicit `--status` always overrides the project default.
- Without a configured default, create retains its built-in `open` behavior.
- The configured value follows ticket `054`: only statuses valid for newly
  created work are accepted, while `done` and `cancelled` are rejected.
- Invalid default values are reported by Doctor and block commands that load
  the root under the existing strict project-configuration policy.
- The common default applies to milestone, task, and subtask creation; each
  item type may override it independently without requiring all overrides.
- Candidate additional project defaults are inventoried and classified before
  inclusion. A setting is added only when it is shared project policy rather
  than a personal preference and does not duplicate canonical marker data.
- `taskr config` from ticket `088` may later provide mutation commands, but
  direct TOML editing remains sufficient for this ticket.
- Smokey covers configured default use, explicit override, absent default,
  invalid and closed values, all supported item types, Doctor behavior, help,
  examples, and completion impact.
- Documentation, Doctor, help, examples, completion, and public API impact are
  reviewed before the ticket moves to `reviewing`.

# Comments

- 2026-08-13: Created while preparing ticket `054`. The initial requirement is
  one project-wide default initial status under `[defaults]`; additional shared
  defaults may be included only after individual review.
- 2026-08-13: Personal editor and browser behavior explicitly remains outside
  root-local `taskr.toml`.
- 2026-08-13: Agreed to support both one common `create_status` and optional
  `milestone_status`, `task_status`, and `subtask_status` values. Explicit CLI
  status wins, followed by the matching type override, common default, and
  built-in `open` fallback.

# Outcome
