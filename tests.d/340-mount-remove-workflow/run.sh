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

create_remove_fixture() {
  local name="$1"
  local root
  local vendor
  local archive
  root="$(new_root "${name}")"
  vendor="$(make_mount_target "${name}-vendor")"
  archive="$(make_mount_target "${name}-archive")"
  cat >"${root}/taskr.toml" <<EOF
[[mounts]]
id = "vendor"
name = "Vendor Project"
path = "${vendor}"
mode = "read-only"

[[mounts]]
id = "archive"
name = "Archive Project"
path = "${archive}"
mode = "read-write"
EOF
  printf '%s\n' "${root}"
}

# Ticket 110: remove mount deletes only the selected local config entry.
root="$(create_remove_fixture mount-remove-success)"
vendor_path="$(awk -F'"' '/id = "vendor"/ { seen=1 } seen && /path = / { print $2; exit }' "${root}/taskr.toml")"
vendor_before="$(find "${vendor_path}" -type f -print | sort | xargs sha256sum)"
run_taskr mount_remove_success "${root}" remove mount vendor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
if grep -q 'id = "vendor"' "${root}/taskr.toml"; then
  echo "removed mount should not remain in taskr.toml" >&2
  exit 1
fi
grep -q 'id = "archive"' "${root}/taskr.toml"
vendor_after="$(find "${vendor_path}" -type f -print | sort | xargs sha256sum)"
[ "${vendor_before}" = "${vendor_after}" ] || { echo "mounted root should remain unchanged" >&2; exit 1; }
run_taskr mount_remove_doctor "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Ticket 110: removing an unknown mount fails clearly and preserves config.
root="$(create_remove_fixture mount-remove-unknown)"
before="$(sha256sum "${root}/taskr.toml")"
run_taskr mount_remove_unknown "${root}" remove mount missing
[ "${exit_code}" -ne 0 ] || { echo "unknown mount removal should fail" >&2; exit 1; }
grep -qi "not found\\|no match\\|mount" "${stderr}"
after="$(sha256sum "${root}/taskr.toml")"
[ "${before}" = "${after}" ] || { echo "failed remove should preserve config" >&2; exit 1; }

# Ticket 110: ambiguous mount selectors fail clearly and preserve config.
root="$(create_remove_fixture mount-remove-ambiguous)"
before="$(sha256sum "${root}/taskr.toml")"
run_taskr mount_remove_ambiguous "${root}" remove mount a
[ "${exit_code}" -ne 0 ] || { echo "ambiguous mount removal should fail" >&2; exit 1; }
grep -qi "ambiguous\\|candidates" "${stderr}"
after="$(sha256sum "${root}/taskr.toml")"
[ "${before}" = "${after}" ] || { echo "ambiguous remove should preserve config" >&2; exit 1; }

# Ticket 110: remove mount requires a mount selector.
root="$(create_remove_fixture mount-remove-missing-arg)"
before="$(sha256sum "${root}/taskr.toml")"
run_taskr mount_remove_missing_arg "${root}" remove mount
[ "${exit_code}" -ne 0 ] || { echo "remove mount without id should fail" >&2; exit 1; }
grep -qi "arg\\|selector\\|mount" "${stderr}"
after="$(sha256sum "${root}/taskr.toml")"
[ "${before}" = "${after}" ] || { echo "missing-arg remove should preserve config" >&2; exit 1; }

# Ticket 110: help and completion expose remove mount and mount IDs.
root="$(create_remove_fixture mount-remove-help)"
run_taskr mount_remove_help "${root}" remove mount --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "remove mount" "${stdout}"
run_taskr mount_remove_completion "${root}" __complete remove mount ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "vendor" "${stdout}"
grep -q "archive" "${stdout}"
