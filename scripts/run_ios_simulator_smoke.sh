#!/bin/sh
# Compatibility entry point for the V iOS Simulator checks.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "${V_BIN:-v}" run "$script_dir/run_ios_simulator_smoke.vsh" "$@"
