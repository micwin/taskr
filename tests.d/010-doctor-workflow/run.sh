#!/usr/bin/env bash
set -euo pipefail


# Run a command and capture its outputs for assertions.
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

# Valid roots should pass doctor with a deterministic summary.
root="${SMOKEY_STATE_DIR}/doctor-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
run_taskr doctor_valid "${root}" doctor
if [ "${exit_code}" -ne 0 ]; then
  echo "doctor should pass for valid root" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q "ok root=" "${stdout}"
grep -q "items=" "${stdout}"
grep -q "files=" "${stdout}"

# Missing roots should fail clearly.
run_taskr doctor_missing "${SMOKEY_STATE_DIR}/missing-root" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor should fail for missing root" >&2
  exit 1
fi
grep -qi "not found\\|missing\\|no such" "${stderr}"

# Invalid marker structure should fail with the invalid path.
run_taskr doctor_invalid "${TASKR_INVALID_ROOT}" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor should fail for invalid marker structure" >&2
  exit 1
fi
grep -q "001-broken" "${stderr}"
