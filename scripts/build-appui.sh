#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cmake -S "$repo_root/native/application" -B "$repo_root/build/appui" \
  -DCMAKE_BUILD_TYPE=Release "$@"
cmake --build "$repo_root/build/appui" --parallel 2
