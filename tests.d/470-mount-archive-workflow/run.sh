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

make_archive_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "archive_target_${name}_roadmap" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "archive_target_${name}_done" "${root}" create task "Mounted Done Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "archive_target_${name}_done_status" "${root}" status 002 done
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "archive_target_${name}_active" "${root}" create task "Mounted Active Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "archive_target_${name}_parent" "${root}" create task "Mounted Parent Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "archive_target_${name}_child" "${root}" create subtask "Mounted Open Child" --under 004 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_archive_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local child_target
  root="$(new_root "${name}")"
  vendor_target="$(make_archive_mount_target "${name}-vendor-target")"
  archive_target="$(make_archive_mount_target "${name}-archive-target")"
  child_target="$(make_archive_mount_target "${name}-child-target")"
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

root="$(create_mount_archive_fixture mount-archive-root)"
vendor_root="$(mount_path "${root}/taskr.toml" vendor)"
archive_root="$(mount_path "${root}/taskr.toml" archive)"
archive_child_root="$(mount_path "${archive_root}/taskr.toml" child)"

# Ticket 123: read-write mounted archive moves the closed subtree into that mounted root's archive.
parent_before="$(hash_root_files "${root}")"
archive_before="$(hash_root_files "${archive_root}")"
run_taskr mount_archive_read_write "${root}" archive archive:002 --to 2026
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'archived source=archive (Archive Project)' "${stdout}"
grep -q 'id=archive:002' "${stdout}"
grep -q 'to=archive/2026/002-mounted-done-task' "${stdout}"
test -f "${archive_root}/archive/2026/002-mounted-done-task/task.md"
test ! -e "${archive_root}/001-mounted-roadmap/002-mounted-done-task"
test ! -e "${root}/archive/2026/002-mounted-done-task"
[ "${parent_before}" = "$(hash_root_files "${root}")" ]
if [ "${archive_before}" = "$(hash_root_files "${archive_root}")" ]; then
  echo "mounted archive should modify mounted root" >&2
  exit 1
fi

# Ticket 123: .: selectors explicitly target the local root.
run_taskr mount_archive_local_prefixed "${root}" archive .:002 --to local
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'archived id=002' "${stdout}"
grep -q 'to=archive/local/002-verzeichnisstruktur' "${stdout}"
test -f "${root}/archive/local/002-verzeichnisstruktur/task.md"

# Ticket 123: transitive read-write mounted archive uses the transitive root's archive area.
run_taskr mount_archive_transitive_read_write "${root}" archive archive:child:002 --to child-2026
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'archived source=archive:child (Writable Child)' "${stdout}"
grep -q 'to=archive/child-2026/002-mounted-done-task' "${stdout}"
test -f "${archive_child_root}/archive/child-2026/002-mounted-done-task/task.md"
test ! -e "${archive_root}/archive/child-2026/002-mounted-done-task/task.md"

# Ticket 123: read-only mounted roots reject archive and leave roots unchanged.
vendor_before="$(hash_root_files "${vendor_root}")"
run_taskr mount_archive_read_only "${root}" archive vendor:002 --to 2026
[ "${exit_code}" -ne 0 ] || { echo "read-only mounted archive should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${vendor_before}" = "$(hash_root_files "${vendor_root}")" ]
test -f "${vendor_root}/001-mounted-roadmap/002-mounted-done-task/task.md"
test ! -e "${vendor_root}/archive/2026/002-mounted-done-task"

# Ticket 123: existing closed-subtree rules remain enforced in mounted roots.
run_taskr mount_archive_active_task "${root}" archive archive:003
[ "${exit_code}" -ne 0 ] || { echo "active mounted task archive should fail" >&2; exit 1; }
grep -qi 'active\|unfinished\|closed' "${stderr}"

run_taskr mount_archive_unfinished_subtree "${root}" archive archive:004
[ "${exit_code}" -ne 0 ] || { echo "unfinished mounted subtree archive should fail" >&2; exit 1; }
grep -qi 'active\|unfinished\|children\|closed' "${stderr}"

# Ticket 123: ambiguous mounted selectors and invalid mount graphs fail clearly.
run_taskr mount_archive_ambiguous "${root}" archive "Mounted Done Task"
[ "${exit_code}" -ne 0 ] || { echo "ambiguous mounted archive selector should fail" >&2; exit 1; }
grep -qi 'ambiguous\|candidates' "${stderr}"
grep -q 'vendor:002' "${stderr}"
grep -q 'archive:child:002' "${stderr}"

run_taskr mount_archive_missing_item "${root}" archive archive:999
[ "${exit_code}" -ne 0 ] || { echo "missing mounted item should fail archive" >&2; exit 1; }
grep -qi 'archive\|999\|not found\|no match' "${stderr}"

unavailable_root="$(new_root mount-archive-unavailable)"
cat >"${unavailable_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-archive-mounted-root"
mode = "read-write"
EOF
run_taskr mount_archive_unavailable "${unavailable_root}" archive missing:002
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail archive" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

cycle_root="$(new_root mount-archive-cycle)"
cycle_target="$(make_archive_mount_target mount-archive-cycle-target)"
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
run_taskr mount_archive_cycle "${cycle_root}" archive vendor:002
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail archive" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

collision_root="$(new_root mount-archive-collision)"
collision_vendor="$(make_archive_mount_target mount-archive-collision-vendor)"
collision_archive="$(make_archive_mount_target mount-archive-collision-archive)"
collision_lib="$(make_archive_mount_target mount-archive-collision-lib)"
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
run_taskr mount_archive_collision "${collision_root}" archive vendor:002
[ "${exit_code}" -ne 0 ] || { echo "transitive mount id collisions should fail archive" >&2; exit 1; }
grep -qi 'duplicate\|collision\|id\|mount' "${stderr}"

# Ticket 123: help, examples, and completion cover mounted archive selectors.
run_taskr mount_archive_help "${root}" archive --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
grep -q -- '--to' "${stdout}"

run_taskr mount_archive_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr archive archive:002 --to 2026' "${stdout}"
grep -q 'taskr archive .:002 --to 2026' "${stdout}"

run_taskr mount_archive_completion "${root}" __complete archive ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'.:002\ttask done Define directory structure' "${stdout}"
grep -qx $'archive:002\ttask done Mounted Done Task' "${stdout}"
grep -qx $'archive:child:002\ttask done Mounted Done Task' "${stdout}"
if grep -q '^vendor:002' "${stdout}"; then
  echo "archive completion should omit read-only mounted item selectors" >&2
  exit 1
fi
