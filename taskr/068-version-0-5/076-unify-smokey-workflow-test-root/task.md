---
title: Unify Smokey workflow test root
status: designing
created_at: 2026-08-10T15:45:27Z
updated_at: 2026-08-10T15:45:27Z
designing_at: 2026-08-10T15:45:27Z
---

# Description

Unify normal Smokey workflows around one cumulative Taskr root instead of
giving every test directory its own isolated copy. The shared root should prove
that commands and features continue to understand the same database after
earlier workflows mutate it.

Keep dedicated roots only where isolation is required to construct invalid,
corrupt, destructive, or otherwise intentionally incompatible states.

# Acceptance

- `000-setup` creates one Smokey-managed shared workflow root from the committed
  valid fixture.
- Normal create, selector, status, open, report, move, tree, priority, comment,
  archive, and related CLI workflows use the same cumulative root where their
  semantics permit it.
- Tests consume the state produced by earlier workflows intentionally rather
  than silently rebuilding their own independent world.
- Dedicated roots require a short documented reason, such as invalid marker
  structure, duplicate IDs, malformed metadata, Doctor repair input,
  destructive archive scenarios, or mutually incompatible edge conditions.
- The design inventories every existing per-workflow root and decides whether
  it joins the shared root or remains specialized.
- Test ordering and ownership of cumulative mutations are explicit and
  readable.
- The actual distinction between shell fail-fast inside one `run.sh` and
  Smokey continuing with later test directories is documented and tested.
- The implementation prevents one expected failure from causing misleading
  cascades in later shared-root workflows, either through runner behavior,
  dependency gating, or another explicitly agreed mechanism.
- `TASKR_BASE_ROOT`, the mutable shared root, and specialized roots have names
  that make their roles unambiguous.
- `smokey agents-help`, test documentation, and repository agent guidance are
  updated if the shared-root policy changes their required conventions.
- The full suite remains deterministic from a clean Smokey state and reports
  failures at the workflow that introduced the invalid shared state.

# Comments

- 2026-08-10: A single test script uses shell fail-fast, but Smokey currently
  continues running later test directories and summarizes all failures. Shared
  mutable state therefore needs an explicit strategy for preventing cascading
  diagnostics.
- 2026-08-10: Priority tests motivated the change: command, list, tree, report,
  show, help, and completion should demonstrate interoperability against one
  evolving root, while deliberately invalid Doctor inputs still need isolated
  copies.

# Outcome
