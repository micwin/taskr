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

# Doctor help should advertise fix mode without making it the default.
run_taskr doctor_help doctor --help
if [ "${exit_code}" -ne 0 ]; then
  echo "doctor help should succeed" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q -- "--fix" "${stdout}"
grep -qi "repair" "${stdout}"
grep -qi "duplicate" "${stdout}"
grep -qi "loadable\\|valid\\|unsupported" "${stdout}"

# Duplicate IDs are fixable, but plain doctor must remain read-only.
duplicate_root="${SMOKEY_STATE_DIR}/doctor-duplicate-root"
cp -R "${TASKR_BASE_ROOT}" "${duplicate_root}"
mkdir -p "${duplicate_root}/005-conflicting-milestone"
cp "${duplicate_root}/001-mvp/milestone.md" "${duplicate_root}/005-conflicting-milestone/milestone.md"
run_taskr doctor_readonly "${duplicate_root}" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "plain doctor should fail before fix" >&2
  exit 1
fi
grep -qi "duplicate id 005" "${stderr}"
[ -d "${duplicate_root}/005-conflicting-milestone" ] || {
  echo "plain doctor must not rename duplicate directories" >&2
  exit 1
}

# Fix mode should rename later duplicate IDs to the next free root-wide ID.
run_taskr doctor_fix "${duplicate_root}" doctor --fix
if [ "${exit_code}" -ne 0 ]; then
  echo "doctor --fix should repair duplicate ids" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q "fixed" "${stdout}"
grep -q "005-conflicting-milestone" "${stdout}"
grep -q "006-conflicting-milestone" "${stdout}"
[ ! -d "${duplicate_root}/005-conflicting-milestone" ]
[ -d "${duplicate_root}/006-conflicting-milestone" ]
run_taskr doctor_after_fix "${duplicate_root}" doctor
if [ "${exit_code}" -ne 0 ]; then
  echo "doctor should pass after fix" >&2
  cat "${stderr}" >&2
  exit 1
fi

# System temp failures are environment problems and should not mutate the root.
temp_error_root="${SMOKEY_STATE_DIR}/doctor-temp-error-root"
cp -R "${TASKR_BASE_ROOT}" "${temp_error_root}"
mkdir -p "${temp_error_root}/005-conflicting-milestone"
cp "${temp_error_root}/001-mvp/milestone.md" "${temp_error_root}/005-conflicting-milestone/milestone.md"
TMPDIR="${SMOKEY_STATE_DIR}/missing-temp-dir" run_taskr doctor_fix_temp_error "${temp_error_root}" doctor --fix
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor --fix should fail when system temp is unavailable" >&2
  exit 1
fi
grep -qi "temporary\\|temp\\|no such" "${stderr}"
[ -d "${temp_error_root}/005-conflicting-milestone" ]
[ ! -d "${temp_error_root}/006-conflicting-milestone" ]

# Fix mode should not partially fix duplicate IDs when unsupported errors remain.
mixed_root="${SMOKEY_STATE_DIR}/doctor-mixed-root"
cp -R "${TASKR_BASE_ROOT}" "${mixed_root}"
mkdir -p "${mixed_root}/005-conflicting-milestone"
cp "${mixed_root}/001-mvp/milestone.md" "${mixed_root}/005-conflicting-milestone/milestone.md"
mkdir -p "${mixed_root}/001-mvp/broken-child"
run_taskr doctor_fix_mixed "${mixed_root}" doctor --fix
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor --fix should reject mixed supported and unsupported errors" >&2
  exit 1
fi
grep -qi "unsupported\\|missing marker\\|not fixable" "${stderr}"
[ -d "${mixed_root}/005-conflicting-milestone" ]
[ ! -d "${mixed_root}/006-conflicting-milestone" ]
