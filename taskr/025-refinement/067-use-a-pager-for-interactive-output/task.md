---
title: Use a pager for interactive output
status: designing
created_at: 2026-08-10T14:15:00Z
updated_at: 2026-08-10T14:15:01Z
designing_at: 2026-08-10T14:15:01Z
---

# Description

Route human-readable command output through a pager when Taskr is attached to
an interactive terminal and a usable pager is available. Preserve direct
stdout behavior for scripts, pipes, redirects, unavailable pagers, and explicit
opt-out.

# Acceptance

- Taskr uses a pager only when its output is attached to an interactive
  terminal.
- Taskr writes directly to stdout when output is piped or redirected.
- Taskr writes directly to stdout when no usable pager is available.
- A global `--no-pager` flag disables pager use for the current invocation.
- Pager discovery and precedence between Taskr configuration, `$PAGER`, and
  PATH-based fallbacks are refined and documented before implementation.
- Pager startup failures produce a clear error and do not lose command output.
- Commands whose output can use the pager are explicitly defined; mutating
  command confirmations remain direct output.
- Help, completion, workflow documentation, and examples cover `--no-pager`
  and the configured default behavior.
- Smokey tests use controlled terminal and pager fixtures to cover interactive
  paging, unavailable pagers, `--no-pager`, piped output, redirected output,
  pager failures, and commands that must bypass paging.

# Comments

- 2026-08-10: Created from the requirement to use an available pager for
  interactive terminal output while preserving automation-safe stdout and an
  explicit `--no-pager` override.
- 2026-08-10: Pager discovery order and the exact set of pageable commands need
  interactive refinement before Smokey behavior is fixed.

# Outcome
