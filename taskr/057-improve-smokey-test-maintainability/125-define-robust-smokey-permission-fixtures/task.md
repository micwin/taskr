---
title: Define robust Smokey permission fixtures
status: designing
created_at: 2026-08-25T17:42:31Z
updated_at: 2026-08-25T17:42:31Z
designing_at: 2026-08-25T17:42:31Z
---

# Description

Define how Smokey should test permission and capability failures without
depending on fragile Unix mode-bit assumptions or privileged execution details.

Tests that use `chmod 000`, `chmod 555`, ownership changes, or similar tricks
can behave differently when run under unusual users, containers, root, mounted
filesystems, or platforms with different permission semantics. Taskr still
needs coverage for unreadable and unwritable paths, but normal workflow suites
should not become flaky because the test harness guessed wrong about the host.

The design should establish when to use capability probes, fake helpers,
dedicated negative-test suites, temporary mounts, or skip-with-diagnostic
behavior for host-dependent permission cases.

# Acceptance

- Document why chmod-only unreadable/unwritable fixtures are not reliable
  enough for ordinary Smokey workflow suites.
- Define the preferred strategy for testing unreadable path behavior.
- Define the preferred strategy for testing unwritable path behavior.
- Decide whether host-dependent permission tests belong in a dedicated suite,
  behind an environment flag, or behind a capability check.
- Define how tests should report skipped host-dependent permission cases if
  skipping is allowed.
- Update `AGENTS.md` or Smokey test guidance with the chosen rule.
- Existing permission-sensitive Smokey tests are audited after the rule is
  accepted.

# Comments

- 2026-08-25: Added while preparing ticket 108 tests. Chmod-based unreadable
  and unwritable mount tests were removed from the ordinary mount-create suite
  because Michael does not want tests that assume root or unusual permission
  behavior.

# Outcome
