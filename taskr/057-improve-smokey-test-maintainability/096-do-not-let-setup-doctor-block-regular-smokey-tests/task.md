---
title: Do not let setup doctor block regular Smokey tests
status: developing
created_at: 2026-08-17T06:56:21Z
updated_at: 2026-08-17T07:01:34Z
designing_at: 2026-08-17T06:56:21Z
developing_at: 2026-08-17T07:01:34Z
---

# Description

Define how setup doctor diagnostics should interact with ticket lifecycle and
release readiness. The shared fixture doctor run is useful feedback during
regular development, but it must not encourage every feature test to create a
private fixture root just because a future contract is temporarily ahead of the
implementation.

Code must not be committed for `reviewing` or `done` states when the setup
doctor reports problems, regardless of whether doctor can fix those problems.
Regular development runs in other states may continue after setup doctor
diagnostics, but the output must remain visible.

The exact technical mechanism is still open. Possible approaches include an
explicit environment variable for strict gates, a release-branch check, a final
explicit doctor assertion before review/done, or another mechanism agreed with
the user. Negativtests that intentionally keep doctor-broken data require their
own suite or fixture root.

# Acceptance

- Document the policy for setup doctor output during ordinary development,
  `reviewing`, `done`, and release readiness.
- Decide how strict setup doctor enforcement is activated without making Smokey
  test code depend directly on Taskr ticket status unless explicitly agreed.
- Ensure strict enforcement breaks the relevant build or test when doctor
  reports problems.
- Keep ordinary non-strict doctor runs visible but non-blocking.
- Document that intentionally doctor-broken negative test data belongs in a
  dedicated suite or fixture root.

# Comments

- 2026-08-17: Added after tag workflow tests exposed that a hard setup doctor
  gate encourages unnecessary fixture duplication whenever a future contract
  temporarily makes the shared fixture invalid before implementation.
- 2026-08-17: Clarified that the `|| true` change in `000-setup` is part of
  preparing the tag workflow contract, not the full solution for this ticket.
  This ticket remains about defining and implementing the strict gate policy.

# Outcome
