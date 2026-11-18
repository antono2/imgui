#!/bin/sh
# Compatibility entry point for the V mobile parity check.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "${V_BIN:-v}" run "$script_dir/check_mobile_parity.vsh" "$@"
