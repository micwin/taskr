---
title: Move Smokey shared environment setup to preload
status: designing
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-10T00:00:00Z
---

# Description

Move shared Smokey environment setup out of repeated test scripts into the
suite-level preload mechanism so common variables are available to all tests
consistently.

# Acceptance

- The correct Smokey preload mechanism is identified from `smokey agents-help`.
- Shared variables such as `TASKR_BIN`, fixture roots, and config paths are
  initialized once for the suite.
- Individual test scripts stop redefining shared variables that belong in the
  preload.
- Smokey-managed state remains the only place for generated roots, configs,
  logs, binaries, and package artifacts.
- `smokey --tests-dir tests.d` passes.

# Comments

- 2026-08-10: Current tests define fallback environment variables in many
  scripts. That setup belongs in the suite preload if Smokey supports it.

# Outcome
