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

make_create_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "create_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "create_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_item_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local child_target
  local blocked_target
  root="$(new_root "${name}")"
  vendor_target="$(make_create_mount_target "${name}-vendor-target")"
  archive_target="$(make_create_mount_target "${name}-archive-target")"
  child_target="$(make_create_mount_target "${name}-child-target")"
  blocked_target="$(make_create_mount_target "${name}-blocked-target")"
  cat >"${archive_target}/taskr.toml" <<EOF
[[mounts]]
id = "child"
name = "Writable Child"
path = "${child_target}"
mode = "read-write"
EOF
  cat >"${vendor_target}/taskr.toml" <<EOF
[[mounts]]
id = "blocked"
name = "Blocked Child"
path = "${blocked_target}"
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

root="$(create_mount_item_fixture mount-create-items-root)"
vendor_root="$(mount_path "${root}/taskr.toml" vendor)"
archive_root="$(mount_path "${root}/taskr.toml" archive)"
archive_child_root="$(mount_path "${archive_root}/taskr.toml" child)"
vendor_blocked_root="$(mount_path "${vendor_root}/taskr.toml" blocked)"

# Ticket 119: create milestone targets the selected read-write mounted root.
parent_before="$(hash_root_files "${root}")"
run_taskr mount_create_milestone "${root}" create milestone "Imported Roadmap" --mount archive --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'created item id=003' "${stdout}"
grep -q 'path=003-imported-roadmap' "${stdout}"
grep -q 'marker=milestone.md' "${stdout}"
[ -f "${archive_root}/003-imported-roadmap/milestone.md" ]
[ "${parent_before}" = "$(hash_root_files "${root}")" ] || { echo "parent root should not receive mounted create marker changes" >&2; exit 1; }
test ! -e "${root}/003-imported-roadmap"

# Ticket 119: create task accepts unprefixed --under inside the selected mount.
run_taskr mount_create_task_unprefixed_under "${root}" create task "Mounted New Work" --mount archive --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'created item id=004' "${stdout}"
[ -f "${archive_root}/001-mounted-roadmap/004-mounted-new-work/task.md" ]
grep -qx 'title: Mounted New Work' "${archive_root}/001-mounted-roadmap/004-mounted-new-work/task.md"

# Ticket 119: create subtask accepts matching prefixed --under inside the selected mount.
run_taskr mount_create_subtask_prefixed_under "${root}" create subtask "Mounted Follow Up" --mount archive --under archive:002 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'created item id=005' "${stdout}"
[ -f "${archive_root}/001-mounted-roadmap/002-mounted-task/005-mounted-follow-up/subtask.md" ]

# Ticket 119: new IDs are allocated from the target root, not the parent root.
if grep -q 'created item id=006' "${SMOKEY_STATE_DIR}/mount_create_task_unprefixed_under.stdout"; then
  echo "mounted create should not allocate from parent root id space" >&2
  exit 1
fi
grep -q 'created item id=004' "${SMOKEY_STATE_DIR}/mount_create_task_unprefixed_under.stdout"
grep -q 'created item id=005' "${SMOKEY_STATE_DIR}/mount_create_subtask_prefixed_under.stdout"

# Ticket 119: --mount . targets the current local root explicitly with .: selectors.
run_taskr mount_create_local_placeholder "${root}" create subtask "Explicit Local Child" --mount . --under .:003 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'created item id=006' "${stdout}"
[ -f "${root}/001-mvp/003-workflows-definieren/006-explicit-local-child/subtask.md" ]

# Ticket 119: transitive read-write mounts are valid create targets when the whole chain is writable.
run_taskr mount_create_transitive_rw "${root}" create task "Transitive Mounted Work" --mount archive:child --under archive:child:001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'created item id=003' "${stdout}"
[ -f "${archive_child_root}/001-mounted-roadmap/003-transitive-mounted-work/task.md" ]

# Ticket 119: read-only mounts and read-only parent chains reject creation without mutations.
vendor_before="$(hash_root_files "${vendor_root}")"
run_taskr mount_create_read_only "${root}" create task "Rejected Vendor Work" --mount vendor --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "read-only mounted create should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${vendor_before}" = "$(hash_root_files "${vendor_root}")" ]
test ! -e "${vendor_root}/001-mounted-roadmap/003-rejected-vendor-work"

