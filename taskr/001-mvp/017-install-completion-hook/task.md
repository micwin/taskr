---
title: Install shell completion during local deb install
status: done
created_at: 2026-08-07T00:00:00Z
updated_at: 2026-08-07T00:00:00Z
---

# Description

Extend `scripts/build.sh deb --install-deb` so local dogfooding also enables
Taskr shell completion for the current user when it is not already configured.

# Acceptance

- `scripts/build.sh deb --install-deb` detects the current interactive shell.
- Bash, zsh, and fish are supported for automatic RC-file updates.
- Bash completion is appended to the correct user bash RC file when missing.
- Zsh completion is appended to the correct user zsh RC file when missing.
- Fish completion is installed or sourced through the correct user fish config
  location when missing.
- Completion setup is idempotent and does not duplicate existing Taskr blocks.
- Completion setup runs as the invoking user, not through `sudo`.
- Unsupported shells are reported clearly and do not fail package installation.
- Powershell completion remains manual/documented unless a Linux user config
  target is explicitly defined later.
- Smokey coverage verifies RC-file detection and idempotent completion setup
  without invoking `sudo`.

# Comments

- 2026-08-07: Cobra currently exposes `completion bash`, `completion zsh`,
  `completion fish`, and `completion powershell`.
- 2026-08-07: The installation path itself requires `sudo`, but shell RC
  mutation must be tested separately with Smokey-managed `$HOME` and `$SHELL`.

# Outcome

Implemented user-level shell completion setup in `scripts/build.sh`.

Behavior:

- `scripts/build.sh install-completion` installs completion for the current
  user without `sudo`.
- `scripts/build.sh deb --install-deb` and `scripts/build.sh all --install-deb`
  install the package with `sudo apt install ./dist/<package>.deb`, then run
  completion setup as the invoking user.
- Bash writes an idempotent Taskr block to `~/.bashrc`, or `~/.bash_profile`
  when that exists and `~/.bashrc` does not.
- Zsh writes an idempotent Taskr block to `${ZDOTDIR:-$HOME}/.zshrc`.
- Fish writes an idempotent Taskr block to
  `${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/taskr.fish`.
- Unsupported shells print `completion unsupported shell=<name>` and do not
  fail the build/install flow.
- Powershell remains manual because no Linux user RC target is defined yet.

Pre-close checks:

- `bash -n scripts/build.sh` passes.
- `go test ./...` passes.
- `taskr --help` renders successfully.
- `taskr completion bash` renders successfully through Cobra's completion
  command.
- `smokey --tests-dir tests.d` passes (`12/12`) with final teardown executed.
- No public API exists yet.
