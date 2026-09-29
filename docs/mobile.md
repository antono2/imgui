# Mobile backends (Vulkan / Metal)

These profiles reuse the Dear ImGui backends pinned in `cimgui/imgui`. They do
not regenerate `imgui.v` or `implot.v` and do not add mobile sources to desktop
builds. The native library includes ImPlot, as desktop builds do.

## Build profiles

Initialize the submodules first (`git submodule update --init --recursive`).
Android requires NDK r27c and Vulkan-capable API 24 or newer:

```sh
v run build_vimgui.vsh --profile android-vulkan --linkage shared \
  --android-abi armeabi-v7a --android-api 24 --ndk "$ANDROID_NDK_HOME" \
  --freetype bundled
```

`arm64-v8a` and `x86_64` are also supported. The corresponding output is
`lib/android-vulkan/<abi>/freetype/libvimgui.so`. Omit `--freetype bundled`
for a build using stb_truetype; it goes in `lib/android-vulkan/<abi>/`.

On macOS with Xcode installed:

```sh
v run build_vimgui.vsh --profile apple-metal --apple-sdk macosx \
  --apple-arch arm64 --freetype bundled
v run build_vimgui.vsh --profile apple-metal --apple-sdk iphonesimulator \
  --apple-arch arm64 --freetype bundled
v run build_vimgui.vsh --profile apple-metal --apple-sdk iphoneos \
  --apple-arch arm64 --freetype bundled
```

The output is `lib/apple-metal/<sdk>/<arch>[/freetype]/libvimgui.dylib`.
Device builds use the iPhoneOS SDK and do not require signing until embedded
in an app. Simulator builds are separate for `arm64` and `x86_64`. For macOS
Metal in V, select `-d imgui_metal`; ordinary macOS builds remain GLFW/Vulkan.
For the FreeType output, also compile the V app with `-d use_freetype`. For an
iOS device V build, select `-d imgui_ios_device`; otherwise iOS selects the
simulator library for the target architecture.
`--linkage static` produces `libvimgui.a` in the same profile directory; select
it from V with `-d imgui_static`. Bundled FreeType also produces a separate
`libfreetype.a`, selected automatically by the V linker flags.

`IMGUI_ENABLE_FREETYPE` makes the pinned FreeType loader the default. The
stb_truetype implementation remains compiled because this repository's
generated cimgui bridge still exports its loader function; apps using the
FreeType profile do not need to select stb. The
`impl_mobile.set_ui_scale(scale)` helper scales both `FontScaleMain` and all
widget sizes from a baseline style, without accumulating rounding error. Call
it after theme customization and before the first frame. Call
`impl_mobile.reset_style_baseline()` after a theme change or new context, then
set the scale again. On Android, the upstream backend reports display size in
physical pixels, so scale typically derives from the device density or user
zoom. On iOS, supply UIKit point dimensions and the point-to-pixel factor to
`impl_ios.new_frame`; keep `set_ui_scale` at `1.0` for normal UIKit-sized
controls, or use it for an additional user zoom. Do not apply screen scale to
both the style and `DisplayFramebufferScale`.

## Android host lifecycle

The app owns `ANativeWindow`, the Vulkan instance/device/swapchain/render pass,
and its `NativeActivity` or Java Activity. This module owns neither the app loop
nor a Vulkan surface. The V-facing platform module is `imgui.impl_android`;
the existing `imgui.impl_vulkan` renderer remains unchanged.

1. Create an ImGui context. Set the style and call
   `impl_mobile.set_ui_scale(density_scale)`.
2. On window creation, call `impl_android.init(native_window)`. Initialize
   Vulkan and call `impl_vulkan.load_functions(...)` before any other Vulkan
   backend function, then `impl_vulkan.vkinit(...)` with the application's
   Vulkan objects and render-pass configuration.
3. Send each `AInputEvent` to `impl_android.handle_input_event(event)`. The
   upstream backend maps touch, mouse, pen, keyboard, and wheel events.
4. Each drawable frame: call `impl_vulkan.new_frame()`,
   `impl_android.new_frame()`, `imgui.new_frame()`, build UI,
   `imgui.render()`, and `impl_vulkan.render_draw_data(imgui.get_draw_data(),
   command_buffer, ...)` inside an active Vulkan render pass. Submit and
   present with the host application's Vulkan code.
5. If `impl_android.wants_text_input()` changes, call
   `ImGuiInputView.setKeyboardVisible(...)` on Android's UI thread. Include
   `android/java/io/antono2/imgui/ImGuiInputView.java` in the app and attach it
   to the Activity's view hierarchy. It sends committed UTF-16 text and basic
   editing keys through a thread-safe JNI queue; `impl_android.new_frame()`
   drains the queue on the render thread. Applications with their own
   `InputConnection` may instead call `impl_android.text_utf8(...)` on the
   render thread. Inline underlined IME preedit is not implemented.
6. Wait for in-flight Vulkan work, then shut down the Vulkan renderer, call
   `impl_android.shutdown()`, and destroy the ImGui context. Reinitialize the
   Android backend if the native window is replaced.

Do not drive the soft keyboard with `igIsItemActive()`; the relevant intent is
`ImGuiIO.WantTextInput`, which is exposed as `wants_text_input()`.

### Installable Android Vulkan sample

