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

make_doctor_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "doctor_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

write_one_mount_config() {
  local root="$1"
  local id="$2"
  local name="$3"
  local path="$4"
  local mode="$5"
  cat >"${root}/taskr.toml" <<EOF
[[mounts]]
id = "${id}"
name = "${name}"
path = "${path}"
mode = "${mode}"
EOF
}

# Ticket 115: default doctor accepts readable read-only and writable read-write mounts.
root="$(new_root mount-doctor-valid)"
vendor_root="$(make_doctor_mount_target mount-doctor-valid-vendor)"
archive_root="$(make_doctor_mount_target mount-doctor-valid-archive)"
cat >"${root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${vendor_root}"
mode = "read-only"

[[mounts]]
id = "archive"
name = "Archive Project"
path = "${archive_root}"
mode = "read-write"
EOF
before_archive="$(hash_root_files "${archive_root}")"
run_taskr mount_doctor_valid "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "ok root=" "${stdout}"
grep -qi 'mount' "${stdout}"
[ "${before_archive}" = "$(hash_root_files "${archive_root}")" ] || { echo "read-write probe should leave mounted root unchanged" >&2; exit 1; }

# Ticket 115: malformed mount config fails with mount-aware diagnostics.
bad_mode_root="$(new_root mount-doctor-bad-mode)"
write_one_mount_config "${bad_mode_root}" vendor "Vendor Project" "${vendor_root}" writable
run_taskr mount_doctor_bad_mode "${bad_mode_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "invalid mount mode should fail doctor" >&2; exit 1; }
grep -qi 'vendor\|mount' "${stderr}"
grep -qi 'mode\|read-only\|read-write' "${stderr}"

duplicate_root="$(new_root mount-doctor-duplicate-id)"
cat >"${duplicate_root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${vendor_root}"
mode = "read-only"

[[mounts]]
id = "vendor"
name = "Vendor Duplicate"
path = "${archive_root}"
mode = "read-only"
EOF
run_taskr mount_doctor_duplicate_id "${duplicate_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "duplicate mount ids should fail doctor" >&2; exit 1; }
grep -qi 'duplicate\|id' "${stderr}"
grep -qi 'vendor\|mount' "${stderr}"

# Ticket 115: missing and non-Taskr mounted roots fail clearly.
missing_root="$(new_root mount-doctor-missing-root)"
write_one_mount_config "${missing_root}" missing "Missing Project" "${SMOKEY_STATE_DIR}/missing-doctor-mounted-root" read-only
run_taskr mount_doctor_missing_root "${missing_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "missing mounted root should fail doctor" >&2; exit 1; }
grep -qi 'missing\|exist\|read\|path' "${stderr}"
grep -qi 'missing\|mount' "${stderr}"

plain_dir="${SMOKEY_STATE_DIR}/mount-doctor-plain-directory"
mkdir -p "${plain_dir}"
plain_root="$(new_root mount-doctor-plain-root)"
write_one_mount_config "${plain_root}" plain "Plain Directory" "${plain_dir}" read-only
run_taskr mount_doctor_plain_directory "${plain_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "non-Taskr mounted root should fail doctor" >&2; exit 1; }
grep -qi 'plain\|mount' "${stderr}"
grep -qi 'taskr\|root\|marker' "${stderr}"

# Ticket 115: graph checks follow transitive mounts and report cycles.
cycle_root="$(new_root mount-doctor-cycle-root)"
cycle_target="$(make_doctor_mount_target mount-doctor-cycle-target)"
write_one_mount_config "${cycle_root}" vendor "Vendor Project" "${cycle_target}" read-only
write_one_mount_config "${cycle_target}" back "Back To Root" "${cycle_root}" read-only
run_taskr mount_doctor_cycle "${cycle_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail doctor" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

collision_root="$(new_root mount-doctor-transitive-collision)"
collision_vendor="$(make_doctor_mount_target mount-doctor-collision-vendor)"
collision_archive="$(make_doctor_mount_target mount-doctor-collision-archive)"
collision_lib="$(make_doctor_mount_target mount-doctor-collision-lib)"
write_one_mount_config "${collision_vendor}" lib "Vendor Library" "${collision_lib}" read-only
write_one_mount_config "${collision_archive}" lib "Archive Library" "${collision_lib}" read-only
cat >"${collision_root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${collision_vendor}"
mode = "read-only"

