# Repository Guidelines

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
- Follow the release process documented in `RELEASING.md` for Taskr releases.
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
- Create Taskr dogfood items with `taskr create` when the command can satisfy
  the needed operation. Do not create item directories or marker files by hand
  merely for convenience.
- Move Taskr dogfood items with `taskr move` when the command can satisfy the
  needed operation. Do not move item directories by hand merely for
  convenience.
- Direct text edits inside existing dogfood marker files remain allowed for
  `# Description`, `# Acceptance`, `# Comments`, and `# Outcome`, subject to
  the ticket lifecycle rules below.
- Direct filesystem manipulation of dogfood structure is acceptable only before
  a supporting Taskr command exists, when the command cannot satisfy the needed
  operation, or after explicit user approval.
- Run `taskr doctor` after structural dogfood changes.

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
- If a file change or decision changes a Taskr ticket's status before
  acceptance, commit the status change together with the corresponding
  intended file changes.
- Implementation commits end with the ticket in `reviewing` and include the
  delivered code, tests, documentation, help, examples, completed `# Outcome`,
  applicable release note, and the ticket status change.
- Commit review corrections while the ticket remains in `reviewing`. Do not
  combine implementation or review corrections with ticket acceptance.
- Move a ticket from `reviewing` to `done` only after explicit user instruction
  and in a dedicated closure commit. That commit contains only the ticket
  status and timestamp update plus the required `BUILD` update.
- When moving a Taskr dogfood ticket to `done`, record release-note intent in
  that same dedicated closure commit. User-visible changes need a concise
  `# Release Notes` section in the ticket marker file. Tickets without
  user-visible release impact use `release_note: no-release-note` in
  frontmatter.
- The dedicated closure-commit rule applies to `done`; it does not
  automatically prescribe the commit shape for `cancelled` or other
  non-delivery closures.
- Before moving a ticket with relevant code changes to `reviewing`, check
  whether `doctor`, command help, shell completion, and any public API already
  cover the changed behavior correctly. If they do not, update them in the
  active ticket first. Do not mark the ticket review-ready with stale
  `doctor`, help, completion, or API behavior.
- Before moving a ticket that adds or changes commands, subcommands, flags,
  inputs, or user-visible command behavior to `reviewing`, update the relevant
  user documentation, command help, and workflow examples.
- Examples must cover every new or changed command, subcommand, flag, and
  important command variant. Provide a normal example and, for non-trivial
  input modes or commands with flags or subcommands, an advanced or edge-case
  example. Do not label those forms as normal, advanced, expert, or edge-case
  in user-facing documentation.
- The user-controlled transition from `reviewing` to `done` must not defer
  documentation, help, or example work that belongs to implementation.
- Every new or changed command argument or flag that accepts Taskr item IDs or
  slugs must wire shell completion for those values. Smokey must test
  completion at the exact argument or flag surface where IDs or slugs are
  accepted, not only through another command that shares the same helper.

## Ticket Lifecycle

- Create new tickets only in `designing`.
- Develop ticket wording interactively with the user while the ticket is in
  `designing`.
- Write or change Smokey tests while the ticket is in `designing`, so the
  expected behavior is fixed before implementation starts.
- During refinement, propagate every agreed requirement into the canonical
  `# Description`, `# Acceptance`, and applicable Smokey test logic as soon as
  consensus is reached. Do not leave accepted behavior recorded only in
  `# Comments` or defer propagation until implementation or closure.
- Treat `# Comments` as discussion history and supporting context, not as the
  canonical source for accepted requirements.
- When implementation work starts on a ticket, set it to `developing` unless
  the user explicitly keeps it in `designing`.
- After a ticket leaves `designing`, change its `# Description`,
  `# Acceptance`, or Smokey test program logic only with explicit user
  interaction for that specific change.
- After a ticket leaves `designing`, edits to the ticket `# Comments` section
  and comments inside Smokey test scripts are allowed without changing the
  agreed behavior.
- Do not rewrite all existing tickets merely to migrate refinements out of
  Comments. Correct an affected ticket when it is next actively refined,
  implemented, reviewed, or explicitly audited, and never change an inactive
  ticket's semantics without user interaction.
- When an agent considers an implementation ticket complete, set it to
  `reviewing`. Use `done` or `cancelled` only after explicit user instruction.
- After a ticket reaches `reviewing`, semantic changes to the ticket, Smokey
  test logic, code behavior, documentation behavior, or process outcome require
  explicit user instruction.
