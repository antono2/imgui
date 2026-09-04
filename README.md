

# [V](https://vlang.io) binding generator for [Dear ImGui](https://github.com/ocornut/imgui)

For a fresh-clone setup and a one-command GLFW/Vulkan demo, see
[`QUICKSTART.md`](QUICKSTART.md).

This is an automated process to generate `imgui.v` and `implot.v`
 - generate C for imgui using [cimgui](https://github.com/cimgui/cimgui)
 - generate C for implot using [cimplot](https://github.com/cimgui/cimplot)
 - `v translate` C to V
 - `cleanup_imgui.perl` and `cleanup_implot.perl` to fix some errors

## Dependencies
`v install https://github.com/antono2/vulkan`<br>
`v install https://github.com/antono2/glfw`

## Install
```bash
v install https://github.com/antono2/imgui
# Build libvimgui for this machine (without regenerating V bindings)
cd ~/.vmodules/imgui
./build_vimgui.sh
```

### Native-library choices

The default uses a shared `libvimgui` and the system GLFW development package:

```bash
./build_vimgui.sh --linkage shared --glfw system
```

To build a static archive and select it from V:

```bash
./build_vimgui.sh --linkage static --glfw system
v -d imgui_static run your_app.v
```

GLFW can instead be downloaded at a chosen release tag. This is useful for a
reproducible application bundle:

```bash
./build_vimgui.sh --linkage shared --glfw bundled --glfw-version 3.4
```

`VIMGUI_LINKAGE`, `VIMGUI_GLFW_PROVIDER`, and `VIMGUI_GLFW_VERSION` provide the
same choices as environment variables. System GLFW is preferable for distro
packages. Bundled GLFW is preferable when shipping a matching `libglfw.so.3`
beside `libvimgui.so`; use an `$ORIGIN` runtime path in the application package.
## Examples
Using GLFW and Dear ImGui [antono2/v_imgui_examples](https://github.com/antono2/v_imgui_examples)

For the first release, an archive containing the already compiled demo and its
runtime libraries provides a low-friction validation path. Compiling the
generated ImGui and ImPlot V bindings can currently require about 11 GiB of
memory and therefore uses V's `-no-memory-limit` option. `scripts/run_demo.sh`
remains the normal source/developer path; prebuilding the demo is not a
requirement for every later release.

Release binaries should be published for the useful platform combinations
(Ubuntu 24.04 x86_64 and Windows x64 initially). Native-library linkage and the
GLFW provider remain build-time choices for developers; they do not need to
multiply the end-user demo downloads.

## Generate
On `Ubuntu`
```bash
sudo apt install -y luajit
~/.vmodules/imgui/generate_v.sh
```

Or
```bash
# Install luajit for your OS
# Go to vmodules/imgui
v generate.vsh
```

`generate_v.sh` and `generate.vsh` regenerate both bindings and then build
`libvimgui`. To only rebuild the native library after a system upgrade or on
an older Linux distribution, run `./build_vimgui.sh` (or `v build_vimgui.vsh`).

## Thanks
Thank you [@ryoskzypu](https://github.com/ryoskzypu) - from  #regex on [libera.chat](https://libera.chat/) - for loving perl and helping people out.
