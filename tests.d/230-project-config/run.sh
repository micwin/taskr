#!/usr/bin/env bash
set -euo pipefail


# A missing project config remains valid, while a valid [site] table is loaded.
root="$(new_root config-valid)"
run_taskr config_missing "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
cat >"${root}/taskr.toml" <<'EOF'
[site]
directory = "../generated-site"
EOF
run_taskr config_valid "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'ok root=' "${stdout}"

# TOML syntax errors identify the project config and block normal commands.
root="$(new_root config-syntax-error)"
printf '%s\n' '[site' 'directory = "../site"' >"${root}/taskr.toml"
run_taskr config_syntax_doctor "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "invalid TOML should make doctor exit 2" >&2; exit 1; }
grep -q 'taskr.toml' "${stderr}"
run_taskr config_syntax_list "${root}" list
[ "${exit_code}" -eq 2 ] || { echo "invalid TOML should block list" >&2; exit 1; }
grep -q 'taskr.toml' "${stderr}"

# Unknown tables and keys fail instead of being ignored as possible typos.
root="$(new_root config-unknown-table)"
printf '%s\n' '[sites]' 'directory = "../site"' >"${root}/taskr.toml"
run_taskr config_unknown_table "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "unknown table should exit 2" >&2; exit 1; }
grep -qi 'unknown.*sites\|sites.*unknown' "${stderr}"
root="$(new_root config-unknown-key)"
printf '%s\n' '[site]' 'director = "../site"' >"${root}/taskr.toml"
run_taskr config_unknown_key "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "unknown key should exit 2" >&2; exit 1; }
grep -qi 'unknown.*director\|director.*unknown' "${stderr}"

# Site configuration requires a nonempty string and rejects item metadata.
root="$(new_root config-empty-directory)"
printf '%s\n' '[site]' 'directory = "   "' >"${root}/taskr.toml"
run_taskr config_empty_directory "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "empty site directory should exit 2" >&2; exit 1; }
grep -qi 'site.*directory\|directory.*empty' "${stderr}"
root="$(new_root config-wrong-type)"
printf '%s\n' '[site]' 'directory = 42' >"${root}/taskr.toml"
run_taskr config_wrong_type "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "non-string site directory should exit 2" >&2; exit 1; }
grep -q 'taskr.toml' "${stderr}"
root="$(new_root config-item-metadata)"
printf '%s\n' 'status = "done"' >"${root}/taskr.toml"
run_taskr config_item_metadata "${root}" doctor
[ "${exit_code}" -eq 2 ] || { echo "item metadata in project config should exit 2" >&2; exit 1; }
grep -qi 'unknown.*status\|status.*unknown' "${stderr}"

# Doctor fix reports invalid TOML without changing the file.
root="$(new_root config-fix-preserves)"
printf '%s\n' '[site]' 'unknown = true' >"${root}/taskr.toml"
before="$(sha256sum "${root}/taskr.toml")"
run_taskr config_fix_preserves "${root}" doctor --fix
[ "${exit_code}" -ne 0 ] || { echo "doctor --fix should reject invalid project config" >&2; exit 1; }
after="$(sha256sum "${root}/taskr.toml")"
[ "${before}" = "${after}" ] || { echo "doctor --fix changed taskr.toml" >&2; exit 1; }
