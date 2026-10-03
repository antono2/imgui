#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ndk_dir="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
sdk_dir="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
mode="${1:-run}"
ui_source="${VIMGUI_ANDROID_UI_SOURCE:-$repo_dir/examples/android_vulkan/ui.v}"
manifest="${VIMGUI_ANDROID_MANIFEST:-$repo_dir/examples/android_vulkan/AndroidManifest.xml}"
if [[ "$mode" != run && "$mode" != --build-only ]]; then
  echo 'Usage: scripts/run_android_demo.sh [--build-only]' >&2
  exit 2
fi
if [[ $# -gt 1 ]]; then
  echo 'Usage: scripts/run_android_demo.sh [run|--build-only]' >&2
  exit 2
fi
if [[ ! -f "$ui_source" && ! -d "$ui_source" ]]; then
  echo "Cannot find the V UI source: $ui_source" >&2
  exit 2
fi
if [[ ! -f "$manifest" ]]; then
  echo "Cannot find the Android manifest: $manifest" >&2
  exit 2
fi
if [[ -z "$ndk_dir" || ! -f "$ndk_dir/build/cmake/android.toolchain.cmake" ]]; then
  echo 'Set ANDROID_NDK_HOME to an installed NDK.' >&2
  exit 2
fi
if [[ -z "$sdk_dir" || ! -d "$sdk_dir/build-tools" ]]; then
  echo 'Set ANDROID_SDK_ROOT to an installed Android SDK.' >&2
  exit 2
fi

adb_args=()
if [[ -n "${ANDROID_SERIAL:-}" ]]; then adb_args=(-s "$ANDROID_SERIAL"); fi
abi="${ANDROID_ABI:-}"
if [[ -z "$abi" && "$mode" == run ]]; then
  abi="$(adb "${adb_args[@]}" shell getprop ro.product.cpu.abi | tr -d '\r')"
fi
case "$abi" in
  armeabi-v7a|arm64-v8a|x86_64) ;;
  *) echo "Set ANDROID_ABI to a supported ABI or connect a tablet (got '$abi')." >&2; exit 2 ;;
esac

application_options=()
v_options=()
if [[ ${VIMGUI_ANDROID_APPLICATION_UI:-0} == 1 ]]; then
  application_options=(-DVIMGUI_APPLICATION_UI=ON -DVIMGUI_ANDROID_EXTERNAL_ACCESSIBILITY=ON)
  v_options=(-d appui_embedded -d release_accessibility)
fi

build_dir="${VIMGUI_ANDROID_BUILD_DIR:-$repo_dir/build/android-onscreen-$abi}"
cmake -S "$repo_dir" -B "$build_dir" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ndk_dir/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="$abi" -DANDROID_PLATFORM=android-24 -DANDROID_STL=c++_static \
  -DVIMGUI_PROFILE=android-vulkan -DIMGUI_FREETYPE=ON \
  -DVIMGUI_FREETYPE_PROVIDER=bundled -DVIMGUI_BUILD_ANDROID_DEMO=ON \
  -DSTATIC_BUILD=OFF -DCMAKE_BUILD_TYPE=Release "${application_options[@]}"
cmake --build "$build_dir" --target vimgui_android_demo --parallel 4

# The host deliberately only owns Vulkan and Android lifecycle. The widgets
# are compiled from V into a separate DSO, then loaded by the host at runtime.
case "$abi" in
  armeabi-v7a) v_arch=arm; clang_target=armv7a-linux-androideabi24-clang ;;
  arm64-v8a) v_arch=arm64; clang_target=aarch64-linux-android24-clang ;;
  x86_64) v_arch=amd64; clang_target=x86_64-linux-android24-clang ;;
esac
ndk_prebuilt="$(find "$ndk_dir/toolchains/llvm/prebuilt" -mindepth 1 -maxdepth 1 -type d | head -1)"
if [[ -z "$ndk_prebuilt" || ! -x "$ndk_prebuilt/bin/$clang_target" ]]; then
  echo "Cannot find the NDK Clang target for $abi." >&2
  exit 2
