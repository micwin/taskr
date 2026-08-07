---
title: Add red Smokey workflow tests
status: done
created_at: 2026-06-03T00:00:00Z
updated_at: 2026-06-03T00:00:00Z
---

# Description

Create directory-based Smokey tests for the full command workflow and verify
they fail for the expected reasons before implementation.

# Acceptance

- Smokey tests are directory-based under `tests.d/`.
- Tests run only through `smokey --tests-dir tests.d`.
- Test roots, configs, logs, and binaries are created below `${SMOKEY_STATE_DIR}`.
- The suite covers the full MVP workflow from root creation through doctor.
- Before implementation, the suite fails for missing or incomplete Taskr behavior.

# Comments

- 2026-06-03: Tests must use Smokey-managed state and suite execution only.
- 2026-06-04: Added directory-based Smokey tests derived from
  `004-erste-kommandos`.

# Outcome

Created a directory-based Smokey suite under `tests.d/`:

```text
000-setup/
010-doctor-workflow/
020-create-workflow/
030-selector-show-list/
040-status-open-workflow/
050-report-workflow/
060-archive-workflow/
999-teardown/
```

The suite uses committed fixtures from `tests.d/000-setup/fixtures`, copies
mutable roots into `${SMOKEY_STATE_DIR}`, and covers every MVP workflow defined
in `004-erste-kommandos`: doctor, create, selector resolution, show/list,
status propagation, open, report, and archive.

Verification command:

```bash
smokey --tests-dir tests.d
```

Current result is red for the expected reason: no `taskr` CLI binary exists yet.
Smokey initial teardown and final teardown both ran successfully.
