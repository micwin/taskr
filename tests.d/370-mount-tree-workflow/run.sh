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

# Ticket 113: default tree renders mount objects with mode, not lifecycle status.
run_taskr mount_tree_default "${root}" tree
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx 'vendor [mount read-only] Vendor Project' "${stdout}"
grep -Fqx '  vendor:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -Fqx '    vendor:002 [task open] Mounted Task' "${stdout}"
grep -Fqx 'vendor:lib [mount read-only] Library Project' "${stdout}"
grep -Fqx '  vendor:lib:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -Fqx 'archive [mount read-write] Archive Project' "${stdout}"
if grep -Eq 'vendor \\[mount (open|designing|developing|active|reviewing|blocked|done|cancelled)\\]' "${stdout}"; then
  echo "mount tree rows should show mode instead of Taskr lifecycle status" >&2
  exit 1
fi

# Ticket 113: default unfinished filtering applies inside mounted roots.
if grep -q 'Mounted Done Task' "${stdout}"; then
  echo "default tree should hide done mounted leaves" >&2
  exit 1
fi
run_taskr mount_tree_all "${root}" tree --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx '    vendor:003 [task done] Mounted Done Task' "${stdout}"
grep -Fqx '    archive:003 [task done] Mounted Done Task' "${stdout}"

# Ticket 113: selected mounted subtrees start at the selected mounted item.
run_taskr mount_tree_selected "${root}" tree vendor:001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx 'vendor:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -Fqx '  vendor:002 [task open] Mounted Task' "${stdout}"
if grep -q '^vendor \\[mount read-only\\]' "${stdout}"; then
  echo "selected mounted subtree should not include parent mount object" >&2
  exit 1
fi

# Ticket 113: alternate indentation modes work with mounted roots.
run_taskr mount_tree_ascii "${root}" tree --ascii
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx '+- vendor:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -Fqx '   +- vendor:002 [task open] Mounted Task' "${stdout}"
run_taskr mount_tree_tabs "${root}" tree --tabs
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'\tvendor:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -qx $'\t\tvendor:002 [task open] Mounted Task' "${stdout}"
run_taskr mount_tree_wide "${root}" tree --wide
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx '    vendor:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -Fqx '        vendor:002 [task open] Mounted Task' "${stdout}"

# Ticket 113: local and mounted IDs can coexist in the same tree.
run_taskr mount_tree_collision "${root}" tree --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fqx '001 [milestone active] #(public,website) MVP' "${stdout}"
grep -Fqx '  002 [task done] #internal Define directory structure' "${stdout}"
grep -Fqx '  vendor:001 [milestone open] Mounted Roadmap' "${stdout}"
grep -Fqx '    vendor:002 [task open] Mounted Task' "${stdout}"

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
