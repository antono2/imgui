#!/usr/bin/env bash
# Compares shared mobile integration across the standard and docking branches.
set -euo pipefail

master_ref=${1:-origin/master}
standard_ref=${2:-origin/standard}

git rev-parse --verify "${master_ref}^{commit}" >/dev/null
git rev-parse --verify "${standard_ref}^{commit}" >/dev/null

# Only hand-maintained, variant-neutral mobile integration belongs here.
# Generated APIs, upstream submodules, and variant-specific Vulkan bindings
# intentionally differ between the docking and standard branches.
shared_paths=(
  .github/workflows/mobile-native.yml
  .gitmodules
  CMakeLists.txt
  build_vimgui.vsh
  imgui.c.v
  android
  docs/mobile.md
  examples/android_vulkan
  examples/ios_metal
  impl_android
  impl_ios
  impl_metal
  impl_mobile
  impl_osx
  native
  scripts/run_android_demo.sh
  scripts/run_android_probes.sh
  scripts/run_ios_simulator_smoke.sh
  scripts/tooling
  scripts/build_appui.vsh
  scripts/check_prerequisites.vsh
  scripts/run_demo.vsh
  scripts/extract_zip.vsh
  scripts/setup_vulkan_ci.vsh
  setup.vsh
  .github/workflows/portable-tooling.yml
  tests/android
  tests/apple
  tests/desktop/moving_dependencies_smoke.v
  tests/input_text_callback.v
  tests/mobile
  tests/vulkan
)

if git diff --quiet "$master_ref" "$standard_ref" -- "${shared_paths[@]}"; then
  echo "Shared mobile integration matches between $master_ref and $standard_ref."
else
  echo "Shared mobile integration differs between $master_ref and $standard_ref:" >&2
  git diff --name-status "$master_ref" "$standard_ref" -- "${shared_paths[@]}" >&2
  exit 1
fi
