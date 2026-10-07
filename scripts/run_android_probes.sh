#!/usr/bin/env bash
# Runs Android native and Vulkan probes to validate device support.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ndk_dir="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
if [[ -z "$ndk_dir" || ! -f "$ndk_dir/build/cmake/android.toolchain.cmake" ]]; then
  echo 'Set ANDROID_NDK_HOME to an installed Android NDK first.' >&2
  exit 2
fi

adb_args=()
if [[ -n "${ANDROID_SERIAL:-}" ]]; then adb_args=(-s "$ANDROID_SERIAL"); fi
abi="$(adb "${adb_args[@]}" shell getprop ro.product.cpu.abi | tr -d '\r')"
case "$abi" in
  armeabi-v7a|arm64-v8a|x86_64) ;;
  *) echo "Unsupported or disconnected Android device ABI: $abi" >&2; exit 2 ;;
esac

build_dir="$repo_dir/build/android-device-probe-$abi"
cmake -S "$repo_dir" -B "$build_dir" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ndk_dir/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="$abi" \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DVIMGUI_PROFILE=android-vulkan \
  -DIMGUI_FREETYPE=ON \
  -DVIMGUI_FREETYPE_PROVIDER=bundled \
  -DVIMGUI_BUILD_SMOKE_TESTS=ON \
  -DSTATIC_BUILD=OFF \
  -DCMAKE_BUILD_TYPE=Release
cmake --build "$build_dir" --parallel 4

remote_dir=/data/local/tmp/io.antono2.vimgui.probe
adb "${adb_args[@]}" shell mkdir -p "$remote_dir"
adb "${adb_args[@]}" push "$build_dir/lib/libvimgui.so" "$remote_dir/libvimgui.so"
for probe in vimgui_android_device_probe vimgui_vulkan_offscreen_probe; do
  adb "${adb_args[@]}" push "$build_dir/$probe" "$remote_dir/$probe"
  adb "${adb_args[@]}" shell chmod 755 "$remote_dir/$probe"
  adb "${adb_args[@]}" shell "LD_LIBRARY_PATH=$remote_dir $remote_dir/$probe"
done
