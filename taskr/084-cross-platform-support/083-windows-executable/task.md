---
title: Build Windows executable
status: designing
created_at: 2026-08-10T18:04:45Z
updated_at: 2026-08-10T18:04:58Z
designing_at: 2026-08-10T18:04:58Z
---

# Description

Build and publish a native Windows Taskr executable from the Go source. The
initial deliverable is a standalone `.exe`, not an MSI or other installer.

Cross-compilation success alone is insufficient. Audit direct and transitive
libraries plus Taskr's own filesystem, configuration, editor/opener, shell, and
process behavior for Windows compatibility. Platform-specific behavior must be
implemented explicitly or reported as unsupported with an actionable error.

# Acceptance

- The design selects and documents the initial Windows architecture; Windows
  AMD64 is the default proposal and additional architectures remain explicit.
- `scripts/build.sh` can produce a versioned Windows executable through Go
  cross-compilation without changing the existing Linux binary or Debian
  package behavior.
- The Windows filename contains the committed `VERSION+BUILD`, target OS, and
  architecture and ends in `.exe`.
- The executable embeds the same version, commit, and build-time metadata as
  other release artifacts.
- The build documents whether `CGO_ENABLED=0` is required and fails clearly if
  a dependency prevents a reproducible cross-build.
- Direct and transitive Go dependencies are inventoried and checked for Windows
  build compatibility; OS-specific files, build tags, CGo use, and external
  command assumptions are reviewed explicitly.
- Taskr code is audited for path separators, executable suffixes, temporary and
  user configuration directories, environment variables, file permissions,
  editor/browser/system-opener invocation, shell completion, and subprocess
  behavior on Windows.
- Every existing command either compiles with defined Windows behavior or has
  a documented, tested, actionable unsupported-platform error.
- CI cross-builds the Windows executable on every relevant change and verifies
  its PE format, filename, and embedded version without requiring a graphical
  Windows host.
- The release workflow publishes the Windows executable and includes it in the
  generated SHA-256 checksum file.
- Download and installation documentation explains how to place and invoke the
  `.exe`; an installer remains out of scope.
- Smokey or focused build tests cover build-script arguments, artifact naming,
  version preservation, checksum inclusion, and failure behavior. Any behavior
  that requires a real Windows runtime has an explicit verification plan.
- Help, examples, completion, Doctor, public API, release notes, and release
  documentation are reviewed before the ticket leaves implementation.

# Comments

- 2026-08-10: Go makes the artifact itself straightforward, but Windows support
  also depends on libraries and Taskr's Unix-oriented runtime assumptions. The
  compatibility audit is therefore part of the deliverable, not a follow-up.
- 2026-08-10: MSI packaging, code signing, and automatic installation are not
  implied by the initial standalone executable and require separate decisions.

# Outcome
