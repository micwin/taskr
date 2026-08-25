#!/usr/bin/env bash
set -euo pipefail

make_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "mount_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "mount_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  local task_marker="${root}/001-mounted-roadmap/002-mounted-task/task.md"
  sed -i '/^status:/a tags: [external]' "${task_marker}"
  sed -i '/# Acceptance/i DescriptionOnly ExternalNeedle appears here.\n' "${task_marker}"
  printf '%s\n' "${root}"
}

create_mount_list_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  root="$(new_root "${name}")"
  vendor_target="$(make_mount_target "${name}-vendor-target")"
  archive_target="$(make_mount_target "${name}-archive-target")"
  lib_target="$(make_mount_target "${name}-lib-target")"
  cat >"${vendor_target}/taskr.toml" <<EOF
[[mounts]]
id = "lib"
name = "Library Project"
path = "${lib_target}"
mode = "read-only"
EOF
  cat >"${root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${vendor_target}"
mode = "read-only"

[[mounts]]
id = "archive"
name = "Archive Project"
path = "${archive_target}"
mode = "read-write"
EOF
  printf '%s\n' "${root}"
}

# Ticket 111: list --type mount renders virtual mounts with mode, not status.
root="$(create_mount_list_fixture mount-list-objects)"
run_taskr mount_list_objects "${root}" list --type mount
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'vendor mount read-only Vendor Project' "${stdout}"
grep -qx 'vendor:lib mount read-only Library Project' "${stdout}"
grep -qx 'archive mount read-write Archive Project' "${stdout}"
if grep -Eq 'vendor mount (open|designing|developing|active|reviewing|blocked|done|cancelled)' "${stdout}"; then
  echo "mount rows should show mode instead of Taskr lifecycle status" >&2
  exit 1
fi

# Ticket 111: default list includes root-level mount objects with their modes.
run_taskr mount_list_default "${root}" list
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'vendor mount read-only Vendor Project' "${stdout}"
grep -qx 'vendor:lib mount read-only Library Project' "${stdout}"
grep -qx 'archive mount read-write Archive Project' "${stdout}"
grep -q '^001 milestone active #(public,website) MVP$' "${stdout}"

# Ticket 111: mounted items use prefixed IDs and do not collide with local IDs.
run_taskr mount_list_all_items "${root}" list --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx '001 milestone active #(public,website) MVP' "${stdout}"
grep -qx 'vendor:001 milestone open Mounted Roadmap' "${stdout}"
grep -qx 'vendor:002 task open #external Mounted Task' "${stdout}"
grep -qx 'vendor:lib:001 milestone open Mounted Roadmap' "${stdout}"
grep -qx 'archive:001 milestone open Mounted Roadmap' "${stdout}"

# Ticket 111: existing list filters compose with mounted item selectors.
run_taskr mount_list_under "${root}" list --under vendor:001 --type task
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'vendor:002 task open #external Mounted Task' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]

# Ticket 111: full-text glob matching includes mounted marker text.
run_taskr mount_list_glob "${root}" list --glob ExternalNeedle
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'vendor:002 task open #external Mounted Task' "${stdout}"
grep -qx 'archive:002 task open #external Mounted Task' "${stdout}"

# Ticket 111: tag filtering includes mounted marker tags case-insensitively.
run_taskr mount_list_tags "${root}" list --tags EXTERNAL
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'vendor:002 task open #external Mounted Task' "${stdout}"
grep -qx 'archive:002 task open #external Mounted Task' "${stdout}"

# Ticket 111: unavailable mounts fail clearly instead of being silently skipped.
bad_root="$(new_root mount-list-unavailable)"
cat >"${bad_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-mounted-root"
mode = "read-only"
EOF
run_taskr mount_list_unavailable "${bad_root}" list --type mount
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail list" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

# Ticket 111: help and completion expose the mount list surface.
run_taskr mount_list_help "${root}" list --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'mount' "${stdout}"
grep -qi 'mode\|read-only\|read-write' "${stdout}"
run_taskr mount_list_type_completion "${root}" __complete list --type ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'mount\titem type' "${stdout}"
run_taskr mount_list_under_completion "${root}" __complete list --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^vendor:001' "${stdout}"
grep -q '^vendor:lib:001' "${stdout}"
