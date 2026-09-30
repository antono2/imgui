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
   To enable copy/paste, also call
   `impl_android.set_clipboard_context(java_vm, android_context)` after `init`.
   Pass `ANativeActivity.vm` and `ANativeActivity.clazz` for a NativeActivity,
   or the equivalent `JavaVM*` and Activity/Context `jobject` for another host.
   Call it on the ImGui thread while the context object is valid. The bridge
   uses Android's `ClipboardManager`, converts UTF-16 to ordinary UTF-8, and
   releases its JNI global references in `shutdown()`. Without this optional
   call, the upstream Android backend's clipboard remains unavailable.
3. Send each `AInputEvent` to `impl_android.handle_input_event(event)`. The
   upstream backend maps mouse, pen, keyboard, and wheel events. This wrapper
   tracks touchscreen pointer IDs and maps a stable primary finger to ImGui's
   single mouse pointer; it promotes another active finger if the primary
   lifts. It does not expose independent simultaneous ImGui pointers. The
   wrapper also maps the first Android gamepad's face/shoulder/menu buttons,
   D-pad, sticks, and triggers to ImGui navigation input. Set
   `ImGuiConfigFlags_NavEnableGamepad` in the application if desired. Call
   `impl_android.clear_gamepad()` when focus is lost, and report Android
   `InputManager.InputDeviceListener.onInputDeviceRemoved(id)` through
   `impl_android.gamepad_disconnected(id)` to release held inputs. The sample
   host does both. Only one navigation controller is active at a time.
4. Each drawable frame: call `impl_vulkan.new_frame()`,
   `impl_android.new_frame()`, `imgui.new_frame()`, build UI,
   `imgui.render()`, and `impl_vulkan.render_draw_data(imgui.get_draw_data(),
   command_buffer, ...)` inside an active Vulkan render pass. Submit and
   present with the host application's Vulkan code.
5. If `impl_android.wants_text_input()` changes, call
   `ImGuiInputView.setKeyboardVisible(...)` on Android's UI thread. Include
   `android/java/io/antono2/imgui/ImGuiInputView.java` in the app and attach it
   to the Activity's view hierarchy. For selection-aware editing, give each
   `InputText` widget the `callback_always` flag and call
   `impl_android.apply_text_edit(mut data)` from its V callback. This opts in
   to a stateful Java `InputConnection`: the Java side keeps text and selection
   in UTF-16; the callback applies the latest edit and publishes ImGui's text
   and UTF-8-byte selection back to Java. Changes made with ImGui's pointer or
   hardware keys become visible to the IME. The helper returns whether it
   applied a pending Java edit. Without the callback, the Java view retains
   the earlier committed-text and basic-key fallback. Applications with their
   own `InputConnection` may instead call `impl_android.text_utf8(...)` on the
   render thread. Preedit is displayed as plain text; inline underlining,
   candidate geometry, and rich marked-text ranges are not implemented.
   The OS can hide the keyboard with Back while `WantTextInput` remains true;
   re-request it when the user taps the still-active field, as the sample host
   does, rather than relying only on `WantTextInput` transitions.
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
together. Its Text field uses the selection-aware callback and displays active
ImGui cursor and selection offsets in UTF-8 bytes. The Android
`InputConnection` synchronizes text and selection; composing text appears
without underline or marked-range styling. The sample's Copy text and Read
clipboard buttons exercise the optional Android clipboard bridge.

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
   ImGui's primary pointer, with another active touch promoted when it ends.
   Forward hardware keys through `impl_ios.key(...)`
   and committed UTF-8 text through `impl_ios.text_utf8(...)`. Use
   `impl_ios.wants_text_input()` to show or hide a UIKit text responder. The
   optional `impl_ios.keyboard_create(parent_view)` attaches a small `UIKeyInput`
   responder to an app-owned `UIView`; call
   `impl_ios.keyboard_set_visible(keyboard, impl_ios.wants_text_input())` after
   each rendered frame and `impl_ios.keyboard_destroy(keyboard)` before the
   parent view is destroyed. The caller owns the opaque handle and must make
   all three calls on the UIKit thread. It feeds committed text and Backspace
   into ImGui without requiring V to bind UIKit types directly. `UIKeyInput`
   supports only simple text entry: rich marked-text composition, selection
   ranges, candidate positioning, and full language coverage require a future
   `UITextInput`-based integration. Hosts needing those features should supply
   their own UIKit text view and feed committed text through `text_utf8`.
   Clipboard reads and writes use `UIPasteboard` and should occur on the main
   thread. Inline marked-text composition and a packaged UITextInput view are
   not part of this first pass. `impl_ios.new_frame` also polls the first
   connected `GCExtendedGamepad`, maps its controls to ImGui navigation, and
   clears held inputs on disconnect. Set `ImGuiConfigFlags_NavEnableGamepad`
   to enable navigation; the sample app does this. Call `new_frame` on the
   UIKit thread that owns the ImGui context.
5. Ensure command buffers using ImGui resources are complete, call
   `impl_metal.shutdown()`, then the platform shutdown, then destroy the ImGui
   context.

The Metal wrapper and upstream renderer are compiled as Objective-C++ with
ARC. Android never compiles them; Apple never compiles the Android backend.
The macOS build also compiles upstream `imgui_impl_osx.mm`. Both Apple builds
link `GameController`; the iOS build does not pull in AppKit/Cocoa.

`examples/ios_metal` is a minimal UIKit/`MTKView` host. It creates the Metal
device, render pass, command buffer, and encoder, and uses the same iOS/Metal
wrappers exposed to V. It renders independently movable `Controls` and
`Workspace` ImGui windows within one `MTKView`, without native UIKit scenes or
Dear ImGui platform viewports. V applications use the same pattern: call
`imgui.begin(...)` / `imgui.end()` for each window between one
`imgui.new_frame()` and `imgui.render()`, then submit the combined draw data
through `impl_metal` once. The bundled app is built unsigned for both simulator
architectures and iPhoneOS in CI; the matching GitHub-hosted simulator job also
attempts to launch it and complete one Metal command buffer with both windows
visible. That runtime step is
advisory because a hosted runner may lack a usable simulator Metal device.
The app includes an `InputText` field backed by the optional `UIKeyInput`
responder. It demonstrates keyboard visibility and simple committed text, but
does not claim complete iOS IME handling; a host needing marked-text and
selection support still needs a `UITextInput` integration.

The Android sample is an integration host, not a reusable application shell;
the Vulkan/NativeActivity host remains C++ while the ImGui widgets are written
in V. Android uses upstream's platform backend plus this repository's
touch, gamepad, IME, and optional clipboard extensions.
The on-screen iOS sample demonstrates rendering, touch, and basic keyboard
input. The iOS layer handles one primary touch; complete marked-text and
selection support remains the host app's responsibility.

## Validation boundaries

`mobile-native.yml` renders an offscreen ImGui frame through Lavapipe on Ubuntu,
then builds and link-tests the Android native backend, on-screen host, V UI,
and IME Java class for three ABIs, cross-links a small V app, and packages a
debug APK for each ABI. It builds and
link-tests Metal/FreeType on GitHub-hosted macOS for
macOS, both iOS Simulator architectures, and arm64 iPhoneOS. The iOS jobs
also link a UIKit/Metal app; the host-architecture simulator job makes an
advisory runtime frame attempt. No developer signing or attached Apple
hardware is required for the compile/link jobs. On a connected Android
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
