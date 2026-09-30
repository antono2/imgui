# Maintaining the bindings

This document is for contributors updating generated bindings, release artifacts,
or repository automation. For installation and application integration, use the
[README](README.md), [Quick Start](QUICKSTART.md), and [mobile guide](docs/mobile.md).

## Generated API and upstream variants

`imgui.v` and `implot/implot.v` are committed output, not an install-time build
step. The pipeline starts with [cimgui](https://github.com/cimgui/cimgui) and
[cimplot](https://github.com/cimgui/cimplot), translates their generated C API
with `v translate`/C2V, then normalizes the V output with
`cleanup_imgui_implot.vsh`. The `master` branch uses cimgui's `docking_inter`
line; `standard` uses cimgui's `master` line. Keep each branch's
`UPSTREAM_VARIANT`, submodule revisions, generated V files, and native library
sources together.

To regenerate against the submodule revisions already checked out, run
`v run generate.vsh`. It also builds `libvimgui`. The normal path uses the
committed generated C API and does not need Perl or LuaJIT. Use
`--regenerate-c` only when intentionally rerunning upstream's Lua generators;
that mode needs LuaJIT. `C2V_BIN` can point to a previously built C2V executable
instead of allowing `v translate` to install one. Compiling the resulting V
bindings can require roughly 11 GiB of memory; the demo build uses V's
`-no-memory-limit` option.

To advance upstream revisions, run the matching command on the matching branch:

```sh
./scripts/update_upstream.sh docking
# On standard only:
./scripts/update_upstream.sh standard
```

Use `--check-only` for a read-only `changed=true` or `changed=false` report.
The updater refuses dirty submodules and non-fast-forward upstream changes.
Review the generated diff, variant, native build, and V checks before merging.

## Upstream update automation

[The upstream update workflow](.github/workflows/update-upstream.yml) checks
both variants weekly or on manual dispatch. When cimgui or cimplot advances,
it regenerates with pinned V and C2V revisions, validates the generated API and
native library, and opens or updates a draft pull request. It does not merge
automatically. Pull requests also regenerate both bindings with the pinned
toolchain and compare them byte-for-byte with committed output; translator or
cleanup changes must therefore be reviewed as API changes.

The proposal job requests only `contents: write` and `pull-requests: write`.
To let it create PRs with `GITHUB_TOKEN`, a repository admin must enable
**Settings → Actions → General → Workflow permissions → Allow GitHub Actions to
create and approve pull requests**. Alternatively, set the optional
`UPSTREAM_UPDATE_TOKEN` repository secret to a GitHub App installation token
or fine-grained PAT with those permissions. A separate token can avoid approval
holds on PR checks triggered by `GITHUB_TOKEN` and is preferable for unattended
proposals. Neither option authorizes automatic merging.

## CI and release artifacts

[The mobile workflow](.github/workflows/mobile-native.yml) runs an offscreen
Vulkan/FreeType frame on Ubuntu, cross-builds Android for `armeabi-v7a`,
`arm64-v8a`, and `x86_64`, and compiles/links Metal for macOS, both iOS Simulator
architectures, and arm64 iPhoneOS. Simulator runtime is advisory because hosted
runners may lack a usable Metal device; passing it does not validate real Apple
hardware or IMEs. Android emulator and physical-device tests are separate from
the required matrix.

[The demo workflow](.github/workflows/demo-release.yml) builds Ubuntu 24.04
x86_64 and Windows 10/11 x64 artifacts. The source path remains
`scripts/run_demo.sh`; prebuilding a demo is not a requirement for every
release. Keep the archive variant marker and the pinned demo/compiler revisions
aligned when changing release packaging.
