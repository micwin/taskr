---
title: Add comment command
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Add a `comment` command that appends a dated entry to an item's `# Comments`
section from the command line. This keeps routine ticket notes inside the Taskr
workflow without opening an editor for small updates.

# Acceptance

- `taskr comment <selector> <text>` appends the text to the selected item's
  `# Comments` section.
- The appended comment includes the current local date and time.
- Each invocation appends one complete comment entry.
- The command errors if the selector is missing, unknown, or ambiguous.
- The command preserves the required marker section order and keeps
  `# Outcome` as the final section.
- Multi-line comments are supported through stdin so pipes and heredocs work.
- Leading and trailing whitespace is trimmed from comments.
- Runs of spaces and tabs inside a comment line are normalized to one space.
- CRLF and CR input are normalized to LF.
- Empty or whitespace-only stdin lines are omitted from multi-line comments.
- Single and double quote characters are preserved as comment text.
- Command help documents selector usage and comment input modes.
- Shell completion covers selectors for the command.
- Smokey tests cover single-line comments, multi-line comments, ambiguous
  selectors, and section preservation.

# Comments

- 2026-08-10: Added so common dogfood ticket notes can be written through the
  CLI instead of manual marker editing.
- 2026-08-10: Comments should include date and time. Multi-line comments should
  be accepted through stdin so users can pipe text or use heredocs.
- 2026-08-10: Whitespace handling was refined: trim both sides, collapse
  repeated spaces and tabs inside a line to one space, normalize CRLF/CR to LF,
  and drop empty stdin lines. Quote characters are preserved; shell quoting is
  not part of Taskr's parser once the shell has passed argv/stdin.

# Outcome
