#!/usr/bin/env bash
set -euo pipefail

run_build() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

home="${SMOKEY_STATE_DIR}/completion-home"
mkdir -p "${home}"

# Bash appends one idempotent block to ~/.bashrc.
HOME="${home}/bash" SHELL=/bin/bash run_build bash_first ./scripts/build.sh install-completion
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "completion configured shell=bash" "${stdout}"
grep -q "taskr completion bash" "${home}/bash/.bashrc"

HOME="${home}/bash" SHELL=/bin/bash run_build bash_second ./scripts/build.sh install-completion
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "completion already configured shell=bash" "${stdout}"
[ "$(grep -c "taskr completion bash" "${home}/bash/.bashrc")" -eq 1 ]

# Zsh respects ZDOTDIR.
HOME="${home}/zsh-home" ZDOTDIR="${home}/zsh-dot" SHELL=/usr/bin/zsh run_build zsh_first ./scripts/build.sh install-completion
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "completion configured shell=zsh" "${stdout}"
grep -q "taskr completion zsh" "${home}/zsh-dot/.zshrc"

# Fish writes a conf.d file below XDG_CONFIG_HOME.
HOME="${home}/fish-home" XDG_CONFIG_HOME="${home}/fish-config" SHELL=/usr/bin/fish run_build fish_first ./scripts/build.sh install-completion
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "completion configured shell=fish" "${stdout}"
grep -q "taskr completion fish | source" "${home}/fish-config/fish/conf.d/taskr.fish"

# Unsupported shells report clearly and do not fail.
HOME="${home}/other-home" SHELL=/bin/sh run_build unsupported ./scripts/build.sh install-completion
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "completion unsupported shell=sh" "${stdout}"
