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

create_mount_fixture() {
  local name="$1"
  local root
  local target
  root="$(new_root "${name}")"
  target="$(make_mount_target "${name}-target")"
  cat >"${root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${target}"
mode = "read-only"
EOF
  printf '%s\n' "${root}"
}

# Ticket 109: reconfigure mount updates the name and preserves other fields.
root="$(create_mount_fixture mount-reconfigure-name)"
run_taskr mount_reconfigure_name "${root}" reconfigure mount vendor --name "Vendor Tickets"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'id = "vendor"' "${root}/taskr.toml"
grep -q 'name = "Vendor Tickets"' "${root}/taskr.toml"
grep -q 'mode = "read-only"' "${root}/taskr.toml"

# Ticket 109: reconfigure mount updates mode and persists read-write after probing.
root="$(create_mount_fixture mount-reconfigure-mode)"
run_taskr mount_reconfigure_mode "${root}" reconfigure mount vendor --mode read-write
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'mode = "read-write"' "${root}/taskr.toml"

# Ticket 109: reconfigure mount resolves a new path, including parent-directory input.
root="$(create_mount_fixture mount-reconfigure-path)"
new_target="$(make_mount_target mount-reconfigure-new-target)"
new_parent="$(dirname "${new_target}")"
run_taskr mount_reconfigure_path "${root}" reconfigure mount vendor --path "${new_parent}"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "path = \"${new_target}\"" "${root}/taskr.toml"

# Ticket 109: multiple fields can be updated in one invocation.
root="$(create_mount_fixture mount-reconfigure-multiple)"
new_target="$(make_mount_target mount-reconfigure-multiple-new-target)"
run_taskr mount_reconfigure_multiple "${root}" reconfigure mount vendor --name "Combined Mount" --path "${new_target}" --mode read-write
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'name = "Combined Mount"' "${root}/taskr.toml"
grep -q "path = \"${new_target}\"" "${root}/taskr.toml"
grep -q 'mode = "read-write"' "${root}/taskr.toml"

# Ticket 109: explicit --id changes the mount ID when the new ID is valid.
root="$(create_mount_fixture mount-reconfigure-id)"
run_taskr mount_reconfigure_id "${root}" reconfigure mount vendor --id supplier
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'id = "supplier"' "${root}/taskr.toml"
if grep -q 'id = "vendor"' "${root}/taskr.toml"; then
  echo "old mount id should be replaced" >&2
  exit 1
fi

# Ticket 109: --auto-adjust-id derives from the existing name and ignores self-collision.
root="$(create_mount_fixture mount-reconfigure-auto-self)"
run_taskr mount_reconfigure_auto_self "${root}" reconfigure mount vendor --auto-adjust-id
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'id = "v"' "${root}/taskr.toml"

# Ticket 109: --auto-adjust-id can derive from a newly supplied quoted name.
root="$(create_mount_fixture mount-reconfigure-auto-name)"
run_taskr mount_reconfigure_auto_name "${root}" reconfigure mount vendor --name "Alpha Vendor" --auto-adjust-id
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'id = "a"' "${root}/taskr.toml"
grep -q 'name = "Alpha Vendor"' "${root}/taskr.toml"

# Ticket 109: --auto-adjust-id tries longer candidates while preserving the current mount as legal.
root="$(create_mount_fixture mount-reconfigure-auto-next)"
other_target="$(make_mount_target mount-reconfigure-auto-next-other)"
cat >>"${root}/taskr.toml" <<EOF
[[mounts]]
id = "v"
name = "Other Vendor"
path = "${other_target}"
mode = "read-only"
EOF
run_taskr mount_reconfigure_auto_next "${root}" reconfigure mount vendor --auto-adjust-id
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'id = "ve"' "${root}/taskr.toml"