[[mounts]]
id = "archive"
name = "Archive Project"
path = "${collision_archive}"
mode = "read-only"
EOF
run_taskr mount_doctor_transitive_id_collision "${collision_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "transitive mount id collisions should fail doctor" >&2; exit 1; }
grep -qi 'duplicate\|collision\|id' "${stderr}"
grep -qi 'lib\|mount' "${stderr}"

# Ticket 115: --include-mounts invokes existing deep validation with mount identity.
deep_root="$(new_root mount-doctor-include-mounts)"
deep_target="$(make_doctor_mount_target mount-doctor-include-target)"
mkdir -p "${deep_target}/001-mounted-roadmap/099-broken-child"
write_one_mount_config "${deep_root}" vendor "Vendor Project" "${deep_target}" read-only
run_taskr mount_doctor_default_skips_deep_structure "${deep_root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_doctor_include_mounts "${deep_root}" doctor --include-mounts
[ "${exit_code}" -ne 0 ] || { echo "--include-mounts should validate mounted item structure" >&2; exit 1; }
grep -qi 'vendor\|mount' "${stderr}"
grep -q '099-broken-child' "${stderr}"

# Ticket 115: --fix removes clearly broken local mount entries and keeps good ones.
fix_root="$(new_root mount-doctor-fix-broken-mount)"
fix_target="$(make_doctor_mount_target mount-doctor-fix-target)"
cat >"${fix_root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${fix_target}"
mode = "read-only"

[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/mount-doctor-fix-missing-root"
mode = "read-only"
EOF
before_target="$(hash_root_files "${fix_target}")"
run_taskr mount_doctor_fix_missing "${fix_root}" doctor --fix
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'fixed\|removed' "${stdout}"
grep -q 'id = "vendor"' "${fix_root}/taskr.toml"
if grep -q 'id = "missing"' "${fix_root}/taskr.toml"; then
  echo "doctor --fix should remove missing local mount entry" >&2
  exit 1
fi
[ "${before_target}" = "$(hash_root_files "${fix_target}")" ] || { echo "doctor --fix should not mutate healthy mounted root" >&2; exit 1; }

# Ticket 115: --fix does not fix cycles, collisions, or read-only mounted data.
run_taskr mount_doctor_fix_cycle "${cycle_root}" doctor --fix
[ "${exit_code}" -ne 0 ] || { echo "doctor --fix should not repair mount cycles" >&2; exit 1; }
grep -qi 'not fixable\|cycle\|cyclic' "${stderr}"
run_taskr mount_doctor_fix_collision "${collision_root}" doctor --fix
[ "${exit_code}" -ne 0 ] || { echo "doctor --fix should not repair transitive mount id collisions" >&2; exit 1; }
grep -qi 'not fixable\|collision\|duplicate' "${stderr}"
run_taskr mount_doctor_fix_read_only_deep "${deep_root}" doctor --fix --include-mounts
[ "${exit_code}" -ne 0 ] || { echo "doctor --fix --include-mounts should reject read-only mounted repairs" >&2; exit 1; }
grep -qi 'read-only\|read only\|not fixable\|vendor' "${stderr}"

# Ticket 115: --include-mounts can deeply validate clean read-write mounts.
rw_root="$(new_root mount-doctor-read-write-deep)"
rw_target="$(make_doctor_mount_target mount-doctor-read-write-target)"
write_one_mount_config "${rw_root}" archive "Archive Project" "${rw_target}" read-write
run_taskr mount_doctor_read_write_deep "${rw_root}" doctor --include-mounts
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Ticket 115: help and examples cover include-mounts and fix behavior.
run_taskr mount_doctor_help "${root}" doctor --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--include-mounts' "${stdout}"
grep -q -- '--fix' "${stdout}"
grep -qi 'mount' "${stdout}"
run_taskr mount_doctor_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr doctor --include-mounts' "${stdout}"
grep -q 'taskr doctor --fix' "${stdout}"
