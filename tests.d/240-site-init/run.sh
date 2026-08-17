#!/usr/bin/env bash
set -euo pipefail


run_taskr() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "${TASKR_BIN}" "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

new_root() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}-root"
  cp -R "${TASKR_BASE_ROOT}" "${root}"
  printf '%s\n' "${root}"
}

# Existing empty directories are claimed and configured relative to the Taskr root.
root="$(new_root site-init-existing)"
target="${SMOKEY_STATE_DIR}/site-init-existing-output"
mkdir -p "${target}"
run_taskr site_init_existing "${root}" site init ../site-init-existing-output
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^\[site\]$' "${root}/taskr.toml"
grep -q '^directory = "../site-init-existing-output"$' "${root}/taskr.toml"
grep -qx 'taskr-site-v1' "${target}/.taskr-site"
grep -q "root=${root} directory=${target} created=false changed=true" "${stdout}"

# Repeating the same initialization is idempotent.
before_config="$(sha256sum "${root}/taskr.toml")"
before_marker="$(sha256sum "${target}/.taskr-site")"
run_taskr site_init_same "${root}" site init ../site-init-existing-output
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "${before_config}" = "$(sha256sum "${root}/taskr.toml")" ]
[ "${before_marker}" = "$(sha256sum "${target}/.taskr-site")" ]
grep -q 'created=false changed=false' "${stdout}"

# Missing directories require the explicit creation flag, which creates parents too.
root="$(new_root site-init-missing)"
target="${SMOKEY_STATE_DIR}/site-init-missing-parent/site"
run_taskr site_init_missing "${root}" site init ../site-init-missing-parent/site
[ "${exit_code}" -eq 2 ] || { echo "missing site directory should exit 2" >&2; exit 1; }
[ ! -e "${target}" ]
[ ! -e "${root}/taskr.toml" ]
grep -qi 'create-if-missing' "${stderr}"
run_taskr site_init_create "${root}" site init ../site-init-missing-parent/site --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ -d "${target}" ]
grep -qx 'taskr-site-v1' "${target}/.taskr-site"
grep -q 'created=true changed=true' "${stdout}"

# Absolute target paths remain absolute in taskr.toml.
root="$(new_root site-init-absolute)"
target="${SMOKEY_STATE_DIR}/site-init-absolute-output"
mkdir -p "${target}"
run_taskr site_init_absolute "${root}" site init "${target}"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fq "directory = \"${target}\"" "${root}/taskr.toml"

# Existing comments survive adding the first supported table.
root="$(new_root site-init-comments)"
target="${SMOKEY_STATE_DIR}/site-init-comments-output"
mkdir -p "${target}"
printf '# project comment\n' >"${root}/taskr.toml"
run_taskr site_init_comments "${root}" site init ../site-init-comments-output
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx '# project comment' "${root}/taskr.toml"
run_taskr site_init_comments_doctor "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# A different existing association is never changed by site init.
other_target="${SMOKEY_STATE_DIR}/site-init-comments-other"
mkdir -p "${other_target}"
before="$(sha256sum "${root}/taskr.toml")"
run_taskr site_init_reconfigure "${root}" site init ../site-init-comments-other
[ "${exit_code}" -eq 2 ] || { echo "site init should reject reconfiguration" >&2; exit 1; }
[ "${before}" = "$(sha256sum "${root}/taskr.toml")" ]
grep -qi 'config\|already.*initial' "${stderr}"

# Foreign content, regular files, and symlinks cannot be claimed.
root="$(new_root site-init-foreign)"
target="${SMOKEY_STATE_DIR}/site-init-foreign-output"
mkdir -p "${target}"
printf 'foreign\n' >"${target}/keep.txt"
run_taskr site_init_foreign "${root}" site init ../site-init-foreign-output
[ "${exit_code}" -eq 2 ] || { echo "foreign site directory should exit 2" >&2; exit 1; }
[ ! -e "${root}/taskr.toml" ]
grep -qi 'nonempty\|not empty\|ownership' "${stderr}"
root="$(new_root site-init-file)"
target="${SMOKEY_STATE_DIR}/site-init-file-output"
printf 'file\n' >"${target}"
run_taskr site_init_file "${root}" site init ../site-init-file-output
[ "${exit_code}" -eq 2 ] || { echo "site target file should exit 2" >&2; exit 1; }
root="$(new_root site-init-symlink)"
real_target="${SMOKEY_STATE_DIR}/site-init-real-output"
target="${SMOKEY_STATE_DIR}/site-init-symlink-output"
mkdir -p "${real_target}"
ln -s "${real_target}" "${target}"
run_taskr site_init_symlink "${root}" site init ../site-init-symlink-output
[ "${exit_code}" -eq 2 ] || { echo "site target symlink should exit 2" >&2; exit 1; }

# Source and output trees must not overlap in either direction.
root="$(new_root site-init-overlap)"
run_taskr site_init_same_root "${root}" site init .
[ "${exit_code}" -eq 2 ] || { echo "Taskr root cannot be its own site directory" >&2; exit 1; }
run_taskr site_init_child "${root}" site init ./generated --create-if-missing
[ "${exit_code}" -eq 2 ] || { echo "site directory below Taskr root should exit 2" >&2; exit 1; }
[ ! -e "${root}/generated" ]
run_taskr site_init_parent "${root}" site init ..
[ "${exit_code}" -eq 2 ] || { echo "site directory containing Taskr root should exit 2" >&2; exit 1; }

# Help, examples, and shell completion expose the final command surface.
run_taskr site_init_help site init --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'site init <site-directory>' "${stdout}"
grep -q -- '--create-if-missing' "${stdout}"
run_taskr site_init_examples examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr site init' "${stdout}"
run_taskr site_init_completion __complete site init ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q ':0$' "${stdout}"
