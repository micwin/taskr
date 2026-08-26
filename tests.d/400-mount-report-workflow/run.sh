#!/usr/bin/env bash
set -euo pipefail

make_report_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "report_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "report_target_${name}_developing" "${root}" create task "Mounted Developing Task" --under 001 --status developing --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "report_target_${name}_reviewing" "${root}" create task "Mounted Reviewing Task" --under 001 --status reviewing --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "report_target_${name}_done" "${root}" create task "Mounted Done Task" --under 001 --status open --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "report_target_${name}_done_status" "${root}" status 004 done
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  sed -i '/^status: developing/a priority: high\ntags: [external]' "${root}/001-mounted-roadmap/002-mounted-developing-task/task.md"
  sed -i '/^status: reviewing/a priority: low\ntags: [external,review]' "${root}/001-mounted-roadmap/003-mounted-reviewing-task/task.md"
  printf '%s\n' "${root}"
}

create_mount_report_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  root="$(new_root "${name}")"
  vendor_target="$(make_report_mount_target "${name}-vendor-target")"
  archive_target="$(make_report_mount_target "${name}-archive-target")"
  lib_target="$(make_report_mount_target "${name}-lib-target")"
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

root="$(create_mount_report_fixture mount-report-root)"

# Ticket 116: default report includes a dedicated mounted roots section.
run_taskr mount_report_default "${root}" report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Taskr report$' "${stdout}"
grep -q '^# Mounted Roots$' "${stdout}"
grep -q '^vendor \[mount read-only\] Vendor Project$' "${stdout}"
grep -q '^vendor:lib \[mount read-only\] Library Project$' "${stdout}"
grep -q '^archive \[mount read-write\] Archive Project$' "${stdout}"

# Ticket 116: status summaries include mounted items with source-qualified rows.
grep -q '^tasks with status "developing": 3$' "${stdout}"
grep -q '^tasks with status "reviewing": 3$' "${stdout}"
grep -q '^tasks with status "done": 4$' "${stdout}"
grep -Fqx 'vendor:002 [developing] #external priority=high Mounted Developing Task' "${stdout}"
grep -Fqx 'vendor:003 [reviewing] #(external,review) priority=low Mounted Reviewing Task' "${stdout}"
grep -Fqx 'archive:002 [developing] #external priority=high Mounted Developing Task' "${stdout}"
grep -Fqx 'vendor:lib:002 [developing] #external priority=high Mounted Developing Task' "${stdout}"

# Ticket 116: local and mounted numeric IDs stay distinguishable in the report.
grep -Fqx '002 [done] #internal Define directory structure' "${stdout}"
grep -Fqx 'vendor:002 [developing] #external priority=high Mounted Developing Task' "${stdout}"
grep -Fqx 'archive:002 [developing] #external priority=high Mounted Developing Task' "${stdout}"

# Ticket 116: priority and tag summaries include mounted items.
grep -q '^tasks with priority "high": 3$' "${stdout}"
grep -q '^tasks with priority "low": 3$' "${stdout}"
grep -q '^items with tag "external": 6$' "${stdout}"
grep -q '^items with tag "review": 3$' "${stdout}"

# Ticket 116: mounted milestone sections retain source identity.
grep -Fqx '## Mounted Roadmap (vendor:mounted-roadmap) [open]' "${stdout}"
grep -Fqx '## Mounted Roadmap (archive:mounted-roadmap) [open]' "${stdout}"
grep -Fqx '## Mounted Roadmap (vendor:lib:mounted-roadmap) [open]' "${stdout}"

# Ticket 116: file report output matches the mounted report content.
target="${SMOKEY_STATE_DIR}/mount-report.txt"
run_taskr mount_report_file "${root}" report --output "${target}"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "wrote report path=${target}" "${stdout}"
grep -q '^# Mounted Roots$' "${target}"
grep -q '^vendor \[mount read-only\] Vendor Project$' "${target}"
grep -Fqx 'vendor:002 [developing] #external priority=high Mounted Developing Task' "${target}"

# Ticket 116: the generated site's report-like overview uses the same mounted report data.
site_target="${SMOKEY_STATE_DIR}/mount-report-site"
run_taskr mount_report_site_init "${root}" site init "${site_target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr mount_report_site_generate "${root}" site generate
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^generated site index=' "${stdout}"
grep -Fq 'Mounted roots' "${site_target}/index.html"
grep -Fq 'vendor [mount read-only] Vendor Project' "${site_target}/index.html"
grep -Fq 'vendor:lib [mount read-only] Library Project' "${site_target}/index.html"
grep -Fq 'archive [mount read-write] Archive Project' "${site_target}/index.html"
grep -Fq 'tasks with status "developing": 3' "${site_target}/index.html"
grep -Fq 'tasks with priority "high": 3' "${site_target}/index.html"
grep -Fq 'items with tag "external": 6' "${site_target}/index.html"
grep -Fq 'vendor:002' "${site_target}/index.html"

# Ticket 116: unavailable mounts fail clearly instead of creating partial reports.
bad_root="$(new_root mount-report-unavailable)"
cat >"${bad_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-report-mounted-root"
mode = "read-only"
EOF
run_taskr mount_report_unavailable "${bad_root}" report
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail report" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

# Ticket 116: help and examples cover mounted report output.
run_taskr mount_report_help "${root}" report --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted' "${stdout}"
run_taskr mount_report_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr report' "${stdout}"
grep -qi 'mounted roots' "${stdout}"
