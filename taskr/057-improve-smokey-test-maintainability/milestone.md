---
title: Improve Smokey test maintainability
status: designing
created_at: 2026-08-10T12:13:20Z
updated_at: 2026-08-10T12:13:20Z
---

# Description

Improve Smokey test maintainability so users can quickly get an overview of
what the smoke tests cover and how a workflow is exercised. Workflow tests
should remain easy to read, review, and debug as coverage grows. Test helper
abstractions should make intent clearer, not hide the behavior being tested
behind single-use indirection or distant helper blocks.

# Acceptance

- `AGENTS.md` defines readability expectations for Smokey tests.
- The policy states that a user must be able to quickly understand the covered
  workflow and major assertions by scanning a Smokey `run.sh`.
- The policy says single-use helpers should be avoided unless they materially
  improve clarity.
- The practice of extracting larger test sections into functions is discussed
  explicitly, including pros and cons.
- `AGENTS.md` captures the agreed rule for when larger Smokey sections should
  become named functions and when they should stay inline.
- The policy says helper names and test call sites must make the user-visible
  workflow and expected behavior easy to understand locally.
- Existing Smokey tests are reviewed for unnecessary indirection, especially
  completion tests with many one-off assertion helpers.
- Existing Smokey tests are simplified where doing so improves local
  readability without weakening coverage.
- Any simplification keeps tests directory-based, Smokey-managed, and fixture
  based.
- Verification continues to run through `smokey --tests-dir tests.d`.

# Comments

- 2026-08-10: Added after reviewing selector completion tests where several
  single-use Bash helpers made the actual test behavior harder to inspect in
  truncated output.
- 2026-08-10: User clarified the primary goal: users must be able to quickly
  understand smoke test coverage. The milestone should explicitly discuss the
  tradeoff of named functions for larger sections and then codify the agreed
  practice in `AGENTS.md`.

# Outcome
