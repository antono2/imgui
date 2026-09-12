

# [V](https://vlang.io) binding generator for [Dear ImGui](https://github.com/ocornut/imgui)

[Project portfolio](https://oreskin.de/projects_en.php)

For a fresh-clone setup and a one-command GLFW/Vulkan demo, see
[`QUICKSTART.md`](QUICKSTART.md).

The cross-platform setup entry point installs prerequisites and builds the
native library without regenerating bindings:

```sh
v run setup.vsh
```

Use `v run setup.vsh --check` for read-only diagnostics.

This is an automated process to generate `imgui.v` and `implot.v`
 - generate C for imgui using [cimgui](https://github.com/cimgui/cimgui)
 - generate C for implot using [cimplot](https://github.com/cimgui/cimplot)
 - `v translate` C to V
 - `cleanup_imgui_implot.perl` to normalize both generated bindings

## Upstream variants

This repository supports both official Dear ImGui lines:

- `master` is the default **docking** build, generated from cimgui's
  `docking_inter` branch. It includes docking and multi-viewport support while
  retaining the normal Dear ImGui API.
- The `standard` branch is generated from cimgui's `master` branch for users
  who want to track Dear ImGui's smaller standard line exactly.

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
`v install antono2.vulkan`<br>
`v install antono2.glfw`

## Install
```bash
v install antono2.imgui
# Build libvimgui for this machine (without regenerating V bindings)
cd ~/.vmodules/antono2/imgui
v run build_vimgui.vsh
```

### Native-library choices

The default uses a shared `libvimgui` and the system GLFW development package:

```bash
v run build_vimgui.vsh --linkage shared --glfw system
```

To build a static archive and select it from V:

```bash
v run build_vimgui.vsh --linkage static --glfw system
v -d imgui_static run your_app.v
```

GLFW can instead be downloaded at a chosen release tag. This is useful for a
reproducible application bundle:

```bash
v run build_vimgui.vsh --linkage shared --glfw bundled --glfw-version 3.4
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
11 GiB of memory and therefore uses V's `-no-memory-limit` option.
`scripts/run_demo.sh` remains the normal source/developer path; prebuilding the
demo is not a requirement for every later release.

Release binaries are built for Ubuntu 24.04 x86_64 and Windows 10/11 x64.
Native-library linkage and the GLFW provider remain build-time choices for
developers; they do not need to multiply the end-user demo downloads.

## Generate

```bash
# Go to the installed antono2/imgui module
./generate_v.sh
```

`generate_v.sh` regenerates both V bindings from the generated C API committed
by the pinned cimgui/cimplot revisions, then builds `libvimgui`. It therefore
does not require LuaJIT for a normal upstream refresh. Pass `--regenerate-c`
only when intentionally rerunning the upstream Lua generators; that advanced
mode requires LuaJIT. `v generate.vsh` is retained as a compatibility entry
point and delegates to the same canonical script.

Maintainers can update either line reproducibly with:

```bash
./scripts/update_upstream.sh docking
# On the standard branch:
./scripts/update_upstream.sh standard
```

To only rebuild the native library after a system upgrade or on an older Linux
distribution, run `v run build_vimgui.vsh`. The Bash `build_vimgui.sh` helper
remains available as a bootstrap fallback on Unix-like machines where V is not
yet in `PATH`.

## Thanks
Thank you [@ryoskzypu](https://github.com/ryoskzypu) - from  #regex on [libera.chat](https://libera.chat/) - for loving perl and helping people out.