blocked_before="$(hash_root_files "${vendor_blocked_root}")"
run_taskr mount_create_transitive_read_only_chain "${root}" create task "Rejected Blocked Work" --mount vendor:blocked --under vendor:blocked:001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "read-only transitive parent chain should fail create" >&2; exit 1; }
grep -qi 'vendor\|blocked\|read-only\|read only' "${stderr}"
[ "${blocked_before}" = "$(hash_root_files "${vendor_blocked_root}")" ]

# Ticket 119: --under prefixes must match the selected --mount target.
run_taskr mount_create_mismatched_under_prefix "${root}" create subtask "Wrong Mount Child" --mount archive --under vendor:002 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "mismatched --mount/--under prefixes should fail" >&2; exit 1; }
grep -qi 'archive\|vendor\|mount\|under\|mismatch' "${stderr}"
test ! -e "${archive_root}/001-mounted-roadmap/006-wrong-mount-child"

# Ticket 119: invalid mount selectors fail clearly before writing.
before_all="$(hash_root_files "${root}") $(hash_root_files "${archive_root}") $(hash_root_files "${vendor_root}")"
run_taskr mount_create_unknown_mount "${root}" create task "Unknown Mount Work" --mount missing --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "unknown mount should fail create" >&2; exit 1; }
grep -qi 'missing\|mount\|not found\|no match' "${stderr}"
run_taskr mount_create_missing_mount_root "${root}" create task "Missing Root Work" --mount archive:missing --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "missing transitive mount should fail create" >&2; exit 1; }
grep -qi 'missing\|mount\|not found\|no match' "${stderr}"
[ "${before_all}" = "$(hash_root_files "${root}") $(hash_root_files "${archive_root}") $(hash_root_files "${vendor_root}")" ]

# Ticket 119: unavailable, cyclic, and duplicate transitive mount graphs fail clearly.
unavailable_root="$(new_root mount-create-items-unavailable)"
cat >"${unavailable_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-create-mounted-root"
mode = "read-write"
EOF
run_taskr mount_create_unavailable "${unavailable_root}" create task "Unavailable Work" --mount missing --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail create" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

cycle_root="$(new_root mount-create-items-cycle)"
cycle_target="$(make_create_mount_target mount-create-items-cycle-target)"
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
run_taskr mount_create_cycle "${cycle_root}" create task "Cycle Work" --mount vendor --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail create" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

collision_root="$(new_root mount-create-items-collision)"
collision_vendor="$(make_create_mount_target mount-create-items-collision-vendor)"
collision_archive="$(make_create_mount_target mount-create-items-collision-archive)"
collision_lib="$(make_create_mount_target mount-create-items-collision-lib)"
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
run_taskr mount_create_collision "${collision_root}" create task "Collision Work" --mount vendor --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "transitive mount id collisions should fail create" >&2; exit 1; }
grep -qi 'duplicate\|collision\|id\|mount' "${stderr}"

# Ticket 119: omitted --mount keeps existing local create behavior.
run_taskr mount_create_omitted_mount "${root}" create task "Plain Local Work" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'created item id=007' "${stdout}"
[ -f "${root}/001-mvp/007-plain-local-work/task.md" ]

# Ticket 119: help, docs-facing examples, and completion cover mounted create.
run_taskr mount_create_items_help "${root}" create --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--mount' "${stdout}"
grep -qi 'mounted\|mount' "${stdout}"
run_taskr mount_create_items_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr create task "New work" --mount vendor --under 003' "${stdout}"
grep -q 'taskr create task "Local work" --mount . --under .:003' "${stdout}"
run_taskr mount_create_items_mount_completion "${root}" __complete create task "Mounted" --mount ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'.\tlocal root' "${stdout}"
grep -qx $'archive\tmount read-write Archive Project' "${stdout}"
grep -qx $'archive:child\tmount read-write Writable Child' "${stdout}"
if grep -q '^vendor' "${stdout}"; then
  echo "create --mount completion should omit read-only mounts" >&2
  exit 1
fi
run_taskr mount_create_items_under_completion "${root}" __complete create subtask "Mounted" --mount archive --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'archive:001\tmilestone open Mounted Roadmap' "${stdout}"
grep -qx $'archive:002\ttask open Mounted Task' "${stdout}"
