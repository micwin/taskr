---
title: Do not let setup doctor block regular Smokey tests
status: developing
created_at: 2026-08-17T06:56:21Z
updated_at: 2026-08-17T07:01:34Z
designing_at: 2026-08-17T06:56:21Z
developing_at: 2026-08-17T07:01:34Z
---

# Description

Change the Smokey `000-setup` doctor call from a hard suite gate into a visible
diagnostic helper for regular development runs. The shared fixture should still
emit doctor output when it is inconsistent, but ordinary workflow tests should
not require a globally doctor-clean fixture just to exercise one changed
contract.

Release builds still need a strict doctor gate. That stricter behavior belongs
in the release/build workflow, not in the regular Smokey setup helper, and it
must break the release build or release test when doctor reports problems.

# Acceptance

- `tests.d/000-setup/run.sh` runs doctor against the shared valid fixture and
  prints useful output when doctor reports problems.
- A failing setup doctor does not stop the regular Smokey suite.
- The ticket documents that release builds must keep or add a separate strict
  doctor check before producing release artifacts, and that this release gate
  fails the build or release test on doctor errors.
- The change does not hide setup failures unrelated to the doctor diagnostic.

# Comments

- 2026-08-17: Added after tag workflow tests exposed that a hard setup doctor
  gate encourages unnecessary fixture duplication whenever a future contract
  temporarily makes the shared fixture invalid before implementation.

# Outcome
