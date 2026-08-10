#!/usr/bin/env bash
set -euo pipefail

trap 'echo "priority workflow failed at line ${LINENO}" >&2' ERR

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

# Add a second high-priority task for stable ordering and selector ambiguity.
run_taskr priority_create_ambiguous "${root}" create task "Workflow priority" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
second_high_marker="${root}/001-mvp/006-workflow-priority/task.md"
add_frontmatter_field "${second_high_marker}" "priority: high"

# Default task lists should sort by priority and show only non-normal values.
run_taskr priority_list_default "${root}" list --type task
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^006 task open priority=high Workflow priority$' "${stdout}"
grep -q '^003 task active Define workflows$' "${stdout}"
grep -q '^005 task active priority=low Open work$' "${stdout}"
default_ids="$(awk '{print $1}' "${stdout}" | paste -sd ' ' -)"
[ "${default_ids}" = "006 003 005" ]

# Display flags should force all effective values or suppress all priority text.
run_taskr priority_list_show "${root}" list --type task --show-priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 task active priority=normal Define workflows$' "${stdout}"
grep -q '^005 task active priority=low Open work$' "${stdout}"

run_taskr priority_list_hide "${root}" list --type task --hide-priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
if grep -q 'priority=' "${stdout}"; then
  echo "list --hide-priority should suppress all priority values" >&2
  exit 1
fi

# Effective priority filters should include omitted normal and task items only.
run_taskr priority_list_filter_high "${root}" list --priority high
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^006 task open priority=high Workflow priority$' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]

run_taskr priority_list_filter_normal "${root}" list --priority normal
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 task active Define workflows$' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]

run_taskr priority_list_filter_low "${root}" list --priority low
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^005 task active priority=low Open work$' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]

# Grouping should be task-only and preserve the priority and stable ID order.
run_taskr priority_list_grouped "${root}" list --type task --group-by priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: high$' "${stdout}"
grep -q '^Priority: normal$' "${stdout}"
grep -q '^Priority: low$' "${stdout}"
grep -q '^  006 task open Workflow priority$' "${stdout}"
grep -q '^  003 task active Define workflows$' "${stdout}"
grep -q '^  005 task active Open work$' "${stdout}"
grouped_ids="$(awk '/^  [0-9]/{print $1}' "${stdout}" | paste -sd ' ' -)"
[ "${grouped_ids}" = "006 003 005" ]

run_taskr priority_list_grouped_mixed "${root}" list --group-by priority
[ "${exit_code}" -ne 0 ] || { echo "priority grouping should require --type task" >&2; exit 1; }
grep -qi 'group.*priority.*type task\|type task.*group.*priority' "${stderr}"

run_taskr priority_list_conflicting_display "${root}" list --type task --show-priority --hide-priority
[ "${exit_code}" -ne 0 ] || { echo "priority display flags should be exclusive" >&2; exit 1; }
grep -qi 'show-priority\|hide-priority\|exclusive' "${stderr}"

run_taskr priority_list_invalid_filter "${root}" list --priority urgent
[ "${exit_code}" -ne 0 ] || { echo "list should reject an invalid priority filter" >&2; exit 1; }
grep -qi 'priority.*urgent\|urgent.*priority' "${stderr}"

run_taskr priority_list_help "${root}" list --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--priority' "${stdout}"
grep -q -- '--show-priority' "${stdout}"
grep -q -- '--hide-priority' "${stdout}"
grep -q -- '--group-by' "${stdout}"

run_taskr priority_list_value_completion "${root}" __complete list --priority ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'high' "${stdout}"
grep -qx 'normal' "${stdout}"
grep -qx 'low' "${stdout}"

run_taskr priority_list_group_completion "${root}" __complete list --group-by ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'priority' "${stdout}"

# Tree should sort task siblings and show only non-normal priority by default.
run_taskr priority_tree_default "${root}" tree 001 --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^  002 \[task done priority=high\] Define directory structure$' "${stdout}"
grep -q '^  006 \[task open priority=high\] Workflow priority$' "${stdout}"
grep -q '^  003 \[task active\] Define workflows$' "${stdout}"
grep -q '^  005 \[task active priority=low\] Open work$' "${stdout}"
tree_ids="$(awk '/^  [0-9]/{print $1}' "${stdout}" | paste -sd ' ' -)"
[ "${tree_ids}" = "002 006 003 005" ]

# Force and hide modes should alter priority text without changing ordering.
run_taskr priority_tree_show "${root}" tree 001 --all --show-priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^  003 \[task active priority=normal\] Define workflows$' "${stdout}"

run_taskr priority_tree_hide "${root}" tree 001 --all --hide-priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
if grep -q 'priority=' "${stdout}"; then
  echo "tree --hide-priority should suppress all priority values" >&2
  exit 1
