# Maintaining the bindings

This document is for contributors updating generated bindings, release artifacts
or repository automation. For installation and application integration, use the
[README](README.md), [Quick Start](QUICKSTART.md) and [mobile guide](docs/mobile.md).

## Generated API and upstream variants

`imgui.v` and `implot/implot.v` are committed output, not an install-time build
step. The pipeline starts with [cimgui](https://github.com/cimgui/cimgui) and
[cimplot](https://github.com/cimgui/cimplot), translates their generated C API
with `v translate`/C2V, then normalizes the V output with
`cleanup_imgui_implot.vsh`. The `master` branch uses cimgui's `docking_inter`
line; `standard` uses cimgui's `master` line. Keep each branch's
`UPSTREAM_VARIANT`, submodule revisions, generated V files and native library
sources together.

To regenerate against the submodule revisions already checked out, run
`./generate.vsh`. It also builds `libvimgui`. The normal path uses the
committed generated C API and does not need Perl or LuaJIT. Use
`--regenerate-c` only when intentionally rerunning upstream's Lua generators;
that mode needs LuaJIT. `C2V_BIN` can point to a previously built C2V executable
instead of allowing `v translate` to install one. Compiling the resulting V
bindings can require roughly 11 GiB of memory; the demo build uses V's
`-no-memory-limit` option.

To advance upstream revisions, run the matching command on the matching branch:

```sh
v run scripts/update_upstream.vsh docking
# On standard only:
v run scripts/update_upstream.vsh standard
```

Use `--check-only` for a read-only `changed=true` or `changed=false` report.
Run `v run scripts/update_upstream.vsh current --check-only` to read the
variant from `UPSTREAM_VARIANT` and check its upstream revisions.
The updater refuses dirty submodules and non-fast-forward upstream changes.
Review the generated diff, variant, native build and V checks before merging.

## Upstream update automation

[The upstream update workflow](.github/workflows/update-upstream.yml) checks
both variants weekly or on manual dispatch. When cimgui or cimplot advances,
it regenerates with pinned V and C2V revisions, validates the generated API and
native library and opens or updates a draft pull request for human review.
A matching generated tree reuses its branch commit and can recover a missing
draft. Repository-token publication dispatches CI after a push or draft
creation. Personal-token publication uses GitHub's normal PR triggers.
Pull requests regenerate both bindings with the pinned toolchain and compare
them byte-for-byte with committed output. Review translator and cleanup changes
as API changes.

Run `v run scripts/publish_generated_branch.vsh --self-test` to exercise draft
creation, recovery, no-ops, lease conflicts and CI dispatch with a local
Git remote and a simulated GitHub client.

## CI and release artifacts

[The mobile workflow](.github/workflows/mobile-native.yml) runs an offscreen
Vulkan/FreeType frame on Ubuntu, cross-builds Android for `armeabi-v7a`,
`arm64-v8a` and `x86_64`, and compiles/links Metal for macOS, both iOS Simulator
architectures and arm64 iPhoneOS. Simulator runtime is advisory because hosted
runners may lack a usable Metal device; passing it does not validate real Apple
hardware or IMEs. Android emulator and physical-device tests are separate from
the required matrix.

To reproduce the Linux lane, install CMake, Ninja, GLFW, Vulkan, FreeType, and
Mesa Lavapipe. Use the released V compiler for the native build and the pinned
compiler from `compatibility.json` for the callback check.

```sh
v run scripts/check_native.vsh linux-build build/ci-linux
v run scripts/check_native.vsh linux-probes build/ci-linux
v run scripts/check_native.vsh linux-callback build/ci-linux /tmp/imgui-native-check
```

The same driver accepts an Android ABI or an Apple SDK and architecture for
frontend checks. Run `v run scripts/check_native.vsh --help` for those commands.

To reproduce the Android build and package checks, set `ANDROID_SDK_ROOT` and put
the SDK command-line tools, a JDK, CMake, and Ninja on `PATH`. Use the V compiler
pinned in `compatibility.json`.

```sh
export ANDROID_ABI=x86_64
v run scripts/check_android.vsh install
v run scripts/check_android.vsh java /tmp/imgui-java
v run scripts/check_android.vsh probes
v run scripts/check_android.vsh demo
v run scripts/check_android.vsh accessible
```

The driver checks the required APK entries and native exports. The
`arm-link SCRATCH` command checks the 32-bit ARM output after a `probes` build
with `ANDROID_ABI=armeabi-v7a`.

On macOS with Xcode and Ninja, use the same driver as the Apple workflow.
Initialize the repository submodules first. This example uses an arm64 simulator.

```sh
v run scripts/check_native.vsh apple-build build/apple iphonesimulator arm64
v run scripts/check_native.vsh apple-link build/apple build/apple-scratch iphonesimulator arm64
v run scripts/check_native.vsh apple-verify build/apple iphonesimulator arm64
```

Use the same SDK and architecture for all three commands. The link step stages the
shared library and links a V consumer. The verification step checks the output
architecture and exports, plus the app bundle and GameController linkage for iOS.

[The mobile parity workflow](.github/workflows/mobile-parity.yml) compares
hand-maintained mobile integration on `master` and `standard` weekly and on
manual dispatch. Run `v run scripts/check_mobile_parity.vsh` locally after
coordinated changes to both branches. Generated APIs, upstream submodules and
variant-specific Vulkan bindings are deliberately excluded.

[The demo workflow](.github/workflows/demo-release.yml) builds Ubuntu 24.04
x86_64 and Windows 10/11 x64 artifacts. The source path remains
`scripts/run_demo.vsh`; prebuilding a demo is not a requirement for every
release. Keep the archive variant marker and the pinned demo/compiler revisions
aligned when changing release packaging. Both packagers write the ZIP in V
and compare every archived file against its source. Run
`v run scripts/package_ubuntu_demo.vsh --help` or
`v run scripts/package_windows_demo.vsh --help` for local packaging options.
The Windows packager takes a directory containing the built EXE and its two
DLLs and can verify a prebuilt runtime without a Windows host.

## Source map and file introductions

`appui/` is the V application-widget interface; `native/application/` owns its
platform hosts and widget implementation. `native/accessibility/` owns the
shared tree and platform adapters. Android Java/JNI and Apple Objective-C++
bridges live beside the corresponding native backends. The `impl_*` directories
expose those backends to V; callers must respect each backend's initialization
and shutdown order.

Purpose comments cover maintained implementation, tests and tooling. Keep the
generated API introduction in `cleanup_imgui_implot.vsh`, then regenerate both
outputs. Preserve upstream submodules and copied upstream files under `include/`;
document their integration in local wrappers instead of editing their headers.
Configuration and asset files are not executable-source comment targets.
