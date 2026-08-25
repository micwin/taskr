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

make_move_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_roadmap" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_child" "${root}" create subtask "Mounted Child" --under 002 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_release" "${root}" create milestone "Mounted Release" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_loose" "${root}" create task "Mounted Loose Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_closed_parent" "${root}" create task "Mounted Closed Parent" --under 001 --status open --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "move_target_${name}_close_parent" "${root}" status 006 done
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_move_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local child_target
  root="$(new_root "${name}")"
  vendor_target="$(make_move_mount_target "${name}-vendor-target")"
  archive_target="$(make_move_mount_target "${name}-archive-target")"
  child_target="$(make_move_mount_target "${name}-child-target")"
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

root="$(create_mount_move_fixture mount-move-root)"
vendor_root="$(mount_path "${root}/taskr.toml" vendor)"
archive_root="$(mount_path "${root}/taskr.toml" archive)"
archive_child_root="$(mount_path "${archive_root}/taskr.toml" child)"

# Ticket 122: same-mount --under moves inside a read-write mounted root.
parent_before="$(hash_root_files "${root}")"
archive_before="$(hash_root_files "${archive_root}")"
run_taskr mount_move_same_mount_under "${root}" move archive:005 --under archive:004
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'moved source=archive (Archive Project)' "${stdout}"
grep -q 'id=archive:005' "${stdout}"
grep -q 'from=001-mounted-roadmap/005-mounted-loose-task' "${stdout}"
grep -q 'to=004-mounted-release/005-mounted-loose-task' "${stdout}"
test -f "${archive_root}/004-mounted-release/005-mounted-loose-task/task.md"
test ! -e "${archive_root}/001-mounted-roadmap/005-mounted-loose-task"
[ "${parent_before}" = "$(hash_root_files "${root}")" ]
if [ "${archive_before}" = "$(hash_root_files "${archive_root}")" ]; then
  echo "mounted move should modify mounted root" >&2
  exit 1
fi

# Ticket 122: --under without a mount prefix resolves in the source mounted root.
run_taskr mount_move_implicit_under_source_root "${root}" move archive:005 --under 001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'moved source=archive (Archive Project)' "${stdout}"
grep -q 'to=001-mounted-roadmap/005-mounted-loose-task' "${stdout}"
test -f "${archive_root}/001-mounted-roadmap/005-mounted-loose-task/task.md"

# Ticket 122: --root moves to the mounted root level, not to the parent root.
run_taskr mount_move_root "${root}" move archive:005 --root
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'moved source=archive (Archive Project)' "${stdout}"
grep -q 'to=005-mounted-loose-task' "${stdout}"
test -f "${archive_root}/005-mounted-loose-task/task.md"
test ! -e "${root}/005-mounted-loose-task"

# Ticket 122: --retype keeps existing local type-conversion rules inside mounted roots.
run_taskr mount_move_retype_task_to_subtask "${root}" move archive:005 --under archive:002 --retype
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'moved source=archive (Archive Project)' "${stdout}"
grep -q 'type=task->subtask' "${stdout}"
test -f "${archive_root}/001-mounted-roadmap/002-mounted-task/005-mounted-loose-task/subtask.md"

run_taskr mount_move_retype_subtask_to_task "${root}" move archive:005 --under archive:004 --retype
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'moved source=archive (Archive Project)' "${stdout}"
grep -q 'type=subtask->task' "${stdout}"
test -f "${archive_root}/004-mounted-release/005-mounted-loose-task/task.md"

# Ticket 122: local-root-prefixed moves remain local.
run_taskr mount_move_local_prefixed "${root}" move .:005 --under .:001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'moved id=005' "${stdout}"
grep -q 'to=001-mvp/005-open-work' "${stdout}"
test -f "${root}/001-mvp/005-open-work/task.md"

# Ticket 122: mounted parent selectors must match the source mount chain.
run_taskr mount_move_cross_mount_rejected "${root}" move archive:005 --under vendor:001
[ "${exit_code}" -ne 0 ] || { echo "cross-mount move should fail" >&2; exit 1; }
grep -qi 'cross-root\|same root\|mount\|source' "${stderr}"

run_taskr mount_move_mounted_to_local_rejected "${root}" move archive:005 --under .:001
[ "${exit_code}" -ne 0 ] || { echo "mounted-to-local move should fail" >&2; exit 1; }
grep -qi 'cross-root\|same root\|mount\|source' "${stderr}"

run_taskr mount_move_local_to_mounted_rejected "${root}" move .:005 --under archive:001
[ "${exit_code}" -ne 0 ] || { echo "local-to-mounted move should fail" >&2; exit 1; }
grep -qi 'cross-root\|same root\|mount\|source' "${stderr}"

run_taskr mount_move_transitive_parent_mismatch "${root}" move archive:child:005 --under archive:001
[ "${exit_code}" -ne 0 ] || { echo "transitive source should reject parent from shorter mount chain" >&2; exit 1; }
grep -qi 'cross-root\|same root\|mount\|source' "${stderr}"

# Ticket 122: read-only mounted roots reject moves and leave roots unchanged.
vendor_before="$(hash_root_files "${vendor_root}")"
run_taskr mount_move_read_only "${root}" move vendor:005 --under vendor:004
[ "${exit_code}" -ne 0 ] || { echo "read-only mounted move should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${vendor_before}" = "$(hash_root_files "${vendor_root}")" ]

