# Quick start

The generated V bindings are already committed. Most users can prepare the
checkout on Linux or macOS with `./setup.vsh`, or on Windows with
`v run setup.vsh`. They only need to build
the native Dear ImGui/ImPlot library; LuaJIT and the binding generator are not
required.

Use a current compiler built from the official `vlang/v` repository. The tagged
V 0.5.2 release lacks process APIs used by these scripts. The exact V and
bootstrap revisions tested on Linux, macOS and Windows are recorded in
[the tooling workflow](.github/workflows/portable-tooling.yml).

## Ubuntu and Debian

Install [V](https://github.com/vlang/v), then clone and run the included setup
check:

```sh
git clone --recursive https://github.com/antono2/imgui
cd imgui
./setup.vsh --check
```

On Ubuntu or Debian, the script can install missing system and V module
dependencies:

```sh
./setup.vsh --install
```

Build the shared native library and launch the pinned GLFW/Vulkan example:

```sh
./scripts/run_demo.vsh
```

The demo runner downloads the tested `antono2/v_imgui_examples` revision into
the ignored `build/` directory. It installs the pinned V dependencies through
VPM and resolves `antono2.imgui` to this checkout, including when the clone has
a custom directory name. The build directory holds a local module link (a
junction on Windows); existing installed ImGui copies are not replaced. It does
not regenerate these bindings. The demo uses V’s compatibility compiler
(`-old-compiler`), which has passed the rendering smoke test. V3 compilation
is checked separately in CI; its Vulkan rendering path is not yet supported.

## Fedora

Install `gcc-c++`, `cmake`, `git`, `glfw-devel`, `vulkan-loader-devel`,
`vulkan-headers`, `volk-devel`, `vulkan-tools` and `pkgconf-pkg-config`.
Install the two V dependencies and then use the same build and demo commands:

```sh
v install antono2.vulkan@v2.0.0
v install antono2.glfw
./build_vimgui.vsh --linkage shared --glfw system
./scripts/run_demo.vsh
```

## Windows 10/11 x64

Install V, Git, CMake, Visual Studio Build Tools with C++ and the Vulkan SDK.
Then run these commands from a Developer PowerShell:

```powershell
v run scripts/check_prerequisites.vsh --glfw bundled
v run scripts/run_demo.vsh
```

The runner downloads GLFW 3.4 through CMake, installs missing V module
dependencies, checks out the tested demo revision, builds it and launches it.
Use `--build-only` to compile without opening a window. The required compiler
support landed upstream through
[`vlang/v#28368`](https://github.com/vlang/v/pull/28368), so use a current
compiler from the official `vlang/v` master branch until that change reaches a
tagged V release; a custom fork is no longer required.

## Build choices

The default is a shared library using system GLFW:

```sh
./build_vimgui.vsh --linkage shared --glfw system
```

A static library requires the matching V definition in consuming programs:

```sh
./build_vimgui.vsh --linkage static --glfw system
v -d imgui_static run your_app.v
```

For a reproducible bundled GLFW build:

```sh
./build_vimgui.vsh --linkage shared --glfw bundled --glfw-version 3.4
```

For a desktop example in a subdirectory of an existing checkout, the shared
`scripts/run_demo.vsh` accepts `--demo-directory` for the checkout root and
`--demo-source` for the V source directory. A supplied checkout is used as-is;
omitting `--demo-source` compiles its root. `--native-only` builds just the
native library. On Windows, prefix the build commands above with `v run`
instead of `./`.
