# Quick start

The generated V bindings are already committed. Most users only need to build
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
v install https://github.com/antono2/vulkan
v install https://github.com/antono2/glfw
v run build_vimgui.vsh --linkage shared --glfw system
./scripts/run_demo.sh
```

## Windows 10/11 x64

Install V, Git, CMake, Visual Studio Build Tools with C++, the Vulkan SDK, and
GLFW 3.4. In a Developer PowerShell set `GLFW_INCLUDE` and `GLFW_LIB`, then run:

```powershell
.\scripts\check_windows.ps1
v install https://github.com/antono2/vulkan
v install https://github.com/antono2/glfw
v run build_vimgui.vsh --linkage shared --glfw bundled --glfw-version 3.4
```

This builds the native library without requiring a separately installed GLFW.
A one-command Windows demo/package script is still TODO. The Linux demo runner
is not intended for PowerShell.

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

Binding regeneration is maintainer-oriented and additionally requires LuaJIT.
Run `./generate_v.sh` only when updating the generated ImGui or ImPlot API.
