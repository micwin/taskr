#!/usr/bin/env bash
set -euo pipefail

make_show_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "show_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "show_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  local task_marker="${root}/001-mounted-roadmap/002-mounted-task/task.md"
  sed -i '/# Acceptance/i Mounted show body from '"${name}"'.\n' "${task_marker}"
  printf '%s\n' "${root}"
}

create_mount_show_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  root="$(new_root "${name}")"
  run_taskr "show_local_${name}" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  vendor_target="$(make_show_mount_target "${name}-vendor-target")"
  archive_target="$(make_show_mount_target "${name}-archive-target")"
  lib_target="$(make_show_mount_target "${name}-lib-target")"
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

root="$(create_mount_show_fixture mount-show-root)"

# Ticket 112: show displays virtual mount object metadata.
run_taskr mount_show_object "${root}" show vendor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'ID: vendor' "${stdout}"
grep -qx 'Type: mount' "${stdout}"
grep -qx 'Name: Vendor Project' "${stdout}"
grep -qx 'Mode: read-only' "${stdout}"
grep -qx 'Path: '"$(awk -F'"' '/id = "vendor"/ { seen=1 } seen && /path = / { print $2; exit }' "${root}/taskr.toml")" "${stdout}"
if grep -q '^Status:' "${stdout}"; then
  echo "mount object show should not render a lifecycle status" >&2
  exit 1
fi

# Ticket 112: show displays transitive mount objects by qualified mount ID.
run_taskr mount_show_transitive_object "${root}" show vendor:lib
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'ID: vendor:lib' "${stdout}"
grep -qx 'Type: mount' "${stdout}"
grep -qx 'Name: Library Project' "${stdout}"
grep -qx 'Mode: read-only' "${stdout}"

# Ticket 112: show displays mounted items with prefixed identity and source metadata.
run_taskr mount_show_item "${root}" show vendor:002
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'ID: vendor:002' "${stdout}"
grep -qx 'Type: task' "${stdout}"
grep -qx 'Title: Mounted Task' "${stdout}"
grep -qx 'Status: open' "${stdout}"
grep -qx 'Source: vendor (Vendor Project)' "${stdout}"
grep -q 'Mounted show body from mount-show-root-vendor-target' "${stdout}"

# Ticket 112: show displays transitive mounted items with full source identity.
run_taskr mount_show_transitive_item "${root}" show vendor:lib:002
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'ID: vendor:lib:002' "${stdout}"
grep -qx 'Source: vendor:lib (Library Project)' "${stdout}"
grep -qx 'Title: Mounted Task' "${stdout}"

# Ticket 112: local selectors keep current behavior.
run_taskr mount_show_local "${root}" show 006
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'ID: 006' "${stdout}"
grep -qx 'Title: Mounted Task' "${stdout}"
if grep -q '^Source:' "${stdout}"; then
  echo "local show output should not gain mount source metadata" >&2
  exit 1
fi

# Ticket 112: ambiguous unprefixed selectors include enough source identity.
run_taskr mount_show_ambiguous "${root}" show "Mounted Task"
[ "${exit_code}" -ne 0 ] || { echo "unprefixed mounted/local ambiguity should fail" >&2; exit 1; }
grep -qi 'ambiguous\|candidates' "${stderr}"
grep -q '006 Mounted Task' "${stderr}"
grep -q 'vendor:002 Mounted Task' "${stderr}"
grep -q 'archive:002 Mounted Task' "${stderr}"
grep -q 'vendor:lib:002 Mounted Task' "${stderr}"

# Ticket 112: missing mounted selectors fail clearly.
run_taskr mount_show_missing_item "${root}" show vendor:999
[ "${exit_code}" -ne 0 ] || { echo "missing mounted selector should fail" >&2; exit 1; }
grep -qi 'vendor\|999\|not found\|no match' "${stderr}"
run_taskr mount_show_missing_mount "${root}" show missing:001
[ "${exit_code}" -ne 0 ] || { echo "missing mount selector should fail" >&2; exit 1; }
grep -qi 'missing\|mount\|not found\|no match' "${stderr}"

# Ticket 112: read-only mounted items are display-only and do not require mutation.
before="$(sha256sum "$(awk -F'"' '/id = "vendor"/ { seen=1 } seen && /path = / { print $2; exit }' "${root}/taskr.toml")/001-mounted-roadmap/002-mounted-task/task.md")"
run_taskr mount_show_read_only "${root}" show vendor:002 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
after="$(sha256sum "$(awk -F'"' '/id = "vendor"/ { seen=1 } seen && /path = / { print $2; exit }' "${root}/taskr.toml")/001-mounted-roadmap/002-mounted-task/task.md")"
[ "${before}" = "${after}" ] || { echo "show should not mutate read-only mounted items" >&2; exit 1; }

# Ticket 112: help and completion expose mounted show selectors.
run_taskr mount_show_help "${root}" show --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
run_taskr mount_show_completion "${root}" __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^vendor\tmount' "${stdout}"
grep -q '^vendor:002' "${stdout}"
grep -q '^vendor:lib\tmount' "${stdout}"
grep -q '^vendor:lib:002' "${stdout}"
