#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
abi=${ANDROID_ABI:-arm64-v8a}
ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}
case "$abi" in
  armeabi-v7a) rust_target=armv7-linux-androideabi; clang_target=armv7a-linux-androideabi24 ;;
  arm64-v8a) rust_target=aarch64-linux-android; clang_target=aarch64-linux-android24 ;;
  x86_64) rust_target=x86_64-linux-android; clang_target=x86_64-linux-android24 ;;
  *) echo "Unsupported Android ABI: $abi" >&2; exit 2 ;;
esac
if [[ ! -d "$ndk/toolchains/llvm/prebuilt" ]]; then
  echo 'Set ANDROID_NDK_HOME to an installed NDK.' >&2
  exit 2
fi
toolchains=("$ndk"/toolchains/llvm/prebuilt/*)
clang=${toolchains[0]}/bin/$clang_target-clang
if [[ ! -x "$clang" ]]; then
  echo "NDK compiler is unavailable: $clang" >&2
  exit 2
fi
python3 "$repo_root/scripts/prepare-accesskit.py" --android-source
rustup target add "$rust_target"
key=${rust_target//-/_}
export "CARGO_TARGET_${key^^}_LINKER=$clang"
export "CC_$key=$clang"
export "AR_$key=${toolchains[0]}/bin/llvm-ar"
release=$repo_root/.dependencies/accesskit/accesskit-c-0.23.1
cargo build --locked --release -j 2 --target "$rust_target" \
  --features android-embedded-dex --manifest-path "$release/Cargo.toml"
printf 'AccessKit library: %s\n' "$release/target/$rust_target/release/libaccesskit.a"
