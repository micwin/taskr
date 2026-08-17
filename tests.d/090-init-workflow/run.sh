#!/usr/bin/env bash
set -euo pipefail


run_taskr() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "${TASKR_BIN}" "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

# Default init should create ./taskr below the current project directory.
project="${SMOKEY_STATE_DIR}/init-project"
mkdir -p "${project}/src"
pushd "${project}" >/dev/null
run_taskr init_default init
popd >/dev/null
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "initialized root=" "${stdout}"
grep -q "created=true" "${stdout}"
test -f "${project}/taskr/files/files.md"

run_taskr doctor_default "${project}/taskr" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "ok root=" "${stdout}"

# Explicit init should target the selected worktree directory.
explicit="${SMOKEY_STATE_DIR}/explicit-taskr"
run_taskr init_explicit "${explicit}" init
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "initialized root=${explicit}" "${stdout}"
grep -q "created=true" "${stdout}"
test -f "${explicit}/files/files.md"

# Re-running init on a valid root should be idempotent.
run_taskr init_again "${explicit}" init
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created=false" "${stdout}"

run_taskr doctor_explicit "${explicit}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "files=1" "${stdout}"
