#!/usr/bin/env bash
set -euo pipefail

mount_path() {
  local config="$1"
  local id="$2"
  awk -F'"' -v id="${id}" '/id = / { seen=($2 == id) } seen && /path = / { print $2; exit }' "${config}"
}

marker_field() {
  local marker="$1"
  local field="$2"
  sed -n "s/^${field}: //p" "${marker}"
}

assert_status_timestamp() {
  local marker="$1"
  local field="$2"
  local transition_at
  local updated_at
  transition_at="$(marker_field "${marker}" "${field}")"
  updated_at="$(marker_field "${marker}" updated_at)"
  if ! [[ "${transition_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo "missing or invalid ${field} in ${marker}: ${transition_at:-<missing>}" >&2
    return 1
  fi
  if [ "${updated_at}" != "${transition_at}" ]; then
    echo "updated_at does not match ${field} in ${marker}: ${updated_at} != ${transition_at}" >&2
    return 1
  fi
}

hash_root_markers() {
  local root="$1"
  find "${root}" -name '*.md' -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum
}

make_status_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "status_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "status_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "status_target_${name}_child" "${root}" create subtask "Mounted Child" --under 002 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_status_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  local writable_child_target
  root="$(new_root "${name}")"
  vendor_target="$(make_status_mount_target "${name}-vendor-target")"
  archive_target="$(make_status_mount_target "${name}-archive-target")"
  lib_target="$(make_status_mount_target "${name}-lib-target")"
  writable_child_target="$(make_status_mount_target "${name}-writable-child-target")"
  cat >"${vendor_target}/taskr.toml" <<EOF
[[mounts]]
id = "lib"
name = "Library Project"
path = "${lib_target}"
mode = "read-write"
EOF
  cat >"${archive_target}/taskr.toml" <<EOF
[[mounts]]
id = "child"
name = "Writable Child"
path = "${writable_child_target}"
mode = "read-write"
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

root="$(create_mount_status_fixture mount-status-root)"
vendor_root="$(mount_path "${root}/taskr.toml" vendor)"
archive_root="$(mount_path "${root}/taskr.toml" archive)"
archive_child_root="$(mount_path "${archive_root}/taskr.toml" child)"

archive_child_marker="${archive_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"

# Ticket 114: parent/child consistency remains enforced inside mounted roots.
run_taskr mount_status_parent_blocked "${root}" status archive:002 done
[ "${exit_code}" -ne 0 ] || { echo "mounted parent should not close before child" >&2; exit 1; }
grep -q 'archive:003' "${stderr}"
run_taskr mount_status_child_reviewing "${root}" status archive:003 reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${archive_child_marker}" reviewing_at
run_taskr mount_status_parent_still_blocked "${root}" status archive:002 done
[ "${exit_code}" -ne 0 ] || { echo "mounted parent should remain blocked by reviewing child" >&2; exit 1; }
grep -q 'archive:003' "${stderr}"

# Ticket 114: status routes successful writes to read-write mounted roots.
parent_before="$(hash_root_markers "${root}")"
archive_before="$(hash_root_markers "${archive_root}")"
run_taskr mount_status_read_write "${root}" status archive:003 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'status id=archive:003' "${stdout}"
grep -q 'old=reviewing' "${stdout}"
grep -q 'new=done' "${stdout}"
grep -qx 'status: done' "${archive_child_marker}"
assert_status_timestamp "${archive_child_marker}" done_at
[ "${parent_before}" = "$(hash_root_markers "${root}")" ] || { echo "parent root should not receive shadow marker changes" >&2; exit 1; }
[ "${archive_before}" != "$(hash_root_markers "${archive_root}")" ] || { echo "read-write mounted root should receive marker change" >&2; exit 1; }
test ! -e "${root}/archive"
run_taskr mount_status_parent_done "${root}" status archive:002 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'status: done' "${archive_root}/001-mounted-roadmap/002-mounted-task/task.md"
assert_status_timestamp "${archive_root}/001-mounted-roadmap/002-mounted-task/task.md" done_at

# Ticket 114: read-only mounts reject status writes without modifying any root.
parent_before="$(hash_root_markers "${root}")"
vendor_before="$(hash_root_markers "${vendor_root}")"
run_taskr mount_status_read_only "${root}" status vendor:003 done
[ "${exit_code}" -ne 0 ] || { echo "read-only mounted status should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${parent_before}" = "$(hash_root_markers "${root}")" ]
[ "${vendor_before}" = "$(hash_root_markers "${vendor_root}")" ]
grep -qx 'status: open' "${vendor_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"

# Ticket 114: transitive chains respect the strictest read-only mode.
run_taskr mount_status_transitive_read_only "${root}" status vendor:lib:003 done
[ "${exit_code}" -ne 0 ] || { echo "read-only parent chain should block transitive status" >&2; exit 1; }
grep -qi 'vendor\|lib\|read-only\|read only' "${stderr}"
lib_root="$(mount_path "${vendor_root}/taskr.toml" lib)"
grep -qx 'status: open' "${lib_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"

# Ticket 114: transitive read-write chains can update the mounted target.
run_taskr mount_status_transitive_read_write "${root}" status archive:child:003 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'status id=archive:child:003' "${stdout}"
grep -qx 'status: done' "${archive_child_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"
assert_status_timestamp "${archive_child_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md" done_at

# Ticket 114: terminal parent rules are enforced through mounted selectors.
run_taskr mount_status_terminal_parent "${root}" status archive:001 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_status_create_below_closed "${root}" create subtask "Late Mounted Child" --under archive:002 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "closed mounted parent should reject new children" >&2; exit 1; }
grep -qi 'done\|terminal\|parent\|closed' "${stderr}"

# Ticket 114: help, examples, and completion expose mounted status selectors.
run_taskr mount_status_help "${root}" status --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
run_taskr mount_status_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr status vendor:003 reviewing' "${stdout}"
run_taskr mount_status_selector_completion "${root}" __complete status ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^archive:003' "${stdout}"
grep -q '^vendor:003' "${stdout}"
grep -q '^archive:child:003' "${stdout}"
run_taskr mount_status_value_completion "${root}" __complete status archive:003 ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx 'done' "${stdout}"
