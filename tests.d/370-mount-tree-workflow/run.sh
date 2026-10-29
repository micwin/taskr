#!/usr/bin/env bash
set -euo pipefail

make_tree_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "tree_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "tree_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "tree_target_${name}_done" "${root}" create task "Mounted Done Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "tree_target_${name}_done_status" "${root}" status 003 done
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  # Ticket 113: each source has its own subtask with the same local ID and title.
  run_taskr "tree_target_${name}_subtask" "${root}" create subtask "Mounted Child" --under 002 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_tree_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  root="$(new_root "${name}")"
  vendor_target="$(make_tree_mount_target "${name}-vendor-target")"
  archive_target="$(make_tree_mount_target "${name}-archive-target")"
  lib_target="$(make_tree_mount_target "${name}-lib-target")"
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

root="$(create_mount_tree_fixture mount-tree-root)"

# Ticket 113: full default output keeps each root's milestone, task, and subtask together, even with identical IDs and titles.
run_taskr mount_tree_default "${root}" tree
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/default.txt" "${stdout}"

# Ticket 113: --all restores closed tasks inside their own root, including local and mounted ID collisions.
run_taskr mount_tree_all "${root}" tree --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/all.txt" "${stdout}"

# Ticket 113: selected vendor milestones include only their own task and subtask.
run_taskr mount_tree_selected "${root}" tree vendor:001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/selected-vendor.txt" "${stdout}"

# Ticket 113: selecting the other direct mount never includes vendor or local work.
run_taskr mount_tree_selected_archive "${root}" tree archive:001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/selected-archive.txt" "${stdout}"

# Ticket 113: selecting the transitive mount never includes its owner's or another root's work.
run_taskr mount_tree_selected_transitive "${root}" tree vendor:lib:001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/selected-lib.txt" "${stdout}"

# Ticket 113: ASCII branches keep complete sibling roots and their descendants separated.
run_taskr mount_tree_ascii "${root}" tree --ascii
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/ascii.txt" "${stdout}"

# Ticket 113: tabs preserve the same complete hierarchy and mount boundaries.
run_taskr mount_tree_tabs "${root}" tree --tabs
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/tabs.txt" "${stdout}"

# Ticket 113: wide indentation preserves the same complete hierarchy and mount boundaries.
run_taskr mount_tree_wide "${root}" tree --wide
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/wide.txt" "${stdout}"

# Ticket 113: task-only roots stay grouped under their virtual mount beside all other sources.
tasks_only_target="${SMOKEY_STATE_DIR}/mount-tree-tasks-only"
cp -R "${SMOKEY_TEST_DIR}/fixtures/tasks-only" "${tasks_only_target}"
run_taskr mount_tree_add_tasks_only "${root}" create mount "${tasks_only_target}" --id tickets --name "Tickets Project"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_tree_tasks_only_combined "${root}" tree
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/tasks-only-combined.txt" "${stdout}"

# Ticket 113: selecting a task-only mount includes precisely its tasks and subtask.
run_taskr mount_tree_tasks_only_selected "${root}" tree tickets
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
diff -u "${SMOKEY_TEST_DIR}/expected/tasks-only-selected.txt" "${stdout}"

# Ticket 113: unavailable mounts fail clearly instead of being silently skipped.
bad_root="$(new_root mount-tree-unavailable)"
cat >"${bad_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-tree-mounted-root"
mode = "read-only"
EOF
run_taskr mount_tree_unavailable "${bad_root}" tree
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail tree" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

# Ticket 113: cyclic mounts fail clearly and are not rendered as infinite trees.
cycle_root="$(new_root mount-tree-cycle)"
cycle_target="$(make_tree_mount_target mount-tree-cycle-target)"
cat >"${cycle_root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${cycle_target}"
mode = "read-only"
EOF
cat >"${cycle_target}/taskr.toml" <<EOF
[[mounts]]
id = "back"
name = "Back To Root"
path = "${cycle_root}"
mode = "read-only"
EOF
run_taskr mount_tree_cycle "${cycle_root}" tree
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail tree" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

# Ticket 113: help and completion expose mounted tree selectors.
run_taskr mount_tree_help "${root}" tree --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
run_taskr mount_tree_completion "${root}" __complete tree ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q $'^vendor\tmount' "${stdout}"
grep -q '^vendor:001' "${stdout}"
grep -q $'^vendor:lib\tmount' "${stdout}"
grep -q '^vendor:lib:001' "${stdout}"
