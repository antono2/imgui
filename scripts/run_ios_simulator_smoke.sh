#!/usr/bin/env bash
# Builds and runs the iOS simulator smoke checks when an appropriate runtime is available.
set -euo pipefail

app_bundle="${1:-}"
if [[ -z "$app_bundle" || ! -d "$app_bundle" ]]; then
  echo 'Usage: scripts/run_ios_simulator_smoke.sh path/to/vimgui_ios_demo.app' >&2
  exit 2
fi

device_id="$(xcrun simctl list devices available | sed -nE '/iPhone/s/.*\(([0-9A-Fa-f-]{36})\).*/\1/p' | sed -n '1p')"
if [[ -z "$device_id" ]]; then
  echo '::warning::No available iPhone Simulator runtime; compile/link checks passed.'
  exit 0
fi

if ! xcrun simctl boot "$device_id"; then
  echo '::warning::Could not boot the selected iPhone Simulator.'
  exit 1
fi
trap 'xcrun simctl shutdown "$device_id" >/dev/null 2>&1 || true' EXIT
xcrun simctl bootstatus "$device_id" -b
codesign --force --sign - "$app_bundle/Frameworks/libvimgui.dylib"
codesign --force --sign - "$app_bundle"
xcrun simctl install "$device_id" "$app_bundle"
container="$(xcrun simctl get_app_container "$device_id" io.antono2.vimgui.ios-demo data)"
status_file="$container/tmp/vimgui-metal-status.txt"
run_smoke() {
  local argument="$1" expected="$2" status
  rm -f "$status_file"
  xcrun simctl launch "$device_id" io.antono2.vimgui.ios-demo "$argument"
  for _ in $(seq 1 30); do
    if [[ -f "$status_file" ]]; then
      status="$(<"$status_file")"
      echo "iOS Simulator Metal status: $status"
      if [[ "$status" == "$expected" ]]; then return 0; fi
      return 1
    fi
    sleep 1
  done
  echo "::warning::iOS Simulator $argument launched but no frame status was reported."
  return 1
}

run_smoke --keyboard-smoke keyboard_input_frame_completed
xcrun simctl terminate "$device_id" io.antono2.vimgui.ios-demo
run_smoke --composition-smoke composition_frame_completed
xcrun simctl terminate "$device_id" io.antono2.vimgui.ios-demo
run_smoke --overflow-smoke overflow_fallback_frame_completed