# Ticket 109: invalid reconfigure requests fail clearly.
root="$(create_mount_fixture mount-reconfigure-invalid)"
run_taskr mount_reconfigure_missing_updates "${root}" reconfigure mount vendor
[ "${exit_code}" -ne 0 ] || { echo "missing reconfigure parameters should fail" >&2; exit 1; }
grep -qi "parameter\\|update\\|flag" "${stderr}"
run_taskr mount_reconfigure_bad_mode "${root}" reconfigure mount vendor --mode writable
[ "${exit_code}" -ne 0 ] || { echo "invalid reconfigure mode should fail" >&2; exit 1; }
grep -qi "mode\\|read-only\\|read-write" "${stderr}"
run_taskr mount_reconfigure_bad_id "${root}" reconfigure mount vendor --id "bad:id"
[ "${exit_code}" -ne 0 ] || { echo "invalid reconfigure id should fail" >&2; exit 1; }
grep -qi "id\\|invalid" "${stderr}"
run_taskr mount_reconfigure_missing_path "${root}" reconfigure mount vendor --path "${SMOKEY_STATE_DIR}/missing-reconfigure-path"
[ "${exit_code}" -ne 0 ] || { echo "missing reconfigure path should fail" >&2; exit 1; }
grep -qi "path\\|missing\\|exist\\|read" "${stderr}"
run_taskr mount_reconfigure_id_and_auto "${root}" reconfigure mount vendor --id next --auto-adjust-id
[ "${exit_code}" -ne 0 ] || { echo "--id and --auto-adjust-id should be exclusive" >&2; exit 1; }
grep -qi "exclusive\\|auto-adjust-id\\|id" "${stderr}"
run_taskr mount_reconfigure_empty_name "${root}" reconfigure mount vendor --name ""
[ "${exit_code}" -ne 0 ] || { echo "empty mount name should fail" >&2; exit 1; }
grep -qi "name\\|empty" "${stderr}"
run_taskr mount_reconfigure_empty_id "${root}" reconfigure mount vendor --id ""
[ "${exit_code}" -ne 0 ] || { echo "empty mount id should fail" >&2; exit 1; }
grep -qi "id\\|empty\\|invalid" "${stderr}"
duplicate_target="$(make_mount_target mount-reconfigure-duplicate-id-target)"
cat >>"${root}/taskr.toml" <<EOF
[[mounts]]
id = "taken"
name = "Taken"
path = "${duplicate_target}"
mode = "read-only"
EOF
run_taskr mount_reconfigure_duplicate_id "${root}" reconfigure mount vendor --id taken
[ "${exit_code}" -ne 0 ] || { echo "duplicate mount id should fail" >&2; exit 1; }
grep -qi "duplicate\\|exists\\|id" "${stderr}"

# Ticket 109: unchanged reconfigure requests succeed as no-op updates.
root="$(create_mount_fixture mount-reconfigure-unchanged)"
before="$(sha256sum "${root}/taskr.toml")"
run_taskr mount_reconfigure_unchanged_name "${root}" reconfigure mount vendor --name "Vendor Project"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
after="$(sha256sum "${root}/taskr.toml")"
[ "${before}" = "${after}" ] || { echo "unchanged mount name should not alter config" >&2; exit 1; }
run_taskr mount_reconfigure_unchanged_mode "${root}" reconfigure mount vendor --mode read-only
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Ticket 109: ambiguous or missing selectors fail clearly.
root="$(create_mount_fixture mount-reconfigure-selector)"
second_target="$(make_mount_target mount-reconfigure-selector-second)"
cat >>"${root}/taskr.toml" <<EOF
[[mounts]]
id = "vend"
name = "Vendor Archive"
path = "${second_target}"
mode = "read-only"
EOF
run_taskr mount_reconfigure_ambiguous "${root}" reconfigure mount ven --name "Ambiguous"
[ "${exit_code}" -ne 0 ] || { echo "ambiguous mount selector should fail" >&2; exit 1; }
grep -qi "ambiguous\\|candidates" "${stderr}"
run_taskr mount_reconfigure_missing_selector "${root}" reconfigure mount missing --name "Missing"
[ "${exit_code}" -ne 0 ] || { echo "missing mount selector should fail" >&2; exit 1; }
grep -qi "not found\\|no match" "${stderr}"

# Ticket 109: help and completion expose reconfigure mount and mount IDs.
run_taskr mount_reconfigure_help "${root}" reconfigure mount --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- "--name" "${stdout}"
grep -q -- "--path" "${stdout}"
grep -q -- "--mode" "${stdout}"
grep -q -- "--id" "${stdout}"
grep -q -- "--auto-adjust-id" "${stdout}"
run_taskr mount_reconfigure_completion "${root}" __complete reconfigure mount ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "vendor" "${stdout}"