# Ticket 122: terminal-parent, descendant, rollback, and timestamps remain enforced.
run_taskr mount_move_under_closed_parent "${root}" move archive:005 --under archive:006 --retype
[ "${exit_code}" -ne 0 ] || { echo "move under closed mounted parent should fail" >&2; exit 1; }
grep -qi 'closed\|terminal\|done\|parent' "${stderr}"

run_taskr mount_move_descendant_rejected "${root}" move archive:002 --under archive:003
[ "${exit_code}" -ne 0 ] || { echo "move into mounted descendant should fail" >&2; exit 1; }
grep -qi 'self\|descendant' "${stderr}"

rollback_root="$(create_mount_move_fixture mount-move-rollback)"
rollback_archive="$(mount_path "${rollback_root}/taskr.toml" archive)"
run_taskr mount_move_invalid_retype_with_children "${rollback_root}" move archive:002 --under archive:005 --retype
[ "${exit_code}" -ne 0 ] || { echo "mounted task with subtask should not invalidly retype below task" >&2; exit 1; }
grep -qi 'invalid\|cannot\|subtask\|children' "${stderr}"
test -f "${rollback_archive}/001-mounted-roadmap/002-mounted-task/task.md"
test -f "${rollback_archive}/001-mounted-roadmap/002-mounted-task/003-mounted-child/subtask.md"

timestamp_root="$(create_mount_move_fixture mount-move-timestamp)"
timestamp_archive="$(mount_path "${timestamp_root}/taskr.toml" archive)"
timestamp_marker="${timestamp_archive}/001-mounted-roadmap/005-mounted-loose-task/task.md"
run_taskr mount_move_timestamps "${timestamp_root}" move archive:005 --under archive:004
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Eq '^updated_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "${timestamp_archive}/004-mounted-release/005-mounted-loose-task/task.md"
test ! -e "${timestamp_marker}"

# Ticket 122: invalid mounted selectors and broken mount graphs fail clearly.
run_taskr mount_move_missing_item "${root}" move archive:999 --under archive:001
[ "${exit_code}" -ne 0 ] || { echo "missing mounted item should fail move" >&2; exit 1; }
grep -qi 'archive\|999\|not found\|no match' "${stderr}"

run_taskr mount_move_ambiguous_source "${root}" move "Mounted Loose Task" --under 001
[ "${exit_code}" -ne 0 ] || { echo "ambiguous mounted move selector should fail" >&2; exit 1; }
grep -qi 'ambiguous\|candidates' "${stderr}"
grep -q 'vendor:005' "${stderr}"
grep -q 'archive:005' "${stderr}"
grep -q 'archive:child:005' "${stderr}"

unavailable_root="$(new_root mount-move-unavailable)"
cat >"${unavailable_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-move-mounted-root"
mode = "read-write"
EOF
run_taskr mount_move_unavailable "${unavailable_root}" move missing:005 --under missing:001
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail move" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

cycle_root="$(new_root mount-move-cycle)"
cycle_target="$(make_move_mount_target mount-move-cycle-target)"
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
run_taskr mount_move_cycle "${cycle_root}" move vendor:005 --under vendor:004
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail move" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

collision_root="$(new_root mount-move-collision)"
collision_vendor="$(make_move_mount_target mount-move-collision-vendor)"
collision_archive="$(make_move_mount_target mount-move-collision-archive)"
collision_lib="$(make_move_mount_target mount-move-collision-lib)"
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
run_taskr mount_move_collision "${collision_root}" move vendor:005 --under vendor:004
[ "${exit_code}" -ne 0 ] || { echo "transitive mount id collisions should fail move" >&2; exit 1; }
grep -qi 'duplicate\|collision\|id\|mount' "${stderr}"

# Ticket 122: help, examples, and completion cover mounted move selectors and --under.
run_taskr mount_move_help "${root}" move --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
grep -q -- '--under' "${stdout}"
grep -q -- '--root' "${stdout}"
grep -q -- '--retype' "${stdout}"

run_taskr mount_move_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr move archive:005 --under archive:004' "${stdout}"
grep -q 'taskr move archive:005 --under 004' "${stdout}"
grep -q 'taskr move .:005 --under .:001' "${stdout}"

run_taskr mount_move_source_completion "${root}" __complete move ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'.:003\ttask active Define workflows' "${stdout}"
grep -qx $'archive:005\ttask open Mounted Loose Task' "${stdout}"
grep -qx $'archive:child:005\ttask open Mounted Loose Task' "${stdout}"
if grep -q '^vendor:005' "${stdout}"; then
  echo "move source completion should omit read-only mounted item selectors" >&2
  exit 1
fi

run_taskr mount_move_under_completion "${root}" __complete move archive:005 --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'archive:001\tmilestone open Mounted Roadmap' "${stdout}"
grep -qx $'archive:004\tmilestone open Mounted Release' "${stdout}"
if grep -q '^vendor:001' "${stdout}"; then
  echo "mounted move --under completion should omit other mount chains" >&2
  exit 1
fi
if grep -qx $'.:001\tmilestone active MVP' "${stdout}"; then
  echo "mounted move --under completion should omit local parent chains" >&2
  exit 1
fi

run_taskr mount_move_implicit_under_completion "${root}" __complete move archive:005 --under 0
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'001\tmilestone open Mounted Roadmap' "${stdout}"
grep -qx $'004\tmilestone open Mounted Release' "${stdout}"
