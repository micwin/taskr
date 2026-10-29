#!/usr/bin/env bash
set -euo pipefail


# Tickets 016 and 127: discover the initialized child despite project directories.
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

# Ticket 127: a project file container must not overshadow the actual child root.
mkdir -p "${project}/files" "${project}/.crush"
cp "${TASKR_BASE_ROOT}/files/files.md" "${project}/files/files.md"
run_taskr report_project_files report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'Project: taskr' "${stdout}"
run_taskr doctor_project_files doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "ok root=${project}/taskr" "${stdout}"

# Ticket 127: explicit invalid roots still fail instead of selecting their child.
run_taskr discovery_explicit_invalid . doctor
[ "${exit_code}" -eq 2 ] || { echo "explicit invalid project root should fail" >&2; exit 1; }
grep -q 'missing marker file' "${stderr}"

# Ticket 127: rootless completion discovers the same child as normal commands.
run_taskr discovery_create_milestone create milestone "Discovered Work" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr discovery_completion __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx $'001\tmilestone open Discovered Work' "${stdout}"
popd >/dev/null

# Ticket 127: a direct valid worktree remains discoverable without a taskr child.
direct_root="$(new_root discovery-direct-root)"
pushd "${direct_root}" >/dev/null
run_taskr discovery_direct doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "ok root=${direct_root}" "${stdout}"
popd >/dev/null
