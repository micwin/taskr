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

project="${SMOKEY_STATE_DIR}/discovery-project"
mkdir -p "${project}/.sync-state" "${project}/src"

pushd "${project}" >/dev/null
run_taskr init_default init
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

run_taskr report_default report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Taskr report$" "${stdout}"
grep -q "^Project: taskr$" "${stdout}"

run_taskr doctor_default doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "ok root=${project}/taskr" "${stdout}"
popd >/dev/null