`examples/android_vulkan` is a small NativeActivity host for integration
testing. Its C++ part owns the Vulkan surface/swapchain and forwards input to
the same Android wrapper exposed to V; `examples/android_vulkan/ui.v` builds
the widgets through this repository's public V bindings. The V UI is compiled
as `libvimgui_android_ui.so` and loaded by the host, so the sample exercises
the actual V API on screen. The renderer remains upstream's Vulkan backend;
the C++ lifecycle host is not an alternative V API. The app includes the Java
`ImGuiInputView` and a tiny `NativeActivity` subclass that switches keyboard
visibility on the UI thread. It loads the vendored Roboto TTF asset, uses the
FreeType profile, and has a UI zoom slider that scales fonts and widget sizes
together. It demonstrates committed text and basic editing, not inline
underlined IME composition.

With the Android SDK (including build-tools and a platform), NDK, JDK, and a
connected Vulkan-capable tablet:

```sh
export ANDROID_SDK_ROOT=/path/to/android-sdk
export ANDROID_NDK_HOME="$ANDROID_SDK_ROOT/ndk/27.3.13750724"
scripts/run_android_demo.sh
```

The script selects the device ABI, builds the native host and V UI, packages,
debug-signs, installs, and launches `io.antono2.vimgui.demo`. It requires `v`
on `PATH` (or `V_BIN` pointing to it). Set `ANDROID_SERIAL` if multiple devices
are connected. For CI/offline packaging, set `ANDROID_ABI` and pass
`--build-only`.
Tap the button, enter committed text, change UI zoom, rotate the tablet, and
background/resume the app. `adb logcat -s vimgui-android-demo:I` reports
initialization, swapchain recreation, tap counts, and keyboard visibility.

## iOS and macOS Metal lifecycle

`imgui.impl_metal` accepts borrowed opaque Objective-C pointers so V does not
need to model Metal protocols. The app owns its `MTKView` or `CAMetalLayer`,
`id<MTLDevice>`, command queue/buffer, current drawable, render-pass
descriptor, and render-command encoder. For iOS, use `imgui.impl_ios` for
minimal platform IO. For macOS, use `imgui.impl_osx`, which forwards to
upstream's Cocoa backend.

1. Create an ImGui context, apply style/scale, initialize `impl_ios.init_platform()` or
   `impl_osx.init(ns_view)`, then call `impl_metal.init(device)`.
2. For each drawable frame, obtain a valid render-pass descriptor and command
   buffer. Call `impl_metal.new_frame(render_pass_descriptor)`, then
   `impl_ios.new_frame(width_points, height_points, framebuffer_scale,
   delta_seconds)` or `impl_osx.new_frame(ns_view)`, then `imgui.new_frame()`.
3. Build the UI and call `imgui.render()`. Create an active Metal render-command
   encoder from the pass descriptor, call
   `impl_metal.render_draw_data(imgui.get_draw_data(), command_buffer,
   render_command_encoder)`, end encoding, present the drawable, and commit.
4. On iOS, forward UITouch identity and position in points to
   `impl_ios.touch(id, x, y, down)`. The first active touch is mapped to
   ImGui's primary pointer. Forward hardware keys through `impl_ios.key(...)`
   and committed UTF-8 text through `impl_ios.text_utf8(...)`. Use
   `impl_ios.wants_text_input()` to show or hide an app-owned UIKit text view.
   Clipboard reads and writes use `UIPasteboard` and should occur on the main
   thread. Inline marked-text composition and a packaged UITextInput view are
   not part of this first pass.
5. Ensure command buffers using ImGui resources are complete, call
   `impl_metal.shutdown()`, then the platform shutdown, then destroy the ImGui
   context.

The Metal wrapper and upstream renderer are compiled as Objective-C++ with
ARC. Android never compiles them; Apple never compiles the Android backend.
The macOS build also compiles upstream `imgui_impl_osx.mm`. The iOS build does
not pull in AppKit/Cocoa.

The Android sample is an integration host, not a reusable application shell;
the Vulkan/NativeActivity host remains C++ while the ImGui widgets are written
in V. Android uses upstream's platform backend, which does not
supply clipboard or gamepad integration; the Java bridge adds committed IME
text and basic editing keys only. There is no on-screen iOS sample yet. The
iOS layer handles one primary touch and delegates keyboard visibility and
committed text collection to the host UIKit app.

## Validation boundaries

`mobile-native.yml` renders an offscreen ImGui frame through Lavapipe on Ubuntu,
then builds and link-tests the Android native backend, on-screen host, V UI,
and IME Java class for three ABIs, cross-links a small V app, and packages a
debug APK for each ABI. It builds and
link-tests Metal/FreeType on GitHub-hosted macOS for
macOS, both iOS Simulator architectures, and arm64 iPhoneOS. No signing or
attached Apple hardware is required for those jobs. On a connected Android
device, `vimgui_android_device_probe` tests context/scaling and physical-device
discovery; `vimgui_vulkan_offscreen_probe` submits a real ImGui frame to the GPU.
The installable sample additionally exercises an on-screen Vulkan swapchain,
touch, rotation, background/resume, and committed IME input on Android hardware.
Emulator UI testing and real Apple GPU tests remain separate optional work.

For the connected-device checks, set `ANDROID_NDK_HOME` and run
`scripts/run_android_probes.sh`. It builds the device's reported ABI, stages only
the two probe executables and `libvimgui.so` under
`/data/local/tmp/io.antono2.vimgui.probe`, and executes both. Set
`ANDROID_SERIAL` when more than one device is connected.
