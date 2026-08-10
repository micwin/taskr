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

assert_updated_at_changed() {
  local marker="$1"
  local updated_at
  updated_at="$(sed -n 's/^updated_at: //p' "${marker}")"
  [[ "${updated_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
  [ "${updated_at}" != "2020-01-01T00:00:00Z" ]
}

# Valid task priorities and an omitted priority should load successfully.
root="${SMOKEY_STATE_DIR}/priority-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
add_frontmatter_field "${root}/001-mvp/002-verzeichnisstruktur/task.md" "priority: high"
add_frontmatter_field "${root}/001-mvp/005-open-work/task.md" "priority: low"

run_taskr priority_doctor_valid "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Full show output should always expose stored high and low priorities.
run_taskr priority_show_full_high "${root}" show 002
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: high$' "${stdout}"

run_taskr priority_show_full_low "${root}" show 005
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: low$' "${stdout}"

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

# The priority command should set high and low while updating marker time.
command_marker="${root}/001-mvp/003-workflows-definieren/task.md"
sed -i 's/^updated_at: .*/updated_at: 2020-01-01T00:00:00Z/' "${command_marker}"
run_taskr priority_set_high "${root}" priority 003 high
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'priority id=003 old=normal new=high changed=true stored=true' "${stdout}"
grep -q '^priority: high$' "${command_marker}"
assert_updated_at_changed "${command_marker}"

sed -i 's/^updated_at: .*/updated_at: 2020-01-01T00:00:00Z/' "${command_marker}"
run_taskr priority_set_low "${root}" priority 003 low
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'priority id=003 old=high new=low changed=true stored=true' "${stdout}"
grep -q '^priority: low$' "${command_marker}"
assert_updated_at_changed "${command_marker}"

# Resetting to normal should remove storage but retain the effective default.
sed -i 's/^updated_at: .*/updated_at: 2020-01-01T00:00:00Z/' "${command_marker}"
run_taskr priority_reset_normal "${root}" priority 003 normal
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'priority id=003 old=low new=normal changed=true stored=false' "${stdout}"
if grep -q '^priority:' "${command_marker}"; then
  echo "normal priority should be represented by an omitted field" >&2
  exit 1
fi
assert_updated_at_changed "${command_marker}"

# Repeating normal should report a no-op and leave the marker byte-identical.
marker_before_noop="$(sha256sum "${command_marker}")"
run_taskr priority_normal_noop "${root}" priority 003 normal
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'priority id=003 old=normal new=normal changed=false stored=false' "${stdout}"
[ "$(sha256sum "${command_marker}")" = "${marker_before_noop}" ]

# Mutation accepts task selectors only and follows shared selector diagnostics.
run_taskr priority_milestone_rejected "${root}" priority 001 high
[ "${exit_code}" -ne 0 ] || { echo "priority should reject milestone targets" >&2; exit 1; }
grep -qi 'priority.*task\|task.*priority' "${stderr}"

run_taskr priority_subtask_rejected "${root}" priority 004 high
[ "${exit_code}" -ne 0 ] || { echo "priority should reject subtask targets" >&2; exit 1; }
grep -qi 'priority.*task\|task.*priority' "${stderr}"

marker_before_invalid_priority="$(sha256sum "${command_marker}")"
run_taskr priority_invalid_value "${root}" priority 003 urgent
[ "${exit_code}" -ne 0 ] || { echo "priority should reject unknown values" >&2; exit 1; }
grep -qi 'priority.*urgent\|urgent.*priority' "${stderr}"

run_taskr priority_invalid_case_value "${root}" priority 003 HIGH
[ "${exit_code}" -ne 0 ] || { echo "priority should reject non-canonical case" >&2; exit 1; }
grep -qi 'priority.*HIGH\|HIGH.*priority' "${stderr}"

run_taskr priority_invalid_numeric_value "${root}" priority 003 1
[ "${exit_code}" -ne 0 ] || { echo "priority should reject numeric values" >&2; exit 1; }
grep -qi 'priority.*1\|1.*priority' "${stderr}"

run_taskr priority_missing_value "${root}" priority 003
[ "${exit_code}" -ne 0 ] || { echo "priority should require a value" >&2; exit 1; }
grep -qi 'arg\|priority\|requires' "${stderr}"

[ "$(sha256sum "${command_marker}")" = "${marker_before_invalid_priority}" ]

run_taskr priority_missing_selector "${root}" priority missing high
[ "${exit_code}" -ne 0 ] || { echo "priority should reject missing selectors" >&2; exit 1; }
grep -qi 'not found\|no match' "${stderr}"

run_taskr priority_create_ambiguous "${root}" create task "Workflow priority" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr priority_ambiguous_selector "${root}" priority workflow high
[ "${exit_code}" -ne 0 ] || { echo "priority should reject ambiguous selectors" >&2; exit 1; }
grep -q '^003 Define workflows$' "${stderr}"
grep -q '^006 Workflow priority$' "${stderr}"

# Help, examples, and completion should expose the full command contract.
run_taskr priority_help "${root}" priority --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr priority <selector> <high|normal|low>' "${stdout}"
grep -q 'updated_at' "${stdout}"
grep -q 'normal.*remov\|remov.*normal' "${stdout}"

run_taskr priority_source_completion "${root}" __complete priority ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'002\ttask done Define directory structure' "${stdout}"
grep -qx $'003\ttask active Define workflows' "${stdout}"
if grep -q $'^001\t\|^004\t' "${stdout}"; then
  echo "priority source completion should offer tasks only" >&2
  exit 1
fi

run_taskr priority_value_completion "${root}" __complete priority 003 ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'high' "${stdout}"
grep -qx 'normal' "${stdout}"
grep -qx 'low' "${stdout}"

run_taskr priority_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr priority 002 high' "${stdout}"
grep -q 'taskr priority 002 normal' "${stdout}"

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
