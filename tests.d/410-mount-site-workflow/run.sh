#!/usr/bin/env bash
set -euo pipefail

make_site_mount_target() {
  local name="$1"
  local root="${SMOKEY_STATE_DIR}/${name}/taskr"
  mkdir -p "${root}"
  run_taskr "init_${name}" "${root}" init
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "site_target_${name}_milestone" "${root}" create milestone "Mounted Roadmap" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "site_target_${name}_task" "${root}" create task "Mounted Task" --under 001 --status developing --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  run_taskr "site_target_${name}_subtask" "${root}" create subtask "Mounted Subtask" --under 002 --status reviewing --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  sed -i '/^status: developing/a tags: [external]' "${root}/001-mounted-roadmap/002-mounted-task/task.md"
  sed -i '/# Acceptance/i Visit https://example.com/mounted and www.example.org/mounted.\n' "${root}/001-mounted-roadmap/002-mounted-task/task.md"
  printf '%s\n' "${root}"
}

create_mount_site_fixture() {
  local name="$1"
  local root
  local vendor_target
  local archive_target
  local lib_target
  root="$(new_root "${name}")"
  vendor_target="$(make_site_mount_target "${name}-vendor-target")"
  archive_target="$(make_site_mount_target "${name}-archive-target")"
  lib_target="$(make_site_mount_target "${name}-lib-target")"
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

root="$(create_mount_site_fixture mount-site-root)"
target="${SMOKEY_STATE_DIR}/mount-site-output"
run_taskr mount_site_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Ticket 117: generated site data includes mount objects and mounted items.
run_taskr mount_site_generate "${root}" site generate
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^generated site index=${target}/index.html" "${stdout}"
grep -Fq '"id":"vendor"' "${target}/assets/items.js"
grep -Fq '"type":"mount"' "${target}/assets/items.js"
grep -Fq '"mode":"read-only"' "${target}/assets/items.js"
grep -Fq '"id":"archive"' "${target}/assets/items.js"
grep -Fq '"mode":"read-write"' "${target}/assets/items.js"
grep -Fq '"id":"vendor:001"' "${target}/assets/items.js"
grep -Fq '"id":"vendor:002"' "${target}/assets/items.js"
grep -Fq '"id":"vendor:003"' "${target}/assets/items.js"
grep -Fq '"id":"vendor:lib"' "${target}/assets/items.js"
grep -Fq '"id":"vendor:lib:001"' "${target}/assets/items.js"

# Ticket 117: overview displays mounted roots and mounted items with source identity.
grep -Fq 'Mounted roots' "${target}/index.html"
grep -Fq 'Vendor Project' "${target}/index.html"
grep -Fq 'Library Project' "${target}/index.html"
grep -Fq 'Archive Project' "${target}/index.html"
grep -Fq 'vendor:002' "${target}/index.html"
grep -Fq 'Mounted Task' "${target}/index.html"

# Ticket 117: mounted IDs link to items and expose mount-id segments as filters.
grep -Eq 'href="items/vendor-002-mounted-task\.html"[^>]*>vendor:002|>vendor:002</a>' "${target}/index.html"
grep -Eq 'href="results\.html\?[^"]*mount=vendor[^"]*"[^>]*>vendor</a>' "${target}/index.html"
grep -Eq 'href="results\.html\?[^"]*mount=vendor%3Alib|href="results\.html\?[^"]*mount=vendor:lib' "${target}/index.html"
grep -Fq 'data-mount-filter-link' "${target}/index.html"
grep -Fq 'data-mount-filter-link' "${target}/results.html"

# Ticket 117: generated item pages for mounted items show source and navigation context.
item_page="${target}/items/vendor-002-mounted-task.html"
[ -f "${item_page}" ]
grep -Fq 'Source: vendor (Vendor Project)' "${item_page}"
grep -Fq 'vendor:002' "${item_page}"
grep -Eq 'href="\.\./results\.html\?[^"]*mount=vendor[^"]*"' "${item_page}"
grep -Eq 'href="https://example\.com/mounted"[^>]*target="_blank"|target="_blank"[^>]*href="https://example\.com/mounted"' "${item_page}"
grep -Eq 'href="https?://www\.example\.org/mounted"[^>]*target="_blank"|target="_blank"[^>]*href="https?://www\.example\.org/mounted"' "${item_page}"
grep -Fq 'id="previous-result"' "${item_page}"
grep -Fq 'id="next-result"' "${item_page}"
grep -Fq 'data-result-context' "${item_page}"

# Ticket 117: search and filters include mounted IDs, slugs, titles, tags, and statuses.
node - "${target}/assets/site.js" "${target}/assets/items.js" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const siteScript = fs.readFileSync(process.argv[2], 'utf8');
const itemScript = fs.readFileSync(process.argv[3], 'utf8');
const sandbox = { window: { location: { search: '', pathname: '/results.html' } }, history: { replaceState: () => {}, pushState: () => {} }, document: { querySelector: () => null, querySelectorAll: () => [] }, URLSearchParams };
vm.runInNewContext(itemScript, sandbox);
vm.runInNewContext(siteScript, sandbox);
if (typeof sandbox.window.taskrSearchSiteItems !== 'function') throw new Error('site.js must expose taskrSearchSiteItems');
if (typeof sandbox.window.taskrVisibleSiteItems !== 'function') throw new Error('site.js must expose taskrVisibleSiteItems');
const items = sandbox.window.taskrItems;
const search = params => sandbox.window.taskrSearchSiteItems(items, new URLSearchParams(params)).map(item => item.id);
const visible = params => sandbox.window.taskrVisibleSiteItems(items, new URLSearchParams(params)).map(item => item.id);
if (!search('q=vendor:2').includes('vendor:002')) throw new Error('search should match mounted IDs without leading zeroes');
if (!search('q=mounted-task').includes('vendor:002')) throw new Error('search should match mounted slugs');
if (!search('q=Mounted%20Task').includes('archive:002')) throw new Error('search should match mounted titles');
if (!search('q=%23external').includes('vendor:002')) throw new Error('search should match mounted tags');
const vendor = visible('mount=vendor');
for (const id of ['vendor:001', 'vendor:002', 'vendor:003', 'vendor:lib', 'vendor:lib:001', 'vendor:lib:002', 'vendor:lib:003']) {
  if (!vendor.includes(id)) throw new Error(`mount=vendor should include ${id}`);
}
if (vendor.includes('archive:001') || vendor.includes('001')) throw new Error('mount=vendor should exclude archive and local items');
const vendorDeveloping = visible('mount=vendor&status=developing');
if (!vendorDeveloping.includes('vendor:001') || !vendorDeveloping.includes('vendor:002')) throw new Error('mount+status should keep ancestor milestone and matching task');
if (vendorDeveloping.includes('vendor:003')) throw new Error('mount+status should exclude non-matching leaves');
const external = visible('tags=external');
if (!external.includes('vendor:002') || !external.includes('archive:002')) throw new Error('tag filter should include mounted items');
NODE

# Ticket 117: mount filter context lives in URLs, not shared browser storage.
grep -Fq 'URLSearchParams' "${target}/assets/site.js"
grep -Fq 'mount=' "${target}/assets/site.js"
if grep -Eq 'localStorage|sessionStorage' "${target}/assets/site.js"; then
  echo "mount result context must not use shared browser storage" >&2
  exit 1
fi

# Ticket 117: unavailable and cyclic mounts fail generation clearly.
bad_root="$(new_root mount-site-unavailable-root)"
bad_target="${SMOKEY_STATE_DIR}/mount-site-unavailable-output"
run_taskr mount_site_bad_init "${bad_root}" site init "${bad_target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
cat >"${bad_root}/taskr.toml" <<EOF
[[mounts]]
id = "missing"
name = "Missing Project"
path = "${SMOKEY_STATE_DIR}/missing-site-mounted-root"
mode = "read-only"
EOF
run_taskr mount_site_unavailable "${bad_root}" site generate
[ "${exit_code}" -ne 0 ] || { echo "unavailable mount should fail site generate" >&2; exit 1; }
grep -qi 'missing\|mount\|path\|read' "${stderr}"

cycle_root="$(new_root mount-site-cycle-root)"
cycle_target="$(make_site_mount_target mount-site-cycle-target)"
cycle_output="${SMOKEY_STATE_DIR}/mount-site-cycle-output"
run_taskr mount_site_cycle_init "${cycle_root}" site init "${cycle_output}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
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
run_taskr mount_site_cycle "${cycle_root}" site generate
[ "${exit_code}" -ne 0 ] || { echo "cyclic mounts should fail site generate" >&2; exit 1; }
grep -qi 'cycle\|cyclic\|recursive\|mount' "${stderr}"

# Ticket 117: help and examples cover generated sites with mounts.
run_taskr mount_site_generate_help "${root}" site generate --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted' "${stdout}"
run_taskr mount_site_open_help "${root}" site open --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'mount\|mounted' "${stdout}"
run_taskr mount_site_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr site generate' "${stdout}"
grep -qi 'mounted roots' "${stdout}"
