#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

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

add_frontmatter_field() {
  local marker="$1"
  local field="$2"
  sed -i "/^status:/a ${field}" "${marker}"
}

# Valid task priorities and an omitted priority should load successfully.
root="${SMOKEY_STATE_DIR}/priority-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
add_frontmatter_field "${root}/001-mvp/002-verzeichnisstruktur/task.md" "priority: high"
add_frontmatter_field "${root}/001-mvp/005-open-work/task.md" "priority: low"

run_taskr priority_doctor_valid "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Metadata output should expose effective priority, including omitted-as-normal.
run_taskr priority_show_high "${root}" show 002 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: high$' "${stdout}"

run_taskr priority_show_low "${root}" show 005 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: low$' "${stdout}"

run_taskr priority_show_default "${root}" show 003 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: normal$' "${stdout}"

# Unknown values and non-canonical spelling should fail validation.
invalid_value_root="${SMOKEY_STATE_DIR}/priority-invalid-value-root"
cp -R "${TASKR_BASE_ROOT}" "${invalid_value_root}"
add_frontmatter_field "${invalid_value_root}/001-mvp/002-verzeichnisstruktur/task.md" "priority: urgent"
run_taskr priority_doctor_invalid_value "${invalid_value_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject an unknown task priority" >&2; exit 1; }
grep -qi 'priority.*urgent\|urgent.*priority' "${stderr}"

invalid_case_root="${SMOKEY_STATE_DIR}/priority-invalid-case-root"
cp -R "${TASKR_BASE_ROOT}" "${invalid_case_root}"
add_frontmatter_field "${invalid_case_root}/001-mvp/002-verzeichnisstruktur/task.md" "priority: HIGH"
run_taskr priority_doctor_invalid_case "${invalid_case_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject non-canonical priority case" >&2; exit 1; }
grep -qi 'priority.*HIGH\|HIGH.*priority' "${stderr}"

# Normal is represented by omission and should not be stored redundantly.
redundant_normal_root="${SMOKEY_STATE_DIR}/priority-redundant-normal-root"
cp -R "${TASKR_BASE_ROOT}" "${redundant_normal_root}"
add_frontmatter_field "${redundant_normal_root}/001-mvp/002-verzeichnisstruktur/task.md" "priority: normal"
run_taskr priority_doctor_redundant_normal "${redundant_normal_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject redundant normal priority metadata" >&2; exit 1; }
grep -qi 'priority.*normal\|normal.*priority' "${stderr}"

# Priority metadata belongs to tasks only.
milestone_priority_root="${SMOKEY_STATE_DIR}/priority-milestone-root"
cp -R "${TASKR_BASE_ROOT}" "${milestone_priority_root}"
add_frontmatter_field "${milestone_priority_root}/001-mvp/milestone.md" "priority: high"
run_taskr priority_doctor_milestone "${milestone_priority_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject milestone priority" >&2; exit 1; }
grep -qi 'priority.*milestone\|milestone.*priority' "${stderr}"

subtask_priority_root="${SMOKEY_STATE_DIR}/priority-subtask-root"
cp -R "${TASKR_BASE_ROOT}" "${subtask_priority_root}"
add_frontmatter_field "${subtask_priority_root}/001-mvp/003-workflows-definieren/004-define-selectors/subtask.md" "priority: low"
run_taskr priority_doctor_subtask "${subtask_priority_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject subtask priority" >&2; exit 1; }
grep -qi 'priority.*subtask\|subtask.*priority' "${stderr}"
