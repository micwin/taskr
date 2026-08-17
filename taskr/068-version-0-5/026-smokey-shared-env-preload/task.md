---
title: Move Smokey shared environment setup to preload
status: done
created_at: 2026-08-10T00:00:00Z
updated_at: 2026-08-17T12:53:22Z
developing_at: 2026-08-17T10:00:47Z
reviewing_at: 2026-08-17T10:03:20Z
done_at: 2026-08-17T12:53:22Z
---

# Description

Move shared Smokey environment setup out of repeated test scripts into
`tests.d/env.preseed`, the suite-level committed shared environment mechanism
documented by `smokey agents-help`.

Taskr's Smokey tests are suite tests. Individual `run.sh` files do not need to
be directly executable as standalone shortcuts. Direct `run.sh` execution
bypasses Smokey behavior such as setup ordering, shared environment handling,
state isolation, fail-fast behavior, and teardown. Keeping direct script
fallbacks alive is the wrong tradeoff here.

# Acceptance

- The correct Smokey shared environment mechanism is identified from `smokey
  agents-help` as `tests.d/env.preseed`.
- `tests.d/env.preseed` is added and contains committed shared exports for
  suite-wide variables derived from `SMOKEY_STATE_DIR`.
- Shared variables such as `TASKR_BIN`, fixture roots, and config paths are
  initialized once for the suite through `env.preseed`.
- `000-setup/run.sh` uses the shared variables but no longer defines or saves
  the same shared values with `smokey_env_save`.
- Individual test scripts stop redefining shared variables that belong in
  `env.preseed`.
- Direct-test fallback patterns such as `${TASKR_BIN:-...}` are removed from
  Smokey test scripts when they only exist to make direct `run.sh` execution
  work.
- The suite remains intentionally suite-only; direct execution of individual
  `run.sh` files is not supported and must not drive test design.
- Smokey-managed state remains the only place for generated roots, configs,
  logs, binaries, and package artifacts.
- `smokey --tests-dir tests.d` passes.

# Comments

- 2026-08-10: Current tests define fallback environment variables in many
  scripts. That setup belongs in the suite preload if Smokey supports it.
- 2026-08-17: `smokey agents-help` names the committed shared environment file
  `tests.d/env.preseed`, not `env.preload`.
- 2026-08-17: Michael clarified that standalone execution of individual
  `run.sh` scripts is not a goal. The Smokey suite must run as a suite; direct
  run-script fallbacks are actively undesirable.

# Outcome

Implemented `tests.d/env.preseed` as the single committed source for shared
Smokey suite variables derived from `SMOKEY_STATE_DIR`.

Removed duplicated suite-wide `TASKR_*` variable initialization, direct-run
fallback expressions, and `smokey_env_save` usage from the setup and workflow
scripts. Individual Smokey tests now rely on suite-managed state and setup
ordering instead of trying to remain standalone executable.

Centralized repeated Smokey helper functions for command capture and copied
fixture roots in `tests.d/env.preseed`, so workflow scripts use the suite
environment instead of redefining those helpers locally.

Verified with `smokey --tests-dir tests.d`: 32/32 tests passed.
