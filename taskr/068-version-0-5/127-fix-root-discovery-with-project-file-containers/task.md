---
title: Fix root discovery with project file containers
status: reviewing
created_at: 2026-10-06T13:51:29Z
updated_at: 2026-10-06T13:57:58Z
designing_at: 2026-10-06T13:51:29Z
developing_at: 2026-10-06T13:54:37Z
reviewing_at: 2026-10-06T13:57:58Z
---

# Description

Fix implicit root discovery when a project contains a files.md container next
to its taskr directory and unrelated source or agent directories. A files
container alone must not cause the entire project to be treated as a worktree.

# Acceptance

- Without an explicit root, discover ./taskr when the project has only file
  containers as root evidence and also contains unrelated directories.
- Preserve discovery of direct roots with work-item markers and initialized
  files-only roots whose directories are all file containers or archive areas.
- Explicit root selection remains strict and never silently falls back.
- Mount parent-directory resolution uses the same corrected candidate check.
- Smokey covers project file containers beside src and .crush, direct root
  operation, explicit invalid-root rejection, and mount parent resolution.
- Document candidate detection and verify Doctor, help, and completion.

# Comments

- 2026-10-06: Found during mount review. A repository-level files/files.md
  made the project look like a root; scanning then failed on .crush. Removing
  that directory only moved the failure to another non-item directory.

# Outcome

Root candidate detection distinguishes files-only worktrees from normal
project directories containing a file container. Implicit discovery and mount
parent resolution find the actual taskr child; explicit root validation stays
strict. Smokey covers both affected surfaces and rootless completion.

# Release Notes

Project-level file containers no longer prevent discovery of the taskr worktree.
