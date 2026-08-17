#!/usr/bin/env bash
set -euo pipefail


site_checksum() {
  local target="$1"
  find "${target}" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum
}

# Generation requires a site association and points users to site init.
root="$(new_root site-generate-uninitialized -root)"
run_taskr site_generate_uninitialized "${root}" site generate
[ "${exit_code}" -eq 2 ] || { echo "uninitialized generation should exit 2" >&2; exit 1; }
grep -qi 'site init' "${stderr}"

# Initialize one owned target and add representative Markdown and URL content.
root="$(new_root site-generate -root)"
target="${SMOKEY_STATE_DIR}/site-generate-output"
run_taskr site_generate_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
sed -i '/# Outcome/i Visit https://example.com/docs and www.example.org for details.\n' \
  "${root}/001-mvp/003-workflows-definieren/task.md"
printf 'stale output\n' >"${target}/stale.html"

# Successful generation reports one RFC3339 timestamp and replaces stale output.
run_taskr site_generate_success "${root}" site generate
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Eq "^generated site index=${target}/index.html generated_at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" "${stdout}"
generated_at="$(sed -n 's/.* generated_at=//p' "${stdout}")"
[ -f "${target}/index.html" ]
[ -f "${target}/results.html" ]
[ -f "${target}/items/003-workflows-definieren.html" ]
[ -f "${target}/assets/items.js" ]
[ -f "${target}/assets/site.js" ]
grep -qx 'taskr-site-v1' "${target}/.taskr-site"
[ ! -e "${target}/stale.html" ]

# The index is a report-like overview with scoped status and item links.
grep -Fq '<title>site-generate-root - Taskr</title>' "${target}/index.html"
grep -Fq "<time datetime=\"${generated_at}\">${generated_at}</time>" "${target}/index.html"
grep -Fq 'Project status' "${target}/index.html"
grep -Fq 'Milestone: MVP' "${target}/index.html"
grep -Eq 'results\.html\?[^" ]*status=active' "${target}/index.html"
grep -Eq 'results\.html\?[^" ]*milestone=001[^" ]*status=active|results\.html\?[^" ]*status=active[^" ]*milestone=001' "${target}/index.html"
grep -Fq 'items/003-workflows-definieren.html' "${target}/index.html"
grep -Fq 'Define workflows' "${target}/index.html"

# Search and all filters share one URL-driven result page and common table.
grep -Fq 'action="results.html"' "${target}/index.html"
grep -Fq 'name="q"' "${target}/index.html"
grep -Fq 'type="search"' "${target}/index.html"
grep -Fq 'id="result-table"' "${target}/results.html"
grep -Fq 'assets/items.js' "${target}/results.html"
grep -Fq 'assets/site.js' "${target}/results.html"
grep -Fq 'URLSearchParams' "${target}/assets/site.js"
grep -Fq 'pageSize = 25' "${target}/assets/site.js"
grep -Fq 'toLowerCase' "${target}/assets/site.js"
grep -Eq 'replace\(/\^0\+/' "${target}/assets/site.js"
if grep -Eq 'localStorage|sessionStorage' "${target}/assets/site.js"; then
  echo "result context must not use shared browser storage" >&2
  exit 1
fi

# Status filters should default to unfinished work and keep state in the URL.
for status in open designing developing active reviewing blocked done cancelled; do
  grep -Fq "data-status-filter=\"${status}\"" "${target}/index.html"
done
grep -Eq 'data-status-filter="done"[^>]*(checked|aria-checked="true")|(checked|aria-checked="true")[^>]*data-status-filter="done"' "${target}/index.html" && {
  echo "done status filter should be disabled by default" >&2
  exit 1
}
grep -Eq 'data-status-filter="cancelled"[^>]*(checked|aria-checked="true")|(checked|aria-checked="true")[^>]*data-status-filter="cancelled"' "${target}/index.html" && {
  echo "cancelled status filter should be disabled by default" >&2
  exit 1
}
grep -Fq 'data-status-filter="active"' "${target}/index.html"
grep -Eq 'URLSearchParams|history\.replaceState|history\.pushState' "${target}/assets/site.js"
if grep -Eq 'localStorage|sessionStorage' "${target}/assets/site.js"; then
  echo "status filter state must not use shared browser storage" >&2
  exit 1
fi

# The generated item data carries hierarchy and every searchable field.
grep -Fq '"id":"001"' "${target}/assets/items.js"
grep -Fq '"slug":"workflows-definieren"' "${target}/assets/items.js"
grep -Fq '"title":"Define workflows"' "${target}/assets/items.js"
grep -Fq '"milestone":"001"' "${target}/assets/items.js"
grep -Fq '"parent":' "${target}/assets/items.js"

