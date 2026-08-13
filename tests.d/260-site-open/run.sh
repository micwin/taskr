#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"
OPEN_PIDS=""

cleanup_processes() {
  for pid in ${OPEN_PIDS}; do
    kill -TERM "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
  done
}
trap cleanup_processes EXIT

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

free_port() {
  node -e 'const s=require("net").createServer();s.listen(0,"127.0.0.1",()=>{console.log(s.address().port);s.close()})'
}

start_open() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  "$@" >"${stdout}" 2>"${stderr}" &
  open_pid=$!
  OPEN_PIDS="${OPEN_PIDS} ${open_pid}"
}

wait_for_pattern() {
  local pattern="$1"
  local file="$2"
  for _ in $(seq 1 100); do
    if grep -Eq "${pattern}" "${file}" 2>/dev/null; then
      return 0
    fi
    sleep 0.05
  done
  echo "timed out waiting for ${pattern} in ${file}" >&2
  cat "${file}" >&2 2>/dev/null || true
  return 1
}

wait_for_http() {
  local pattern="$1"
  local url="$2"
  local output="$3"
  for _ in $(seq 1 100); do
    if curl --fail --silent "${url}" >"${output}" 2>/dev/null && grep -Fq "${pattern}" "${output}"; then
      return 0
    fi
    sleep 0.05
  done
  echo "timed out waiting for ${pattern} at ${url}" >&2
  return 1
}

stop_open() {
  local pid="$1"
  kill -INT "${pid}"
  set +e
  wait "${pid}"
  stopped_code=$?
  set -e
  OPEN_PIDS=" ${OPEN_PIDS// ${pid}/}"
}

# Open requires an initialized site and an existing generated index by default.
root="$(new_root site-open-uninitialized)"
run_taskr site_open_uninitialized "${root}" site open --no-browser
[ "${exit_code}" -eq 2 ] || { echo "uninitialized site open should exit 2" >&2; exit 1; }
grep -qi 'site init' "${stderr}"

root="$(new_root site-open-missing-index)"
target="${SMOKEY_STATE_DIR}/site-open-missing-index-output"
run_taskr site_open_missing_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr site_open_missing_index "${root}" site open --no-browser
[ "${exit_code}" -eq 2 ] || { echo "missing index should exit 2" >&2; exit 1; }
grep -qi 'site generate\|regenerate' "${stderr}"

# Normal open serves existing output, prints the complete URL, and does not regenerate.
root="$(new_root site-open-normal)"
target="${SMOKEY_STATE_DIR}/site-open-normal-output"
run_taskr site_open_normal_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr site_open_normal_generate "${root}" site generate
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
before_index="$(sha256sum "${target}/index.html")"
port="$(free_port)"
start_open site_open_normal "${TASKR_BIN}" "${root}" site open --no-browser --port "${port}"
pid="${open_pid}"
wait_for_pattern "url=http://127\\.0\\.0\\.1:${port}/index\\.html" "${stdout}"
url="http://127.0.0.1:${port}/index.html"
wait_for_http 'site-open-normal-root - Taskr' "${url}" "${SMOKEY_STATE_DIR}/site-open-normal.html"
[ "${before_index}" = "$(sha256sum "${target}/index.html")" ]
if grep -q '__taskr_reload' "${SMOKEY_STATE_DIR}/site-open-normal.html"; then
  echo "normal open must not inject watch reload behavior" >&2
  exit 1
fi
stop_open "${pid}"
[ "${stopped_code}" -eq 0 ] || { echo "Ctrl-C should stop site open successfully" >&2; exit 1; }

# Positional terms open the shared result view using the site's search semantics.
port="$(free_port)"
start_open site_open_search "${TASKR_BIN}" "${root}" site open Define workflows --no-browser --port "${port}"
pid="${open_pid}"
wait_for_pattern "url=http://127\\.0\\.0\\.1:${port}/results\\.html\\?q=Define\\+workflows" "${stdout}"
wait_for_http 'id="result-table"' "http://127.0.0.1:${port}/results.html?q=Define+workflows" "${SMOKEY_STATE_DIR}/site-open-search.html"
stop_open "${pid}"
[ "${stopped_code}" -eq 0 ]

