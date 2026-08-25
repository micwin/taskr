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

make_fake_system_opener() {
  local name="$1"
  local dir="${SMOKEY_STATE_DIR}/${name}-bin"
  mkdir -p "${dir}"
  cat >"${dir}/xdg-open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$1" >>"${FAKE_XDG_OPEN_LOG}"
EOF
  chmod +x "${dir}/xdg-open"
  printf '%s\n' "${dir}"
}

make_open_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "open_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "open_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

create_mount_open_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local child_target
  root="$(new_root "${name}")"
  vendor_target="$(make_open_mount_target "${name}-vendor-target")"
  archive_target="$(make_open_mount_target "${name}-archive-target")"
  child_target="$(make_open_mount_target "${name}-child-target")"
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

root="$(create_mount_open_fixture mount-open-root)"
vendor_root="$(mount_path "${root}/taskr.toml" vendor)"
archive_root="$(mount_path "${root}/taskr.toml" archive)"
archive_child_root="$(mount_path "${archive_root}/taskr.toml" child)"

# Ticket 120: read-write mounted open launches the editor for the mounted marker path.
parent_before="$(hash_root_files "${root}")"
archive_before="$(hash_root_files "${archive_root}")"
EDITOR=true run_taskr mount_open_read_write "${root}" open archive:002
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'opened source=archive (Archive Project)' "${stdout}"
grep -q 'path=001-mounted-roadmap/002-mounted-task/task.md' "${stdout}"
grep -q 'opener=editor' "${stdout}"
[ "${parent_before}" = "$(hash_root_files "${root}")" ]
[ "${archive_before}" = "$(hash_root_files "${archive_root}")" ]

# Ticket 120: transitive read-write mounted open uses the full source identity.
EDITOR=true run_taskr mount_open_transitive_read_write "${root}" open archive:child:002
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'opened source=archive:child (Writable Child)' "${stdout}"
grep -q 'path=001-mounted-roadmap/002-mounted-task/task.md' "${stdout}"
grep -q 'opener=editor' "${stdout}"
[ -f "${archive_child_root}/001-mounted-roadmap/002-mounted-task/task.md" ]

# Ticket 120: local-root-prefixed selectors open local markers without mount source output.
EDITOR=true run_taskr mount_open_local_prefixed "${root}" open .:003
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'opened path=001-mvp/003-workflows-definieren/task.md opener=editor' "${stdout}"
if grep -q 'source=' "${stdout}"; then
  echo "local-root-prefixed open should not report mount source" >&2
  exit 1
fi

# Ticket 120: existing local open behavior remains unchanged when no mount prefix is used.
EDITOR=true run_taskr mount_open_local_existing "${root}" open 003
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'opened path=001-mvp/003-workflows-definieren/task.md opener=editor' "${stdout}"

# Ticket 120: read-only mounted roots fail for editor without modifying roots.
vendor_before="$(hash_root_files "${vendor_root}")"
EDITOR=true run_taskr mount_open_read_only_editor "${root}" open vendor:002
[ "${exit_code}" -ne 0 ] || { echo "read-only mounted editor open should fail" >&2; exit 1; }
grep -qi 'read-only\|read only\|mount' "${stderr}"
[ "${vendor_before}" = "$(hash_root_files "${vendor_root}")" ]

# Ticket 120: --system may open read-only mounted roots through the system opener.
fake_bin="$(make_fake_system_opener mount-open-read-only-system)"
system_log="${SMOKEY_STATE_DIR}/mount-open-read-only-system.log"
FAKE_XDG_OPEN_LOG="${system_log}" PATH="${fake_bin}:${PATH}" run_taskr mount_open_read_only_system "${root}" open vendor:002 --system
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'opened source=vendor (Vendor Project)' "${stdout}"
grep -q 'path=001-mounted-roadmap/002-mounted-task/task.md' "${stdout}"
grep -q 'opener=system' "${stdout}"
grep -q "${vendor_root}/001-mounted-roadmap/002-mounted-task/task.md" "${system_log}"
[ "${vendor_before}" = "$(hash_root_files "${vendor_root}")" ]

# Ticket 120: invalid mounted selectors and broken mount graphs fail clearly.
EDITOR=true run_taskr mount_open_ambiguous "${root}" open "Mounted Task"
[ "${exit_code}" -ne 0 ] || { echo "ambiguous mounted item should fail open" >&2; exit 1; }
grep -qi 'ambiguous\|candidates' "${stderr}"
grep -q 'vendor:002' "${stderr}"
grep -q 'archive:002' "${stderr}"
grep -q 'archive:child:002' "${stderr}"

EDITOR=true run_taskr mount_open_missing_item "${root}" open archive:999
[ "${exit_code}" -ne 0 ] || { echo "missing mounted item should fail open" >&2; exit 1; }
grep -qi 'archive\|999\|not found\|no match' "${stderr}"
EDITOR=true run_taskr mount_open_unknown_mount "${root}" open missing:001
[ "${exit_code}" -ne 0 ] || { echo "unknown mount should fail open" >&2; exit 1; }
grep -qi 'missing\|mount\|not found\|no match' "${stderr}"

unavailable_root="$(new_root mount-open-unavailable)"
cat >"${unavailable_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-open-mounted-root"
mode = "read-write"
EOF
EDITOR=true run_taskr mount_open_unavailable "${unavailable_root}" open missing:001
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail open" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

cycle_root="$(new_root mount-open-cycle)"
cycle_target="$(make_open_mount_target mount-open-cycle-target)"
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
EDITOR=true run_taskr mount_open_cycle "${cycle_root}" open vendor:002
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail open" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

collision_root="$(new_root mount-open-collision)"
collision_vendor="$(make_open_mount_target mount-open-collision-vendor)"
collision_archive="$(make_open_mount_target mount-open-collision-archive)"
collision_lib="$(make_open_mount_target mount-open-collision-lib)"
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
EDITOR=true run_taskr mount_open_collision "${collision_root}" open vendor:002
[ "${exit_code}" -ne 0 ] || { echo "transitive mount id collisions should fail open" >&2; exit 1; }
grep -qi 'duplicate\|collision\|id\|mount' "${stderr}"

# Ticket 120: help, examples, and completion cover mounted open selectors.
run_taskr mount_open_help "${root}" open --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted\|prefix' "${stdout}"
run_taskr mount_open_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr open vendor:003' "${stdout}"
grep -q 'taskr open .:003' "${stdout}"
run_taskr mount_open_completion "${root}" __complete open ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'.:003\ttask active Define workflows' "${stdout}"
grep -qx $'archive:002\ttask open Mounted Task' "${stdout}"
grep -qx $'archive:child:002\ttask open Mounted Task' "${stdout}"
if grep -q '^vendor:002' "${stdout}"; then
  echo "open completion should omit read-only mounted item selectors" >&2
  exit 1
fi
run_taskr mount_open_system_completion "${root}" __complete open --system ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'vendor:002\ttask open Mounted Task' "${stdout}"
