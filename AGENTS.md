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

## Dogfood Work

- Tickets that concern Taskr itself are dogfood work. Track Taskr process,
  policy, and agent-workflow changes under the Dogfood milestone in `taskr/`.
- The implementation scope policy belongs in
  `taskr/012-dogfood/011-implementation-scope-policy/task.md`; update that
  ticket before changing how broadly implementation agents may act beyond the
  active ticket.

## Implementation Scope

- Work from the active Taskr ticket. Keep code, tests, docs, and ticket updates
  close to that ticket's `# Acceptance` and `# Description`.
- Do directly required supporting work inside the active ticket when it is
  needed to satisfy acceptance. Examples: create required directories, add a Go
  module for a Go CLI ticket, wire Smokey to a binary that the ticket requires,
  or remove build artifacts created during verification.
- Do small same-surface corrections inside the active ticket when they are
  necessary for that ticket's stated behavior. Examples: add a missing
  subcommand named in the ticket, fix help text for that subcommand, or expose
  a flag already specified by the active ticket's command contract.
- Create a new Taskr ticket instead of implementing silently when a discovered
  issue changes behavior, data model, command names, flags, workflows,
  validation policy, release process, or agent process beyond the active
  ticket's acceptance.
- Ask the user before editing when scope is ambiguous or a change affects
  semantics. Examples: status meaning, ID rules, hierarchy derivation, archive
  location, root discovery, selector matching, or exit-code policy.
- If a follow-up is found while implementing, record it as dogfood when it
  concerns Taskr development process or as MVP/product work when it concerns
  user-visible Taskr behavior.
- Until this policy changes, create commits only after the user explicitly asks
  for a commit. Prepare coherent commit scopes when status changes or ticket
  closures require them, but leave the changes uncommitted until requested.
- If a file change or decision changes a Taskr ticket's status, commit the
  status change together with the corresponding intended file changes.
- When closing a ticket as `done`, commit the ticket status, its `# Outcome`,
  and the changes that make the ticket done in the same commit. This does not
  apply to `cancelled` or other non-delivery closures where no implementation
  changes are intended.
- Before closing a ticket after relevant code changes, check whether `doctor`,
  command help, shell completion, and any public API already cover the changed
  behavior correctly. If they do not, update them in the active ticket before
  closing it. Do not close the ticket with stale `doctor`, help, completion, or
  API behavior.

## Ticket Lifecycle

- Create new tickets only in `designing`.
- Develop ticket wording interactively with the user while the ticket is in
  `designing`.
- Write or change Smokey tests while the ticket is in `designing`, so the
  expected behavior is fixed before implementation starts.
- After a ticket leaves `designing`, change its `# Description`,
  `# Acceptance`, or Smokey test program logic only with explicit user
  interaction for that specific change.
- After a ticket leaves `designing`, edits to the ticket `# Comments` section
  and comments inside Smokey test scripts are allowed without changing the
  agreed behavior.
