#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$repo_root/scripts/prepare-accesskit.py"
accesskit_root="$repo_root/.dependencies/accesskit/accesskit-c-0.23.1"
cmake_options=()
if [[ $(uname -s) == Linux ]]; then
  cmake_options+=("-DVIMGUI_ACCESSKIT_STATIC_LIBRARY=$accesskit_root/target/release/libaccesskit.a")
fi
cmake -S "$repo_root/native/application" -B "$repo_root/build/appui" \
  -DCMAKE_BUILD_TYPE=Release "-DACCESSKIT_DIR=$accesskit_root" "${cmake_options[@]}" "$@"
cmake --build "$repo_root/build/appui" --parallel 2
