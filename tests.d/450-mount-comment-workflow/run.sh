#!/usr/bin/env bash
set -euo pipefail

mount_path() {
  local config="$1"
  local id="$2"
  awk -F'"' -v id="${id}" '/id = / { seen=($2 == id) } seen && /path = / { print $2; exit }' "${config}"
}

hash_root_files() {
  local root="$1"
  find "${root}" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum
}

make_comment_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "comment_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "comment_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "comment_target_${name}_subtask" "${root}" create subtask "Mounted Child" --under 002 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_comment_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local child_target
  root="$(new_root "${name}")"
  vendor_target="$(make_comment_mount_target "${name}-vendor-target")"
  archive_target="$(make_comment_mount_target "${name}-archive-target")"
  child_target="$(make_comment_mount_target "${name}-child-target")"
  cat >"${archive_target}/taskr.toml" <<EOF
[[mounts]]
id = "child"
name = "Read Only Child"
path = "${child_target}"
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

assert_comment_entry() {
  local marker="$1"
  local text="$2"
  if ! grep -Eq "^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}: ${text}$" "${marker}"; then
    echo "missing timestamped comment in ${marker}: ${text}" >&2
    return 1
  fi
}

root="$(create_mount_comment_fixture mount-comment-root)"
vendor_root="$(mount_path "${root}/taskr.toml" vendor)"
archive_root="$(mount_path "${root}/taskr.toml" archive)"
archive_child_root="$(mount_path "${archive_root}/taskr.toml" child)"
archive_marker="${archive_root}/001-mounted-roadmap/002-mounted-task/task.md"
vendor_marker="${vendor_root}/001-mounted-roadmap/002-mounted-task/task.md"
child_marker="${archive_child_root}/001-mounted-roadmap/002-mounted-task/task.md"
local_marker="${root}/001-mvp/003-workflows-definieren/task.md"

# Ticket 121: read-write mounted comments mutate only the mounted marker.
parent_before="$(hash_root_files "${root}")"
archive_before="$(hash_root_files "${archive_root}")"
run_taskr mount_comment_read_write "${root}" comment archive:002 "  Mounted   write   \"works\"  "
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'commented source=archive (Archive Project)' "${stdout}"
grep -q 'path=001-mounted-roadmap/002-mounted-task/task.md' "${stdout}"
assert_comment_entry "${archive_marker}" 'Mounted write "works"'
[ "${parent_before}" = "$(hash_root_files "${root}")" ]
if [ "${archive_before}" = "$(hash_root_files "${archive_root}")" ]; then
  echo "read-write mounted comment should modify mounted root" >&2
  exit 1
fi
if grep -q 'Mounted write' "${root}/001-mvp/003-workflows-definieren/task.md"; then
  echo "parent root should not receive shadow comment data" >&2
  exit 1
fi

# Ticket 121: stdin comments preserve existing multi-line comment formatting on mounted markers.
printf 'first mounted line\nsecond mounted line\n' | "${TASKR_BIN}" "${root}" comment archive:003 --stdin >"${SMOKEY_STATE_DIR}/mount_comment_stdin.stdout" 2>"${SMOKEY_STATE_DIR}/mount_comment_stdin.stderr"
grep -q 'commented source=archive (Archive Project)' "${SMOKEY_STATE_DIR}/mount_comment_stdin.stdout"
grep -q '^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:$' "${archive_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"
grep -q '^  first mounted line$' "${archive_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"
grep -q '^  second mounted line$' "${archive_root}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"

# Ticket 121: .: selectors explicitly target the local root and keep mounted roots untouched.
archive_after_read_write="$(hash_root_files "${archive_root}")"
run_taskr mount_comment_local_prefixed "${root}" comment .:003 "Local explicit comment"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'commented id=003 path=001-mvp/003-workflows-definieren/task.md' "${stdout}"
assert_comment_entry "${local_marker}" 'Local explicit comment'
[ "${archive_after_read_write}" = "$(hash_root_files "${archive_root}")" ]

# Ticket 121: read-only direct and transitive mounts reject comments without mutation.
vendor_before="$(hash_root_files "${vendor_root}")"
run_taskr mount_comment_read_only "${root}" comment vendor:002 "Must not write"
[ "${exit_code}" -ne 0 ] || { echo "read-only mounted comment should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${vendor_before}" = "$(hash_root_files "${vendor_root}")" ]
if grep -q 'Must not write' "${vendor_marker}"; then
  echo "read-only marker should not receive comment" >&2
  exit 1
