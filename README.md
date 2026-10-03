

# [V](https://vlang.io) bindings for [Dear ImGui](https://github.com/ocornut/imgui) and ImPlot

[Project portfolio](https://oreskin.de/projects_en.php)

For a fresh-clone setup and a one-command GLFW/Vulkan demo, see
[`QUICKSTART.md`](QUICKSTART.md).
For Android Vulkan and Apple Metal/iOS build and lifecycle details, see
[`docs/mobile.md`](docs/mobile.md).

The cross-platform setup entry point installs prerequisites and builds the
native library without regenerating bindings:

```sh
./setup.vsh
```

Use `./setup.vsh --check` for read-only diagnostics. The scripts are executable on
Linux and macOS with V on `PATH`. On Windows, run the same files with
`v run setup.vsh` or `v run scripts/run_demo.vsh` from a Developer PowerShell.

The V bindings are already generated and committed. Installing the module does
not require the binding generators; see [Maintaining](MAINTAINING.md) if you
are updating the upstream API.

## Upstream variants

This repository supports both official Dear ImGui lines:

- `master` is the default **docking** build. It includes docking and
  multi-viewport support while retaining the normal Dear ImGui API.
- The `standard` branch tracks Dear ImGui's smaller standard line.

Both currently track Dear ImGui `1.92.9b`. The `b` is an upstream patch-level
suffix shared by the release; it does not identify the docking variant. Check
`UPSTREAM_VARIANT` in a checkout to see which line its generated bindings and
native sources use. Do not mix a generated binding from one line with a native
library built from the other.

Applications can identify and configure the selected line without referring to
docking-only generated symbols:

```v
println('Dear ImGui variant: ${imgui.upstream_variant}')
if imgui.configure_docking(true) {
	imgui.create_main_dockspace()
}
imgui.configure_platform_viewports(true)
// After rendering the main viewport:
imgui.render_platform_viewports()
```

The configuration functions return `false` on the standard branch. Dockspace
and secondary-viewport rendering helpers become safe no-ops there.

## Dependencies
The setup and build tooling uses V, CMake, Git, and a C/C++ toolchain. Python,
Rust, and Cargo are not required.

`v install antono2.vulkan@v3.2.0`<br>
`v install antono2.glfw@v2.0.0`

## Install
```bash
v install antono2.imgui
# Build libvimgui for this machine (without regenerating V bindings)
cd ~/.vmodules/antono2/imgui
./build_vimgui.vsh
```

### Native-library choices

The default uses a shared `libvimgui` and the system GLFW development package:

```bash
./build_vimgui.vsh --linkage shared --glfw system
```

To build a static archive and select it from V:

```bash
./build_vimgui.vsh --linkage static --glfw system
v -d imgui_static run your_app.v
```

GLFW can instead be downloaded at a chosen release tag. This is useful for a
reproducible application bundle:

```bash
./build_vimgui.vsh --linkage shared --glfw bundled --glfw-version 3.4
```

`VIMGUI_LINKAGE`, `VIMGUI_GLFW_PROVIDER`, and `VIMGUI_GLFW_VERSION` provide the
same choices as environment variables. System GLFW is preferable for distro
packages. Bundled GLFW is preferable when shipping a matching `libglfw.so.3`
beside `libvimgui.so`; use an `$ORIGIN` runtime path in the application package.

### Vulkan loader ownership

`libvimgui` is built with `IMGUI_IMPL_VULKAN_NO_PROTOTYPES` and intentionally
does not link directly to `libvulkan`. A Volk-based application must initialize
in this order:

1. Call `volkInitialize()` before GLFW performs Vulkan discovery.
2. Create the Vulkan instance and call `volkLoadInstance(instance)`.
3. Immediately call `imgui.impl_vulkan.load_functions(...)` with a callback
   backed by `vkGetInstanceProcAddr`.
4. Only then call helpers such as `select_physical_device`,
   `select_queue_family_index`, or `vkinit`.

Calling an ImGui Vulkan helper before step 3 can produce an early segmentation
fault with little or no stack trace. Do not combine the directly linked Vulkan
prototype path with Volk's global dispatch table in the same application.

## Examples
Using GLFW and Dear ImGui [antono2/v_imgui_examples](https://github.com/antono2/v_imgui_examples)

Release archives containing the already compiled demo and its runtime libraries
provide a low-friction validation path. The archive name identifies the
upstream line: `v-imgui-demo-docking-ubuntu24-amd64.zip` supports docking and
platform viewports, while `v-imgui-demo-standard-ubuntu24-amd64.zip` retains
normal independent floating windows. Each archive also contains `VARIANT.txt`.

Compiling the generated ImGui and ImPlot V bindings can currently require about
11 GiB of memory. Use `scripts/run_demo.vsh` to build and run the demo from source.

Release binaries are built for Ubuntu 24.04 x86_64 and Windows 10/11 x64.
Native-library linkage and the GLFW provider remain build-time choices for
developers; they do not need to multiply the end-user demo downloads.

For binding regeneration, upstream updates, and CI/release procedures, see
[Maintaining](MAINTAINING.md). To rebuild only the native library after a
system upgrade, run `./build_vimgui.vsh`.

## Thanks
Thank you [@ryoskzypu](https://github.com/ryoskzypu) from #regex on
[libera.chat](https://libera.chat/) for helping with the original cleanup rules
that the current V-native generator preserves.
