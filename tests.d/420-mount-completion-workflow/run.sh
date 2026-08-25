#!/usr/bin/env bash
set -euo pipefail

make_completion_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "completion_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "completion_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "completion_target_${name}_subtask" "${root}" create subtask "Mounted Subtask" --under 002 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_completion_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  local child_target
  root="$(new_root "${name}")"
  vendor_target="$(make_completion_mount_target "${name}-vendor-target")"
  archive_target="$(make_completion_mount_target "${name}-archive-target")"
  lib_target="$(make_completion_mount_target "${name}-lib-target")"
  child_target="$(make_completion_mount_target "${name}-child-target")"
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
path = "${child_target}"
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

assert_completion_has() {
  local expected="$1"
  if ! grep -qx "${expected}" "${stdout}"; then
    echo "missing completion: ${expected}" >&2
    cat "${stdout}" >&2
    return 1
  fi
}

assert_completion_lacks_prefix() {
  local prefix="$1"
  if grep -q "^${prefix}" "${stdout}"; then
    echo "unexpected completion prefix: ${prefix}" >&2
    cat "${stdout}" >&2
    return 1
  fi
}

root="$(create_mount_completion_fixture mount-completion-root)"

# Ticket 118: mount-object selectors complete local, direct, and transitive mounts.
run_taskr mount_completion_show_objects "${root}" __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'vendor\tmount read-only Vendor Project'
assert_completion_has $'archive\tmount read-write Archive Project'
assert_completion_has $'vendor:lib\tmount read-write Library Project'
assert_completion_has $'archive:child\tmount read-write Writable Child'

# Ticket 118: read-only commands complete mounted item selectors, including local-root-prefixed selectors.
assert_completion_has $'.:001\tmilestone active MVP'
assert_completion_has $'vendor:001\tmilestone open Mounted Roadmap'
assert_completion_has $'vendor:002\ttask open Mounted Task'
assert_completion_has $'vendor:003\tsubtask open Mounted Subtask'
assert_completion_has $'vendor:lib:002\ttask open Mounted Task'
assert_completion_has $'archive:child:002\ttask open Mounted Task'

# Ticket 118: tree and list parent/filter surfaces complete mounted selectors at the exact flag position.
run_taskr mount_completion_tree "${root}" __complete tree ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'vendor\tmount read-only Vendor Project'
assert_completion_has $'vendor:001\tmilestone open Mounted Roadmap'
assert_completion_has $'vendor:002\ttask open Mounted Task'
assert_completion_has $'vendor:lib\tmount read-write Library Project'
run_taskr mount_completion_list_under "${root}" __complete list --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'.:001\tmilestone active MVP'
assert_completion_has $'vendor:001\tmilestone open Mounted Roadmap'
assert_completion_has $'archive:001\tmilestone open Mounted Roadmap'
assert_completion_has $'archive:child:001\tmilestone open Mounted Roadmap'

# Ticket 118: create --mount completes only writable roots plus the explicit local root placeholder.
run_taskr mount_completion_create_mount "${root}" __complete create task "New Mounted Work" --mount ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'.\tlocal root'
assert_completion_has $'archive\tmount read-write Archive Project'
assert_completion_has $'archive:child\tmount read-write Writable Child'
assert_completion_lacks_prefix 'vendor'

# Ticket 118: create --under with --mount completes parents inside the selected writable mount.
run_taskr mount_completion_create_under_local "${root}" __complete create subtask "Local Child" --mount . --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'.:001\tmilestone active MVP'
assert_completion_has $'.:003\ttask active Define workflows'
run_taskr mount_completion_create_under_mounted "${root}" __complete create subtask "Mounted Child" --mount archive --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'archive:001\tmilestone open Mounted Roadmap'
assert_completion_has $'archive:002\ttask open Mounted Task'
assert_completion_lacks_prefix 'vendor:'

# Ticket 118: mutating status completion suggests only legally writable mounted item selectors.
run_taskr mount_completion_status_selector "${root}" __complete status ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'.:003\ttask active Define workflows'
assert_completion_has $'archive:002\ttask open Mounted Task'
assert_completion_has $'archive:child:003\tsubtask open Mounted Subtask'
assert_completion_lacks_prefix 'vendor:'

# Ticket 118: remove/reconfigure mount complete mount IDs, not item selectors.
run_taskr mount_completion_reconfigure "${root}" __complete reconfigure mount ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'vendor\tmount read-only Vendor Project'
assert_completion_has $'archive\tmount read-write Archive Project'
assert_completion_has $'vendor:lib\tmount read-write Library Project'
assert_completion_lacks_prefix 'vendor:001'
run_taskr mount_completion_remove "${root}" __complete remove mount ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_completion_has $'vendor\tmount read-only Vendor Project'
assert_completion_has $'archive\tmount read-write Archive Project'
assert_completion_has $'archive:child\tmount read-write Writable Child'
assert_completion_lacks_prefix 'archive:001'

# Ticket 118: report currently has no selector arguments and should suppress file fallback cleanly.
run_taskr mount_completion_report "${root}" __complete report ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q ':4$' "${stdout}"
if grep -q '^vendor' "${stdout}"; then
  echo "report completion should not invent selector arguments before report accepts them" >&2
  exit 1
fi

# Ticket 118: unavailable mounts do not fall back to filesystem completion.
bad_root="$(new_root mount-completion-unavailable)"
cat >"${bad_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-completion-mounted-root"
mode = "read-only"
EOF
run_taskr mount_completion_unavailable_show "${bad_root}" __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q ':4$' "${stdout}"
if grep -qi 'missing\|no such\|invalid marker' "${stdout}" "${stderr}"; then
  echo "completion should suppress unavailable mount diagnostics" >&2
  exit 1
fi

# Ticket 118: help and examples mention mounted selector completion where useful.
run_taskr mount_completion_help "${root}" completion --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted' "${stdout}"
run_taskr mount_completion_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'vendor:003' "${stdout}"
grep -q -- '--mount .' "${stdout}"
