#!/usr/bin/env bash
# Launches the packaged demo using its bundled native libraries.
set -euo pipefail
package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
exec "$package_dir/v_imgui_demo" "$@"