fi
hidden_tree_ids="$(awk '/^  [0-9]/{print $1}' "${stdout}" | paste -sd ' ' -)"
[ "${hidden_tree_ids}" = "002 006 003 005" ]

# Existing layout and visibility flags should preserve their shape and meaning.
run_taskr priority_tree_ascii "${root}" tree 001 --all --ascii
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^+- 002 \[task done priority=high\] Define directory structure$' "${stdout}"
grep -q '^+- 006 \[task open priority=high\] Workflow priority$' "${stdout}"

run_taskr priority_tree_tabs "${root}" tree 001 --all --tabs
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q $'^\t002 \[task done priority=high\] Define directory structure$' "${stdout}"

run_taskr priority_tree_wide "${root}" tree 001 --all --wide
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^    002 \[task done priority=high\] Define directory structure$' "${stdout}"

# Priority display flags should be exclusive and documented.
run_taskr priority_tree_conflicting_display "${root}" tree 001 --show-priority --hide-priority
[ "${exit_code}" -ne 0 ] || { echo "tree priority display flags should be exclusive" >&2; exit 1; }
grep -qi 'show-priority\|hide-priority\|exclusive' "${stderr}"

run_taskr priority_tree_help "${root}" tree --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--show-priority' "${stdout}"
grep -q -- '--hide-priority' "${stdout}"

run_taskr priority_tree_flag_completion "${root}" __complete tree --
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^--show-priority' "${stdout}"
grep -q '^--hide-priority' "${stdout}"

# Report should count effective task priority globally and per milestone.
run_taskr priority_report_mark_developing "${root}" status 003 developing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr priority_report_create_empty "${root}" create milestone "Priority future" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

run_taskr priority_report "${root}" report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^# Task Priority Summary$' "${stdout}"
[ "$(grep -c '^tasks with effective priority "high": 2$' "${stdout}")" -eq 2 ]
[ "$(grep -c '^tasks with effective priority "normal": 1$' "${stdout}")" -eq 2 ]
[ "$(grep -c '^tasks with effective priority "low": 1$' "${stdout}")" -eq 2 ]

global_high_line="$(grep -n -m1 '^tasks with effective priority "high":' "${stdout}" | cut -d: -f1)"
global_normal_line="$(grep -n -m1 '^tasks with effective priority "normal":' "${stdout}" | cut -d: -f1)"
global_low_line="$(grep -n -m1 '^tasks with effective priority "low":' "${stdout}" | cut -d: -f1)"
[ "${global_high_line}" -lt "${global_normal_line}" ]
[ "${global_normal_line}" -lt "${global_low_line}" ]

grep -q '^## MVP (mvp) \[active\]$' "${stdout}"
grep -q '^### Task Priority Counts$' "${stdout}"
grep -q '^# Open Milestones Without Tickets$' "${stdout}"
grep -q '^007 \[open\] Priority future$' "${stdout}"
if grep -q '^## Priority future ' "${stdout}"; then
  echo "empty milestones should not receive a task priority count section" >&2
  exit 1
fi

# Priority reporting must not replace status counts or current-work selection.
grep -q '^tasks with status "developing": 1$' "${stdout}"
grep -q '^tasks with status "active": 1$' "${stdout}"
grep -q '^tasks with status "done": 1$' "${stdout}"
grep -q '^tasks with status "open": 1$' "${stdout}"
grep -q '^003 \[developing\] Define workflows$' "${stdout}"

run_taskr priority_report_help "${root}" report --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'repository.*report\|report.*repository' "${stdout}"
grep -qi 'priority' "${stdout}"

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

run_taskr priority_ambiguous_selector "${root}" priority workflow high
[ "${exit_code}" -ne 0 ] || { echo "priority should reject ambiguous selectors" >&2; exit 1; }
grep -q '^003 Define workflows$' "${stderr}"
grep -q '^006 Workflow priority$' "${stderr}"

# Help, examples, and completion should expose the full command contract.
run_taskr priority_help "${root}" priority --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr priority <selector> <high|normal|low>' "${stdout}"
grep -q 'updated_at' "${stdout}"
grep -qi 'normal.*remov\|remov.*normal' "${stdout}"

run_taskr priority_source_completion "${root}" __complete priority ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'002\ttask done Define directory structure' "${stdout}"
grep -qx $'003\ttask developing Define workflows' "${stdout}"
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
grep -q 'taskr list --type task --priority high' "${stdout}"
grep -q 'taskr list --type task --show-priority' "${stdout}"
grep -q 'taskr list --type task --group-by priority' "${stdout}"
grep -q 'taskr tree 001 --all --show-priority' "${stdout}"
grep -q 'taskr tree 001 --hide-priority' "${stdout}"
grep -q 'taskr report' "${stdout}"

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
