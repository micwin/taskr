---
title: Validate ticket structure in doctor
status: designing
created_at: 2026-08-10T10:35:05Z
updated_at: 2026-08-10T10:35:05Z
---

# Description

Extend `taskr doctor` so it validates the internal structure of Taskr marker
files, not only the directory/marker presence rules. A valid marker must keep
the agreed storage sections and metadata shape so CLI commands can safely read,
show, report, edit, and close items.

# Acceptance

- `taskr doctor` verifies that each item marker has exactly one supported role
  marker file for its directory.
- `taskr doctor` verifies that required frontmatter fields exist and are
  parseable.
- `taskr doctor` verifies that required H1 sections exist in the agreed order:
  `# Description`, `# Acceptance`, `# Comments`, `# Outcome`.
- `taskr doctor` rejects duplicate required sections and unknown replacement
  section names that would make command behavior ambiguous.
- Files directories marked by `files.md` remain exempt from item marker
  validation below that directory.
- The check covers milestone, task, and subtask markers consistently.
- Documentation and help describe the marker structure checks accurately.
- Smokey tests cover valid markers, missing sections, duplicate sections,
  malformed frontmatter, wrong section order, and ignored files directories.

# Comments

- 2026-08-10: Added after the status lifecycle discussion because stricter
  lifecycle commands depend on marker files having a predictable shape.

# Outcome
