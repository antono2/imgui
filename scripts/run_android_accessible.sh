#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}
mode=${1:-run}
if [[ "$mode" != run && "$mode" != --build-only ]]; then
  echo 'Usage: scripts/run_android_accessible.sh [--build-only]' >&2; exit 2
fi
if [[ ! -x "$sdk/platform-tools/adb" || ! -f "$ndk/build/cmake/android.toolchain.cmake" ]]; then
  echo 'Set ANDROID_SDK_ROOT and ANDROID_NDK_HOME.' >&2; exit 2
fi
adb=("$sdk/platform-tools/adb")
if [[ -n ${ANDROID_SERIAL:-} ]]; then adb+=(-s "$ANDROID_SERIAL"); fi
abi=${ANDROID_ABI:-}
if [[ -z "$abi" && "$mode" == run ]]; then abi=$("${adb[@]}" shell getprop ro.product.cpu.abi | tr -d '\r'); fi
case "$abi" in
  armeabi-v7a) ;;
  arm64-v8a) ;;
  x86_64) ;;
  *) echo 'Set ANDROID_ABI to a supported ABI.' >&2; exit 2 ;;
esac
build=$repo_root/build/android-accessible-$abi
cmake -S "$repo_root" -B "$build" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="$abi" -DANDROID_PLATFORM=android-24 -DANDROID_STL=c++_static \
  -DVIMGUI_PROFILE=android-vulkan -DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=Release \
  -DVIMGUI_APPLICATION_UI=ON -DVIMGUI_BUILD_ANDROID_DEMO=ON -DVIMGUI_ANDROID_ACCESSIBLE_DEMO=ON
cmake --build "$build" --target vimgui_android_demo --parallel 2
build_tools=$(printf '%s\n' "$sdk"/build-tools/* | sort -V | tail -n 1)
android_jar=$(printf '%s\n' "$sdk"/platforms/*/android.jar | sort -V | tail -n 1)
package=$build/package
rm -rf -- "$package/classes" "$package/dex"
mkdir -p "$package/lib/$abi" "$package/assets" "$package/classes" "$package/dex"
cp "$build/lib/libvimgui.so" "$package/lib/$abi/libvimgui.so"
cp "$build/libvimgui_android_demo.so" "$package/lib/$abi/libvimgui_android_demo.so"
cp "$repo_root/cimgui/imgui/misc/fonts/Roboto-Medium.ttf" "$package/assets/Roboto-Medium.ttf"
"${JAVAC:-javac}" -source 8 -target 8 -Xlint:-options -cp "$android_jar" -d "$package/classes" \
  "$repo_root/android/java/io/antono2/imgui/ImGuiInputView.java" \
  "$repo_root/android/java/io/antono2/imgui/ImGuiAccessibility.java" \
  "$repo_root/examples/android_vulkan/java/io/antono2/vimgui/demo/ImGuiActivity.java"
mapfile -d '' class_files < <(find "$package/classes" -name '*.class' -print0)
"$build_tools/d8" --min-api 24 --lib "$android_jar" --output "$package/dex" "${class_files[@]}"
cp "$package/dex/classes.dex" "$package/classes.dex"
unsigned=$build/accessible-unsigned.apk
aligned=$build/accessible-aligned.apk
signed=$build/accessible-$abi.apk
"$build_tools/aapt" package -f -M "$repo_root/examples/android_accessible/AndroidManifest.xml" \
  -I "$android_jar" -A "$package/assets" -F "$unsigned"
(
  cd "$package"
  "$build_tools/aapt" add "$unsigned" "lib/$abi/libvimgui.so" "lib/$abi/libvimgui_android_demo.so" classes.dex
)
"$build_tools/zipalign" -f 4 "$unsigned" "$aligned"
keystore=$build/debug.keystore
if [[ ! -f "$keystore" ]]; then
  keytool -genkeypair -keystore "$keystore" -storepass android -keypass android -alias androiddebugkey \
    -dname 'CN=Android Debug,O=Android,C=US' -validity 3650 -keyalg RSA -keysize 2048 -noprompt
fi
"$build_tools/apksigner" sign --ks "$keystore" --ks-pass pass:android --key-pass pass:android --out "$signed" "$aligned"
"$build_tools/apksigner" verify "$signed"
printf 'APK: %s\n' "$signed"
if [[ "$mode" == run ]]; then
  "${adb[@]}" install -r "$signed"
  "${adb[@]}" shell am start -n io.antono2.vimgui.accessible/io.antono2.vimgui.demo.ImGuiActivity
fi