fi

child_before="$(hash_root_files "${archive_child_root}")"
run_taskr mount_comment_transitive_read_only "${root}" comment archive:child:002 "Must not write through child"
[ "${exit_code}" -ne 0 ] || { echo "transitive read-only mounted comment should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${child_before}" = "$(hash_root_files "${archive_child_root}")" ]
if grep -q 'Must not write through child' "${child_marker}"; then
  echo "transitive read-only marker should not receive comment" >&2
  exit 1
fi

# Ticket 121: ambiguous mounted selectors and invalid mount graphs fail clearly.
run_taskr mount_comment_ambiguous "${root}" comment "Mounted Task" "Ambiguous comment"
[ "${exit_code}" -ne 0 ] || { echo "ambiguous mounted comment selector should fail" >&2; exit 1; }
grep -qi 'ambiguous\|candidates' "${stderr}"
grep -q 'vendor:002' "${stderr}"
grep -q 'archive:002' "${stderr}"
grep -q 'archive:child:002' "${stderr}"

run_taskr mount_comment_missing_item "${root}" comment archive:999 "Missing comment"
[ "${exit_code}" -ne 0 ] || { echo "missing mounted item should fail comment" >&2; exit 1; }
grep -qi 'archive\|999\|not found\|no match' "${stderr}"
run_taskr mount_comment_unknown_mount "${root}" comment missing:001 "Unknown mount comment"
[ "${exit_code}" -ne 0 ] || { echo "unknown mount should fail comment" >&2; exit 1; }
grep -qi 'missing\|mount\|not found\|no match' "${stderr}"

unavailable_root="$(new_root mount-comment-unavailable)"
cat >"${unavailable_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-comment-mounted-root"
mode = "read-write"
EOF
run_taskr mount_comment_unavailable "${unavailable_root}" comment missing:001 "Unavailable"
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail comment" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

cycle_root="$(new_root mount-comment-cycle)"
cycle_target="$(make_comment_mount_target mount-comment-cycle-target)"
cat >"${cycle_root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${cycle_target}"
mode = "read-write"
EOF
cat >"${cycle_target}/taskr.toml" <<EOF
[[mounts]]
id = "back"
name = "Back To Root"
path = "${cycle_root}"
mode = "read-write"
EOF
run_taskr mount_comment_cycle "${cycle_root}" comment vendor:002 "Cycle"
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail comment" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

collision_root="$(new_root mount-comment-collision)"
collision_vendor="$(make_comment_mount_target mount-comment-collision-vendor)"
collision_archive="$(make_comment_mount_target mount-comment-collision-archive)"
collision_lib="$(make_comment_mount_target mount-comment-collision-lib)"
cat >"${collision_vendor}/taskr.toml" <<EOF
[[mounts]]
id = "lib"
name = "Vendor Library"
path = "${collision_lib}"
mode = "read-write"
EOF
cat >"${collision_archive}/taskr.toml" <<EOF
[[mounts]]
id = "lib"
name = "Archive Library"
path = "${collision_lib}"
mode = "read-write"
EOF
cat >"${collision_root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${collision_vendor}"
mode = "read-write"

[[mounts]]
id = "archive"
name = "Archive Project"
path = "${collision_archive}"
mode = "read-write"
EOF
run_taskr mount_comment_collision "${collision_root}" comment vendor:002 "Collision"
[ "${exit_code}" -ne 0 ] || { echo "transitive mount id collisions should fail comment" >&2; exit 1; }
grep -qi 'duplicate\|collision\|id\|mount' "${stderr}"

# Ticket 121: help, examples, and completion cover mounted comment selectors.
run_taskr mount_comment_help "${root}" comment --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
run_taskr mount_comment_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr comment vendor:003 "Reviewed external work"' "${stdout}"
grep -q 'taskr comment .:003 "Reviewed local work"' "${stdout}"
run_taskr mount_comment_completion "${root}" __complete comment ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'.:003\ttask active Define workflows' "${stdout}"
grep -qx $'archive:002\ttask open Mounted Task' "${stdout}"
if grep -q '^vendor:002' "${stdout}"; then
  echo "comment completion should omit read-only mounted item selectors" >&2
  exit 1
fi
