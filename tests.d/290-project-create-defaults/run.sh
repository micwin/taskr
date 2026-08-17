#!/usr/bin/env bash
set -euo pipefail


assert_marker_status() {
  local root="$1"
  local slug="$2"
  local marker_name="$3"
  local status="$4"
  local marker
  marker="$(find "${root}" -path "*-${slug}/${marker_name}" -print -quit)"
  [ -n "${marker}" ]
  grep -qx "status: ${status}" "${marker}"
  grep -Eq "^${status}_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" "${marker}"
}

# Without project defaults, create retains its built-in open fallback.
root="$(new_root project-default-absent -root)"
run_taskr project_default_absent "${root}" create task "Absent project default" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_marker_status "${root}" absent-project-default task.md open

# One common create_status applies to every item type.
root="$(new_root project-default-common -root)"
cat >"${root}/taskr.toml" <<'EOF'
[defaults]
create_status = "designing"
EOF
run_taskr project_default_common_milestone "${root}" create milestone "Common milestone" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr project_default_common_task "${root}" create task "Common task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr project_default_common_subtask "${root}" create subtask "Common subtask" --under 003 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_marker_status "${root}" common-milestone milestone.md designing
assert_marker_status "${root}" common-task task.md designing
assert_marker_status "${root}" common-subtask subtask.md designing

# Type-specific defaults override the common value independently.
root="$(new_root project-default-specific -root)"
cat >"${root}/taskr.toml" <<'EOF'
[defaults]
create_status = "designing"
milestone_status = "blocked"
task_status = "developing"
subtask_status = "reviewing"
EOF
run_taskr project_default_specific_milestone "${root}" create milestone "Specific milestone" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr project_default_specific_task "${root}" create task "Specific task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr project_default_specific_subtask "${root}" create subtask "Specific subtask" --under 003 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_marker_status "${root}" specific-milestone milestone.md blocked
assert_marker_status "${root}" specific-task task.md developing
assert_marker_status "${root}" specific-subtask subtask.md reviewing

# A missing type override falls back to the common default.
root="$(new_root project-default-partial -root)"
cat >"${root}/taskr.toml" <<'EOF'
[defaults]
create_status = "active"
task_status = "blocked"
EOF
run_taskr project_default_partial_milestone "${root}" create milestone "Partial milestone" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr project_default_partial_task "${root}" create task "Partial task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_marker_status "${root}" partial-milestone milestone.md active
assert_marker_status "${root}" partial-task task.md blocked

# Explicit CLI status has highest precedence over every project default.
run_taskr project_default_cli_override "${root}" create task "Explicit override" --under 001 --status reviewing --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_marker_status "${root}" explicit-override task.md reviewing

# Doctor and normal root loading reject invalid or closed configured defaults.
for value in done cancelled unknown; do
  root="$(new_root "project-default-invalid-${value}" -root)"
  printf '[defaults]\ncreate_status = "%s"\n' "${value}" >"${root}/taskr.toml"
  run_taskr "project_default_doctor_${value}" "${root}" doctor
  [ "${exit_code}" -eq 2 ] || { echo "Doctor should reject default ${value}" >&2; exit 1; }
  grep -qi 'default\|create_status\|status' "${stderr}"
  before="$(find "${root}" -type d | sort | sha256sum)"
  run_taskr "project_default_create_${value}" "${root}" create task "Invalid default ${value}" --under 001 --no-edit
  [ "${exit_code}" -eq 2 ] || { echo "create should reject default ${value}" >&2; exit 1; }
  [ "${before}" = "$(find "${root}" -type d | sort | sha256sum)" ]
done

# Unknown defaults remain strict configuration errors rather than ignored typos.
root="$(new_root project-default-unknown-key -root)"
cat >"${root}/taskr.toml" <<'EOF'
[defaults]
create_stats = "designing"
EOF
run_taskr project_default_unknown_key "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "unknown defaults key should exit 2" >&2; exit 1; }
grep -qi 'unknown.*create_stats\|create_stats.*unknown' "${stderr}"

# Create help documents project-default precedence and the built-in fallback.
run_taskr project_default_help create --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'taskr.toml\|project default' "${stdout}"
grep -qi 'type.*default\|default.*type' "${stdout}"
grep -qi 'default.*open\|open.*default' "${stdout}"