# Regenerate creates a missing index before serving it.
root="$(new_root site-open-regenerate)"
target="${SMOKEY_STATE_DIR}/site-open-regenerate-output"
run_taskr site_open_regenerate_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
port="$(free_port)"
start_open site_open_regenerate "${TASKR_BIN}" "${root}" site open --regenerate --no-browser --port "${port}"
pid="${open_pid}"
wait_for_pattern "url=http://127\\.0\\.0\\.1:${port}/index\\.html" "${stdout}"
[ -f "${target}/index.html" ]
wait_for_http 'site-open-regenerate-root - Taskr' "http://127.0.0.1:${port}/index.html" "${SMOKEY_STATE_DIR}/site-open-regenerate.html"
stop_open "${pid}"
[ "${stopped_code}" -eq 0 ]

# Personal browser configuration wins, supports arguments and controls URL position.
browser_log="${SMOKEY_STATE_DIR}/browser.log"
fake_browser="${SMOKEY_STATE_DIR}/fake-browser.sh"
cat >"${fake_browser}" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${BROWSER_LOG}"
EOF
chmod +x "${fake_browser}"
config="${SMOKEY_STATE_DIR}/site-open-browser.yaml"
printf 'browser: "bash %s before {url} after"\n' "${fake_browser}" >"${config}"
port="$(free_port)"
start_open site_open_configured_browser env BROWSER='definitely-missing-fallback' BROWSER_LOG="${browser_log}" "${TASKR_BIN}" "${root}" --config-file "${config}" site open --port "${port}"
pid="${open_pid}"
wait_for_pattern "url=http://127\\.0\\.0\\.1:${port}/index\\.html" "${stdout}"
wait_for_pattern '^before$' "${browser_log}"
sed -n '1p' "${browser_log}" | grep -qx 'before'
sed -n '2p' "${browser_log}" | grep -qx "http://127.0.0.1:${port}/index.html"
sed -n '3p' "${browser_log}" | grep -qx 'after'
stop_open "${pid}"
[ "${stopped_code}" -eq 0 ]

# Invalid explicit browser configuration fails fast without using BROWSER.
printf 'browser: "definitely-missing-configured-browser"\n' >"${config}"
rm -f "${browser_log}"
stdout="${SMOKEY_STATE_DIR}/site_open_invalid_browser.stdout"
stderr="${SMOKEY_STATE_DIR}/site_open_invalid_browser.stderr"
set +e
env BROWSER="bash ${fake_browser} fallback {url}" BROWSER_LOG="${browser_log}" "${TASKR_BIN}" "${root}" --config-file "${config}" site open --port "$(free_port)" >"${stdout}" 2>"${stderr}"
exit_code=$?
set -e
[ "${exit_code}" -ne 0 ] || { echo "invalid configured browser should fail" >&2; exit 1; }
[ ! -e "${browser_log}" ]
grep -qi 'browser\|executable\|not found' "${stderr}"

# BROWSER is used when personal configuration omits browser and appends URL by default.
config="${SMOKEY_STATE_DIR}/site-open-no-browser-config.yaml"
printf 'editor: "true"\n' >"${config}"
rm -f "${browser_log}"
port="$(free_port)"
start_open site_open_env_browser env BROWSER="bash ${fake_browser} from-env" BROWSER_LOG="${browser_log}" "${TASKR_BIN}" "${root}" --config-file "${config}" site open --port "${port}"
pid="${open_pid}"
wait_for_pattern '^from-env$' "${browser_log}"
sed -n '2p' "${browser_log}" | grep -qx "http://127.0.0.1:${port}/index.html"
stop_open "${pid}"
[ "${stopped_code}" -eq 0 ]

