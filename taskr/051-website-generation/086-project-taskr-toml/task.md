---
title: Define project taskr.toml configuration
status: done
created_at: 2026-08-10T18:19:10Z
updated_at: 2026-08-10T19:32:50Z
designing_at: 2026-08-10T18:19:11Z
developing_at: 2026-08-10T18:30:42Z
reviewing_at: 2026-08-10T18:35:23Z
done_at: 2026-08-10T19:32:50Z
---

# Description

Introduce optional project-local configuration in `taskr.toml` at the Taskr
root. The file provides extensible, namespaced settings for Taskr features; the
initial consumer is the `[site]` section used by `taskr site init`, `generate`,
and `open`.

`taskr.toml` supplements the marker-based worktree. It must never duplicate or
override item roles, IDs, hierarchy, status, priority, or other information
derived from marker files and directory structure.

# Acceptance

- The canonical project configuration path is `<taskr-root>/taskr.toml`.
- The configuration language is TOML and the parser provides actionable file,
  key, and syntax errors.
- The schema is extensible through named tables; `[site]` is the first defined
  table and unrelated future tables do not require another project config file.
- Unknown tables and keys are hard errors so misspelled configuration cannot be
  ignored silently.
- The initial shape supports at least:

  ```toml
  [site]
  directory = "../site"
  ```

- Relative paths are resolved against the Taskr root rather than the caller's
  current working directory.
- `[site]` is optional. When present, `directory` is required, must be a
  nonempty string, and is exposed through an internal typed configuration API
  for subsequent site commands.
- `taskr.toml` does not make a directory a valid Taskr root by itself and does
  not replace marker-based root discovery or hierarchy validation.
- Item roles, IDs, parent relationships, status, priority, and duplicated
  marker metadata are rejected as project configuration concepts.
- Site initialization can add `[site]` without deleting unrelated supported
  tables, keys, or comments. General updates are deferred to task `088`.
- Project configuration is loaded independently from the previously specified
  personal YAML/`--config-file` surface. Personal configuration migration and
  cross-scope precedence are outside this ticket.
- Project configuration must not contain secrets; documentation points to
  Vaultline or environment-based runtime retrieval for secret values.
- Doctor validates the file, schema, path safety, and known values while still
  providing actionable diagnostics when configuration is malformed.
- Malformed or semantically invalid `taskr.toml` blocks normal commands that
  load the Taskr root. Doctor remains available, returns a nonzero status, and
  reports the project configuration error.
- `doctor --fix` does not rewrite or remove malformed project configuration.
- Smokey covers missing configuration, valid site configuration, syntax
  errors, unknown or misplaced keys, path resolution, preservation of unrelated
  settings, and precedence behavior.
- Help, documentation, examples, completion impact, and public API exposure are
  reviewed before implementation is closed.

# Comments

- 2026-08-10: A root-local `taskr.toml` was chosen over a hidden
  `.taskr-site.yaml`. The Taskr root already supplies scope, TOML tables support
  future features, and one project configuration avoids feature-specific files.
- 2026-08-10: This does not reverse the marker-only hierarchy decision from
  ticket `002`; project configuration may tune features but cannot describe the
  worktree structure.
- 2026-08-10: The first implementation is strict and project-local only.
  Unknown keys fail, invalid configuration blocks normal root commands, and
  Doctor diagnoses but does not fix TOML. Personal configuration remains a
  separate concern.
- 2026-08-10: Selected `github.com/pelletier/go-toml/v2` strict decoding. Taskr
  normalizes the library's structured unknown-field details into stable key
  diagnostics instead of exposing its generic strict-mode summary.

# Outcome

Taskr loads optional root-local `taskr.toml` through a typed project
configuration API. The initial optional `[site]` table requires one nonempty
string `directory`, resolves relative paths from the Taskr root, and is attached
to the loaded worktree for the site commands.

Strict decoding rejects unknown tables, unknown keys, invalid TOML, wrong value
types, empty directories, and item metadata. These errors block normal
root-loading commands; Doctor reports them with config context and `--fix`
leaves the file unchanged. Focused Go tests and Smokey workflow 230 cover the
contract, and the README, worktree format, and Doctor help document it.
