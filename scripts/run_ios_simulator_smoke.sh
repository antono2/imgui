#!/usr/bin/env bash
set -euo pipefail

app_bundle="${1:-}"
if [[ -z "$app_bundle" || ! -d "$app_bundle" ]]; then
  echo 'Usage: scripts/run_ios_simulator_smoke.sh path/to/vimgui_ios_demo.app' >&2
  exit 2
fi

device_id="$(xcrun simctl list -j devices available | python3 -c '
import json, sys
devices = [device for group in json.load(sys.stdin)["devices"].values() for device in group]
phones = [device for device in devices if device["name"].startswith("iPhone")]
print(phones[0]["udid"] if phones else "")
')"
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
rm -f "$status_file"
xcrun simctl launch "$device_id" io.antono2.vimgui.ios-demo --keyboard-smoke
for _ in $(seq 1 30); do
  if [[ -f "$status_file" ]]; then
    status="$(<"$status_file")"
    echo "iOS Simulator Metal status: $status"
    if [[ "$status" == keyboard_input_frame_completed ]]; then exit 0; fi
    exit 1
  fi
  sleep 1
done
echo '::warning::iOS Simulator launched but no keyboard/Metal frame status was reported.'
exit 1
