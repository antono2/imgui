# Quick start

The generated V bindings are already committed. Most users can prepare the
checkout on Linux, macOS, or Windows with `v run setup.vsh`. They only need to build
the native Dear ImGui/ImPlot library; LuaJIT and the binding generator are not
required.

## Ubuntu and Debian

Install [V](https://github.com/vlang/v), then clone and run the included setup
check:

```sh
git clone --recursive https://github.com/antono2/imgui
cd imgui
./scripts/setup_linux.sh --check
```

On Ubuntu or Debian, the script can install missing system and V module
dependencies:

```sh
./scripts/setup_linux.sh --install
```

Build the shared native library and launch the pinned GLFW/Vulkan example:

```sh
./scripts/run_demo.sh
```

The demo runner downloads the tested `antono2/v_imgui_examples` revision into
the ignored `build/` directory. It does not regenerate these bindings.

## Fedora

Install `gcc-c++`, `cmake`, `git`, `glfw-devel`, `vulkan-loader-devel`,
`vulkan-headers`, `volk-devel`, `vulkan-tools`, and `pkgconf-pkg-config`.
Install the two V dependencies and then use the same build and demo commands:

```sh
v install antono2.vulkan
v install antono2.glfw
v run build_vimgui.vsh --linkage shared --glfw system
./scripts/run_demo.sh
```

## Windows 10/11 x64

Install V, Git, CMake, Visual Studio Build Tools with C++, and the Vulkan SDK.
Then run these commands from a Developer PowerShell:

```powershell
.\scripts\check_windows.ps1 -BundledGlfw
.\scripts\run_demo_windows.ps1
```

The runner downloads GLFW 3.4 through CMake, installs missing V module
dependencies, checks out the tested demo revision, builds it, and launches it.
Use `-BuildOnly` to compile without opening a window. CI checks the same path
against pinned module and compiler revisions. The required compiler support
landed upstream through
[`vlang/v#28368`](https://github.com/vlang/v/pull/28368), so use a current
compiler from the official `vlang/v` master branch until that change reaches a
tagged V release; a custom fork is no longer required.

## Build choices

The default is a shared library using system GLFW:

```sh
v run build_vimgui.vsh --linkage shared --glfw system
```

A static library requires the matching V definition in consuming programs:

```sh
v run build_vimgui.vsh --linkage static --glfw system
v -d imgui_static run your_app.v
```

For a reproducible bundled GLFW build:

```sh
v run build_vimgui.vsh --linkage shared --glfw bundled --glfw-version 3.4
```

## Regenerating bindings

Binding regeneration is maintainer-oriented. Run `v run generate.vsh` only when
updating the generated ImGui or ImPlot API. It translates the generated API
committed by the pinned upstream submodules; LuaJIT is required only with the
advanced `--regenerate-c` option. Use `./scripts/update_upstream.sh docking` on
the default branch or `./scripts/update_upstream.sh standard` on the standard
variant branch to advance the corresponding upstream line.
