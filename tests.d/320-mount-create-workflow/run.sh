#!/usr/bin/env bash
set -euo pipefail

make_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "mount_target_${name}" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  printf '%s\n' "${root}"
}

# Ticket 108: explicit mount creation stores a virtual mount object in taskr.toml.
root="$(new_root mount-create-explicit)"
target="$(make_mount_target explicit-target)"
run_taskr mount_create_explicit "${root}" create mount "${target}" --id vendor --name "Vendor Project" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=vendor" "${stdout}"
test -f "${root}/taskr.toml"
grep -q 'id = "vendor"' "${root}/taskr.toml"
grep -q 'name = "Vendor Project"' "${root}/taskr.toml"
grep -q 'mode = "read-only"' "${root}/taskr.toml"
grep -q "path = \"${target}\"" "${root}/taskr.toml"
test ! -e "${root}/vendor"

# Ticket 108: read-write mode is accepted and persists after a write probe.
root="$(new_root mount-create-read-write)"
target="$(make_mount_target read-write-target)"
run_taskr mount_create_read_write "${root}" create mount "${target}" --id rw --name "Writable Mount" --mode read-write --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'id = "rw"' "${root}/taskr.toml"
grep -q 'mode = "read-write"' "${root}/taskr.toml"

# Ticket 108: quoted names with spaces are stored unchanged.
root="$(new_root mount-create-quoted-name)"
target="$(make_mount_target quoted-name-target)"
run_taskr mount_create_quoted_name "${root}" create mount "${target}" --id qn --name "Quoted Vendor Tickets" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'name = "Quoted Vendor Tickets"' "${root}/taskr.toml"

# Ticket 108: omitted --id derives a free lowercase ID from the first name word.
root="$(new_root mount-create-derived-id)"
target="$(make_mount_target derived-target)"
run_taskr mount_create_derived_id "${root}" create mount "${target}" --name "Vendor Project" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=v" "${stdout}"
grep -q 'id = "v"' "${root}/taskr.toml"

# Ticket 108: derivation tries longer first-word prefixes until one is free.
root="$(new_root mount-create-derived-next)"
target_v="$(make_mount_target derived-next-v)"
target_ve="$(make_mount_target derived-next-ve)"
run_taskr mount_create_existing_v "${root}" create mount "${target_v}" --id v --name "V Existing" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_create_derived_next "${root}" create mount "${target_ve}" --name "Vendor Project" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=ve" "${stdout}"
grep -q 'id = "ve"' "${root}/taskr.toml"

# Ticket 108: parent-directory input is resolved and stored as the Taskr root.
root="$(new_root mount-create-parent-path)"
target="$(make_mount_target parent-path-target)"
parent="$(dirname "${target}")"
run_taskr mount_create_parent_path "${root}" create mount "${parent}" --id parent --name "Parent Path" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "path = \"${target}\"" "${root}/taskr.toml"

# Ticket 108: invalid modes, IDs, duplicate IDs, and missing names fail clearly.
root="$(new_root mount-create-invalid-values)"
target="$(make_mount_target invalid-values-target)"
run_taskr mount_create_bad_mode "${root}" create mount "${target}" --id badmode --name "Bad Mode" --mode writable --no-edit
[ "${exit_code}" -ne 0 ] || { echo "invalid mount mode should fail" >&2; exit 1; }
grep -qi "mode\\|read-only\\|read-write" "${stderr}"
run_taskr mount_create_bad_id "${root}" create mount "${target}" --id "bad:id" --name "Bad Id" --no-edit
[ "${exit_code}" -ne 0 ] || { echo "invalid mount id should fail" >&2; exit 1; }
grep -qi "id\\|invalid" "${stderr}"
run_taskr mount_create_good_id "${root}" create mount "${target}" --id dupe --name "Duplicate" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_create_duplicate_id "${root}" create mount "${target}" --id dupe --name "Duplicate Again" --no-edit
[ "${exit_code}" -ne 0 ] || { echo "duplicate mount id should fail" >&2; exit 1; }
grep -qi "duplicate\\|exists\\|id" "${stderr}"
run_taskr mount_create_missing_name "${root}" create mount "${target}" --id noname --no-edit
[ "${exit_code}" -ne 0 ] || { echo "missing mount name should fail" >&2; exit 1; }
grep -qi "name" "${stderr}"

# Ticket 108: ID derivation fails when every first-word candidate is taken.
root="$(new_root mount-create-derive-exhausted)"
target_a="$(make_mount_target derive-a)"
target_ab="$(make_mount_target derive-ab)"
target_abc="$(make_mount_target derive-abc)"
target_new="$(make_mount_target derive-new)"
run_taskr mount_create_take_a "${root}" create mount "${target_a}" --id a --name "A" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_create_take_ab "${root}" create mount "${target_ab}" --id ab --name "AB" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_create_take_abc "${root}" create mount "${target_abc}" --id abc --name "ABC" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_create_derive_exhausted "${root}" create mount "${target_new}" --name "ABC" --no-edit
[ "${exit_code}" -ne 0 ] || { echo "exhausted mount id derivation should fail" >&2; exit 1; }
grep -qi "derive\\|id\\|attempt" "${stderr}"

# Ticket 108: missing and non-Taskr roots are rejected before storage.
root="$(new_root mount-create-bad-paths)"
missing="${SMOKEY_STATE_DIR}/does-not-exist"
run_taskr mount_create_missing_path "${root}" create mount "${missing}" --id missing --name "Missing" --no-edit
[ "${exit_code}" -ne 0 ] || { echo "missing mount path should fail" >&2; exit 1; }
grep -qi "path\\|missing\\|exist\\|read" "${stderr}"
plain="${SMOKEY_STATE_DIR}/plain-directory"
mkdir -p "${plain}"
run_taskr mount_create_plain_directory "${root}" create mount "${plain}" --id plain --name "Plain" --no-edit
[ "${exit_code}" -ne 0 ] || { echo "non-Taskr root should fail" >&2; exit 1; }
grep -qi "taskr\\|root\\|marker" "${stderr}"

# Ticket 108: help and completion expose create mount and its flags.
run_taskr mount_create_help "${root}" create --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "mount" "${stdout}"
run_taskr mount_create_mount_help "${root}" create mount --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- "--id" "${stdout}"
grep -q -- "--name" "${stdout}"
grep -q -- "--mode" "${stdout}"
run_taskr mount_create_completion "${root}" __complete create ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "mount" "${stdout}"