# Client-side status filtering should hide terminal work by default and keep
# milestones visible when they or any descendant match the active filter.
node - "${target}/assets/site.js" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const script = fs.readFileSync(process.argv[2], 'utf8');
const sandbox = { window: { location: { search: '', pathname: '/index.html' } }, history: { replaceState: () => {} }, document: { querySelector: () => null, querySelectorAll: () => [] }, URLSearchParams };
vm.runInNewContext(script, sandbox);
if (typeof sandbox.window.taskrVisibleSiteItems !== 'function') {
  throw new Error('site.js must expose window.taskrVisibleSiteItems for filter tests');
}
const items = [
  { id: '001', type: 'milestone', status: 'done' },
  { id: '002', type: 'task', status: 'developing', parent: '001', milestone: '001' },
  { id: '003', type: 'task', status: 'done', parent: '001', milestone: '001' },
  { id: '004', type: 'milestone', status: 'done' },
  { id: '005', type: 'milestone', status: 'active' },
  { id: '006', type: 'task', status: 'cancelled', parent: '005', milestone: '005' }
];
const ids = params => sandbox.window.taskrVisibleSiteItems(items, new URLSearchParams(params)).map(item => item.id);
const defaults = ids('');
if (!defaults.includes('001') || !defaults.includes('002')) throw new Error('done milestone with visible child should remain visible by default');
if (defaults.includes('003') || defaults.includes('004') || defaults.includes('006')) throw new Error('done/cancelled leaf items and empty done milestones should be hidden by default');
if (!defaults.includes('005')) throw new Error('active milestone should remain visible by default');
const withDone = ids('status=done');
if (!withDone.includes('001') || !withDone.includes('003') || !withDone.includes('004')) throw new Error('explicit done status should show done milestones and done tasks');
if (withDone.includes('002') || withDone.includes('006')) throw new Error('explicit done status should not show non-done leaves');
const withCancelled = ids('status=cancelled');
if (!withCancelled.includes('005') || !withCancelled.includes('006')) throw new Error('milestone with visible cancelled child should remain visible when cancelled is enabled');
NODE

# Item pages contain complete collapsible Markdown and safe external links.
item_page="${target}/items/003-workflows-definieren.html"
grep -Fq '<details' "${item_page}"
grep -Fq 'Description' "${item_page}"
grep -Fq 'Acceptance' "${item_page}"
grep -Fq 'Comments' "${item_page}"
grep -Fq 'Outcome' "${item_page}"
grep -Fq 'Active task with an unfinished child' "${item_page}"
grep -Eq 'href="https://example\.com/docs"[^>]*target="_blank"|target="_blank"[^>]*href="https://example\.com/docs"' "${item_page}"
grep -Eq 'href="https?://www\.example\.org"[^>]*target="_blank"|target="_blank"[^>]*href="https?://www\.example\.org"' "${item_page}"
grep -Fq 'id="previous-result"' "${item_page}"
grep -Fq 'id="next-result"' "${item_page}"
grep -Fq 'data-result-context' "${item_page}"

# More than 25 matching items are represented for client-side pagination.
for number in $(seq -w 1 26); do
  run_taskr "site_generate_create_${number}" "${root}" create task "Search Batch ${number}" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
done
run_taskr site_generate_paged "${root}" site generate
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(grep -o 'Search Batch [0-9][0-9]' "${target}/assets/items.js" | wc -l)" -eq 26 ]
grep -Fq 'pageSize = 25' "${target}/assets/site.js"
grep -Fq 'previous-result' "${target}/assets/site.js"
grep -Fq 'next-result' "${target}/assets/site.js"

# A source error leaves the last successful generated site byte-identical.
before="$(site_checksum "${target}")"
printf '%s\n' 'broken marker' >"${root}/001-mvp/003-workflows-definieren/task.md"
run_taskr site_generate_source_failure "${root}" site generate
[ "${exit_code}" -ne 0 ] || { echo "invalid source should block generation" >&2; exit 1; }
[ "${before}" = "$(site_checksum "${target}")" ]

# Missing and empty configured targets are not silently reclaimed by generate.
root="$(new_root site-generate-missing-target -root)"
target="${SMOKEY_STATE_DIR}/site-generate-missing-output"
run_taskr site_generate_missing_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
rm -rf "${target}"
run_taskr site_generate_missing_target "${root}" site generate
[ "${exit_code}" -eq 2 ] || { echo "missing configured target should exit 2" >&2; exit 1; }
[ ! -e "${target}" ]
grep -qi 'site init\|missing\|ownership' "${stderr}"

root="$(new_root site-generate-empty-target -root)"
target="${SMOKEY_STATE_DIR}/site-generate-empty-output"
run_taskr site_generate_empty_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
rm "${target}/.taskr-site"
run_taskr site_generate_empty_target "${root}" site generate
[ "${exit_code}" -eq 2 ] || { echo "unowned empty target should exit 2" >&2; exit 1; }
grep -qi 'site init\|ownership\|marker' "${stderr}"

# A foreign configured target remains untouched when generation is rejected.
root="$(new_root site-generate-foreign-target -root)"
target="${SMOKEY_STATE_DIR}/site-generate-foreign-output"
mkdir -p "${target}"
printf 'foreign\n' >"${target}/keep.txt"
printf '[site]\ndirectory = "%s"\n' "${target}" >"${root}/taskr.toml"
run_taskr site_generate_foreign_target "${root}" site generate
[ "${exit_code}" -eq 2 ] || { echo "foreign target should exit 2" >&2; exit 1; }
grep -qx 'foreign' "${target}/keep.txt"

# Help, examples, and completion expose the generation command.
run_taskr site_generate_help site generate --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'site generate' "${stdout}"
run_taskr site_generate_examples examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr site generate' "${stdout}"
run_taskr site_generate_completion __complete site generate ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q ':4$' "${stdout}"
