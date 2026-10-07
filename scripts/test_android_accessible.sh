#!/usr/bin/env bash
# Runs device-side accessibility checks against the Android example.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
adb=("$sdk/platform-tools/adb")
if [[ -n ${ANDROID_SERIAL:-} ]]; then adb+=(-s "$ANDROID_SERIAL"); fi
abi=${ANDROID_ABI:-$("${adb[@]}" shell getprop ro.product.cpu.abi | tr -d '\r')}
ANDROID_ABI=$abi bash "$repo_root/scripts/run_android_accessible.sh" --build-only
build=$repo_root/build/android-accessible-$abi
build_tools=$(printf '%s\n' "$sdk"/build-tools/* | sort -V | tail -n 1)
android_jar=$(printf '%s\n' "$sdk"/platforms/*/android.jar | sort -V | tail -n 1)
package=$build/test-package
mkdir -p "$package/classes" "$package/dex"
"${JAVAC:-javac}" -source 8 -target 8 -Xlint:-options -cp "$android_jar" -d "$package/classes" \
  "$repo_root/tests/android/accessibility/AccessibilitySmoke.java"
mapfile -d '' class_files < <(find "$package/classes" -name '*.class' -print0)
"$build_tools/d8" --min-api 24 --lib "$android_jar" --output "$package/dex" "${class_files[@]}"
"$build_tools/aapt" package -f -M "$repo_root/tests/android/accessibility/AndroidManifest.xml" \
  -I "$android_jar" -F "$package/unsigned.apk"
(cd "$package/dex"; "$build_tools/aapt" add "$package/unsigned.apk" classes.dex)
"$build_tools/zipalign" -f 4 "$package/unsigned.apk" "$package/aligned.apk"
"$build_tools/apksigner" sign --ks "$build/debug.keystore" --ks-pass pass:android --key-pass pass:android \
  --out "$package/test.apk" "$package/aligned.apk"
"$build_tools/apksigner" verify "$package/test.apk"
"${adb[@]}" install -r "$build/accessible-$abi.apk"
"${adb[@]}" install -r "$package/test.apk"
"${adb[@]}" shell input keyevent 224
"${adb[@]}" shell wm dismiss-keyguard
"${adb[@]}" shell am instrument -w \
  io.antono2.vimgui.accessible.test/io.antono2.vimgui.accessible.test.AccessibilitySmoke | tee "$build/instrumentation.log"
rg -q 'result=PASS:' "$build/instrumentation.log"
