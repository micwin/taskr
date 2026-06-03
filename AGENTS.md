# Repository Guidelines

First read and follow the active memory-castle agent instructions at
`~/.local/share/jeff/memcastle/codex/index.md`; this file only adds Taskr
repository-specific rules.

## Read These First

If present, review `README.md`, `DEVELOPER.md`, `RUNBOOK.md`, and docs under
`doc/` before acting. Their guidance overrides this file when instructions
conflict.

## Local Layout

- Keep source code under `src/`, documentation under `doc/`, Smokey suites
  under `tests.d/`, build intermediates under `work/`, release artifacts under
  `dist/`, and handoff files under `tmp/`.
- Do not make runtime code depend on `tmp/`, `work/`, or `dist/`.
- Use `develop` as the default base branch. Feature branches use
  `feature/<ticket-id>-<feature-slug>`; release branches use
  `release/v<major>.<minor>.<patch>`.

## Build And Test

- Prefer project scripts when they exist. If a new script is added, document its
  purpose and prerequisites.
- Use Smokey for user-visible workflows. Run the full suite with
  `smokey --tests-dir tests.d` when `tests.d/` exists.
- Smokey tests must follow `smokey agents-help`: suite-only execution,
  Smokey-managed state, readable directory tests, committed fixtures, and no
  direct-test fallbacks.

## Taskr-Specific Safety

- Secrets live in Vaultline. Documentation may mention Vaultline key names, but
  must never contain secret values.
- Do not commit generated artifacts, personal data, `*.vlx`, `work/`, `dist/`,
  or `tmp/` unless the user explicitly requests artifact versioning.
- Do not run `sudo`; provide exact commands for the user when root access is
  required.