fi
v_bin="${V_BIN:-v}"
mkdir -p "$build_dir/vmodules/antono2" "$repo_dir/lib/android-vulkan/$abi/freetype"
ln -sfn "$repo_dir" "$build_dir/vmodules/antono2/imgui"
cp "$build_dir/lib/libvimgui.so" "$repo_dir/lib/android-vulkan/$abi/freetype/libvimgui.so"
"$v_bin" "${v_options[@]}" -path "$build_dir/vmodules|@vlib|@vmodules" \
  -os android -arch "$v_arch" -cc "$ndk_prebuilt/bin/$clang_target" \
  -d use_freetype -gc none -no-memory-limit -shared \
  -o "$build_dir/libvimgui_android_ui.so" "$ui_source"
test -f "$build_dir/libvimgui_android_ui.so"

build_tools="$(find "$sdk_dir/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)"
android_jar="$(find "$sdk_dir/platforms" -mindepth 2 -maxdepth 2 -name android.jar | sort -V | tail -1)"
if [[ -z "$build_tools" || -z "$android_jar" ]]; then
  echo 'The Android SDK needs build-tools and a platform android.jar.' >&2
  exit 2
fi

package_dir="$build_dir/package"
rm -rf -- "$package_dir/classes" "$package_dir/dex"
mkdir -p "$package_dir/lib/$abi" "$package_dir/assets" "$package_dir/classes" "$package_dir/dex"
cp "$build_dir/lib/libvimgui.so" "$package_dir/lib/$abi/libvimgui.so"
cp "$build_dir/libvimgui_android_demo.so" "$package_dir/lib/$abi/libvimgui_android_demo.so"
cp "$build_dir/libvimgui_android_ui.so" "$package_dir/lib/$abi/libvimgui_android_ui.so"
cp "$repo_dir/cimgui/imgui/misc/fonts/Roboto-Medium.ttf" "$package_dir/assets/Roboto-Medium.ttf"
javac_bin="${JAVAC:-javac}"
"$javac_bin" -source 8 -target 8 -Xlint:-options -cp "$android_jar" -d "$package_dir/classes" \
  "$repo_dir/android/java/io/antono2/imgui/ImGuiInputView.java" \
  "$repo_dir/android/java/io/antono2/imgui/ImGuiAccessibility.java" \
  "$repo_dir/examples/android_vulkan/java/io/antono2/vimgui/demo/ImGuiActivity.java"
mapfile -d '' class_files < <(find "$package_dir/classes" -name '*.class' -print0)
"$build_tools/d8" --min-api 24 --lib "$android_jar" \
  --output "$package_dir/dex" "${class_files[@]}"
cp "$package_dir/dex/classes.dex" "$package_dir/classes.dex"
unsigned_apk="$build_dir/vimgui-demo-unsigned.apk"
aligned_apk="$build_dir/vimgui-demo-aligned.apk"
signed_apk="$build_dir/vimgui-demo-$abi.apk"
"$build_tools/aapt" package -f \
  -M "$manifest" \
  -I "$android_jar" -A "$package_dir/assets" -F "$unsigned_apk"
(
  cd "$package_dir"
  "$build_tools/aapt" add "$unsigned_apk" \
    "lib/$abi/libvimgui.so" "lib/$abi/libvimgui_android_demo.so" \
    "lib/$abi/libvimgui_android_ui.so" classes.dex
)
"$build_tools/zipalign" -f 4 "$unsigned_apk" "$aligned_apk"
keystore="$build_dir/debug.keystore"
if [[ ! -f "$keystore" ]]; then
  keytool -genkeypair -keystore "$keystore" -storepass android -keypass android \
    -alias androiddebugkey -dname 'CN=Android Debug,O=Android,C=US' \
    -validity 3650 -keyalg RSA -keysize 2048 -noprompt
fi
"$build_tools/apksigner" sign --ks "$keystore" --ks-pass pass:android \
  --key-pass pass:android --out "$signed_apk" "$aligned_apk"
"$build_tools/apksigner" verify "$signed_apk"
echo "APK: $signed_apk"

if [[ "$mode" == run ]]; then
  badging="$("$build_tools/aapt" dump badging "$signed_apk")"
  app_package="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<< "$badging")"
  app_activity="$(sed -n "s/^launchable-activity: name='\([^']*\)'.*/\1/p" <<< "$badging")"
  if [[ -z "$app_package" || -z "$app_activity" ]]; then
    echo 'The APK must declare a launcher activity.' >&2
    exit 2
  fi
  adb "${adb_args[@]}" install -r "$signed_apk"
  adb "${adb_args[@]}" shell am start -n "$app_package/$app_activity"
  echo 'Use adb logcat -s vimgui-android-demo:I to inspect lifecycle/taps.'
fi