# An explicitly occupied port fails instead of selecting another port.
port="$(free_port)"
node -e 'require("net").createServer().listen(Number(process.argv[1]),"127.0.0.1")' "${port}" &
blocker_pid=$!
OPEN_PIDS="${OPEN_PIDS} ${blocker_pid}"
sleep 0.1
run_taskr site_open_port_conflict "${root}" site open --no-browser --port "${port}"
[ "${exit_code}" -ne 0 ] || { echo "occupied explicit port should fail" >&2; exit 1; }
grep -qi 'port\|address.*use\|bind' "${stderr}"
kill -TERM "${blocker_pid}"
wait "${blocker_pid}" 2>/dev/null || true
OPEN_PIDS=" ${OPEN_PIDS// ${blocker_pid}/}"

# Watch serves reload support and regenerates after relevant marker changes.
root="$(new_root site-open-watch)"
target="${SMOKEY_STATE_DIR}/site-open-watch-output"
run_taskr site_open_watch_init "${root}" site init "${target}" --create-if-missing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr site_open_watch_generate "${root}" site generate
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
port="$(free_port)"
start_open site_open_watch "${TASKR_BIN}" "${root}" site open --watch --no-browser --port "${port}"
pid="${open_pid}"
wait_for_pattern "url=http://127\\.0\\.0\\.1:${port}/index\\.html" "${stdout}"
watch_url="http://127.0.0.1:${port}"
wait_for_http '__taskr_reload' "${watch_url}/index.html" "${SMOKEY_STATE_DIR}/site-open-watch.html"
sed -i 's/title: Open work/title: Open refreshed work/' "${root}/001-mvp/005-open-work/task.md"
wait_for_http 'Open refreshed work' "${watch_url}/items/005-open-work.html" "${SMOKEY_STATE_DIR}/site-open-watch-refreshed.html"
wait_for_pattern 'regenerated' "${stdout}"

# Failed watch regeneration preserves the last successful page and suppresses reload.
marker="${root}/001-mvp/005-open-work/task.md"
valid_marker="$(cat "${marker}")"
printf 'broken marker\n' >"${marker}"
wait_for_pattern 'regeneration.*failed\|failed.*regenerat' "${stderr}"
curl --fail --silent "${watch_url}/items/005-open-work.html" >"${SMOKEY_STATE_DIR}/site-open-watch-stale.html"
grep -q 'Open refreshed work' "${SMOKEY_STATE_DIR}/site-open-watch-stale.html"
kill -0 "${pid}"
printf '%s' "${valid_marker}" >"${marker}"
sleep 0.6

# Changing taskr.toml to another site root stops watch with an error.
other_target="${SMOKEY_STATE_DIR}/site-open-watch-other-output"
mkdir -p "${other_target}"
printf 'taskr-site-v1\n' >"${other_target}/.taskr-site"
printf '[site]\ndirectory = "%s"\n' "${other_target}" >"${root}/taskr.toml"
for _ in $(seq 1 100); do
  if ! kill -0 "${pid}" 2>/dev/null; then
    break
  fi
  sleep 0.05
done
if kill -0 "${pid}" 2>/dev/null; then
  echo "watch should stop after configured site directory changes" >&2
  exit 1
fi
set +e
wait "${pid}"
watch_exit=$?
set -e
OPEN_PIDS=" ${OPEN_PIDS// ${pid}/}"
[ "${watch_exit}" -ne 0 ] || { echo "changed site directory should fail watch" >&2; exit 1; }
grep -qi 'site.*director\|server root\|ownership' "${stderr}"

# Help, examples, and completion expose the final open surface.
run_taskr site_open_help site open --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'site open' "${stdout}"
grep -q -- '--regenerate' "${stdout}"
grep -q -- '--watch' "${stdout}"
grep -q -- '--port' "${stdout}"
grep -q -- '--no-browser' "${stdout}"
grep -q 'site open \[search terms' "${stdout}"
run_taskr site_open_examples examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr site open' "${stdout}"
run_taskr site_open_completion __complete site open ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q ':4$' "${stdout}"
