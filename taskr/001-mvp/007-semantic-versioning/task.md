---
title: Introduce semantic versioning
status: done
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Define version source, version command output, tag format, and release version
rules.

# Acceptance

- Version numbers follow semantic versioning.
- `taskr version` reports the application version in a stable format.
- Build metadata is injected by the project build script.
- The project build script increments the build counter automatically.
- The project build script supports `--raise-minor` and `--raise-major`.
- `--raise-minor` increments minor and resets patch to `0`.
- `--raise-major` increments major and resets minor and patch to `0`.
- Raising major or minor does not reset the monotonic build counter.
- Git tag naming and release branch naming are documented.
- Smokey or unit coverage verifies the version command output.
- Build numbers use SemVer build metadata, for example `0.1.0+42`, and are
  monotonic across application versions.

# Comments

- 2026-06-03: Versioning belongs in MVP because release artifacts need stable
  names.
- 2026-08-07: Build numbers should not consume the SemVer patch component.
  Use `+<build>` metadata so `0.1.0+42` means application version `0.1.0`,
  build `42`.
- 2026-08-07: Version raising belongs in the build script. The script owns
  monotonic build-counter increments and can bump major or minor while leaving
  the build counter monotonic across versions.

# Outcome

Implemented SemVer-based build versioning:

- `VERSION` stores `MAJOR.MINOR.PATCH`.
- `BUILD` stores the monotonic build counter.
- `scripts/build.sh binary` reads both files, increments `BUILD`, and injects
  `MAJOR.MINOR.PATCH+BUILD` through Go ldflags.
- `scripts/build.sh binary --raise-minor` increments minor and resets patch to
  `0` without resetting the build counter.
- `scripts/build.sh binary --raise-major` increments major and resets minor and
  patch to `0` without resetting the build counter.
- `taskr version` prints injected version metadata and includes `commit=` and
  `built_at=` when those values are provided.

Pre-close checks:

- `go test ./...` passes.
- `taskr --help` renders successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes through `070-version-workflow`; later
  packaging coverage belongs to `014-debian-package`.
- No public API exists yet.
