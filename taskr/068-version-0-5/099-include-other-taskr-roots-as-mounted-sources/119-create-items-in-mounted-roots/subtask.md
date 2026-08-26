---
title: Create items in mounted roots
status: reviewing
created_at: 2026-08-25T17:27:18Z
updated_at: 2026-08-25T20:15:43Z
designing_at: 2026-08-25T17:27:18Z
developing_at: 2026-08-25T19:15:04Z
reviewing_at: 2026-08-25T20:15:43Z
---

# Description

Extend `taskr create milestone|task|subtask` so work items can be created in a
read-write mounted root.

The selected mount becomes the target root for the creation. The parent root
only supplies the mount configuration and selector namespace; the new marker
directory and marker file are written inside the mounted root.

Example forms:

- `taskr create milestone "Imported Roadmap" --mount vendor`
- `taskr create task "Local work" --mount . --under .:003`
- `taskr create task "New work" --mount vendor --under 003`
- `taskr create subtask "Follow-up" --mount vendor --under vendor:003`

# Acceptance

- `taskr create milestone|task|subtask ... --mount <id>` targets the selected
  mounted root.
- `taskr create milestone|task|subtask ... --mount .` targets the current local
  root explicitly.
- The mount must be writable through the whole transitive mount chain.
- Transitive read-write mounts are valid create targets when the complete mount
  chain is writable.
- Creating work through a read-only mount fails clearly and leaves every root
  unchanged.
- `--under` resolves inside the selected mounted root.
- `--under` accepts both mount-prefixed selectors such as `vendor:003` and
  unprefixed selectors such as `003` when unambiguous inside the selected
  mount.
- A mount-prefixed `--under` selector must match the selected `--mount` target.
  For example, `--mount archive --under vendor:003` fails clearly instead of
  crossing into another mounted root.
- `--under` accepts local-root-prefixed selectors such as `.:003` when
  `--mount .` targets the current root.
- A `--mount` value that is unknown, ambiguous, unavailable, cyclic, or blocked
  by duplicate transitive mount IDs fails clearly.
- New item IDs are allocated from the target mounted root, not the parent root.
- New marker directories and marker files are written only in the mounted root.
- Existing create behavior for local work remains unchanged when `--mount` is
  omitted.
- Help, docs, examples, and shell completion cover `create ... --mount` and
  mounted `--under` selectors.
- Smokey covers mounted milestone creation, mounted task creation under a
  milestone, mounted subtask creation under a task, read-only rejection,
  transitive read-write creation, `--mount .`, `.:003`, prefixed and unprefixed
  `--under`, target-root ID allocation, unchanged parent root, invalid mount
  selectors, mismatched `--mount`/`--under` prefixes, and completion.

# Comments

- 2026-08-25: Added after Michael noted that creating normal work items in a
  writable mounted root is a separate create-command surface from creating the
  mount object itself.
- 2026-08-25: Creation must also work through transitive writable mounts.
  `.` is the explicit current-root placeholder for `--mount` and prefixed local
  selectors.
- 2026-08-25: A prefixed `--under` selector must point into the same root as
  `--mount`; mixing two mounted roots in one create command is an error.

# Outcome

Item creation can target local, direct, or transitive writable roots with
root-relative parent selection and target-root ID allocation.

# Release Notes

`taskr create` supports `--mount` for writable mounted roots.
