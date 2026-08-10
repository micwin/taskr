---
title: Edit ticket sections selectively
status: designing
created_at: 2026-08-10T10:01:48Z
updated_at: 2026-08-10T10:01:48Z
---

# Description

Add a command for editing individual sections of a Taskr item without opening
or rewriting the whole marker file manually. The command should support
interactive editing through `$EDITOR` and non-interactive replacement through
stdin or pipes.

# Acceptance

- A command exists to edit one named section of one selected item.
- Supported sections include `description`, `acceptance`, `comments`, and
  `outcome`.
- Section names are documented and validated.
- Default mode opens the selected section content in the configured editor and
  writes the edited content back to the marker.
- Editor selection follows Taskr's normal editor behavior, using `$EDITOR` or
  configured editor support when available.
- `--stdin` replaces the selected section with content read from stdin, so
  pipes and heredocs work.
- `--show-old` with `--stdin` writes the current section content before reading
  replacement input.
- The command preserves marker frontmatter and required section order.
- The command refuses unknown sections, missing selectors, missing stdin input,
  and ambiguous selectors.
- Help documents section names, editor mode, stdin mode, and `--show-old`.
- Shell completion covers selectors and section names.
- Smokey tests cover editor mode, stdin mode, `--show-old`, invalid sections,
  ambiguous selectors, and section-order preservation.

# Comments

- 2026-08-10: Added while refining comment workflows. Sometimes users need to
  update `# Description`, `# Acceptance`, `# Comments`, or `# Outcome` without
  opening the whole marker file.
- 2026-08-10: `--show-old` is intended for non-interactive stdin workflows where
  a caller wants to display the old section before replacing it.

# Outcome
