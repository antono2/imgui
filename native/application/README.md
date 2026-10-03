# Application UI (development preview)

This optional layer supplies stable widget identities, a retained accessibility tree,
virtualized lists, high-contrast styling, text scaling, and native action routing.
`appui/` is a small V module independent of the generated ImGui/ImPlot bindings.
The existing raw bindings and mobile backend profiles remain available.

## Desktop build

Install CMake, a C++17 compiler, and GLFW; Linux also needs Vulkan, D-Bus,
ATK and ATK Bridge development headers, and a driver. Run `./scripts/build_appui.vsh`
from the repository. Native adapters use AT-SPI on Linux, UI Automation on Windows,
AppKit on macOS, UIKit on iOS, and AccessibilityNodeProvider on Android. Windows currently
runs the same script with `v run scripts/build_appui.vsh` from a developer shell,
with GLFW and the Vulkan SDK configured.
The desktop folder chooser uses Native File Dialog Extended 1.3.0 (Zlib license),
downloaded by CMake with a pinned SHA-256. Its Linux portal backend uses the
desktop's configured chooser; the running desktop must provide that portal.
`pick_folder(initial_path)` returns the selected folder, an empty string for
cancellation, or an error. Mobile hosts supply their platform picker and grants.

Build the V example with this checkout available as `antono2/imgui` on V's module
path. `examples/accessible_review/main.v` exercises 100,000 synthetic rows.
`--smoke-test` exits after five rendered frames.

The standalone desktop host builds its own ImGui core. Do not link it alongside
a separate `libvimgui` in the same process. Embedding applications instead enable
`VIMGUI_APPLICATION_UI=ON` in the root CMake project and use `-d appui_embedded`
with the V module. Their existing host owns the ImGui context and backend loop.
Call `initialize`, `begin_frame`, the UI callback, `end_frame`, and `shutdown` at
the corresponding lifecycle points.

`next_control_name` supplies context for repeated buttons, checkboxes, and radio
controls without making their visible labels longer. Include the visible label
in the accessible name so speech-control users can identify the control.

`same_line_for(label, choice)` keeps the next button (`choice=false`) or
checkbox/radio (`choice=true`) on the current row only when it fits using the
current font and padding. `same_line_width` handles controls with an explicit
width. Long button labels wrap within the available width. `reveal(id)` brings a newly opened screen's control into its parent viewport
without activating it or changing keyboard focus. Lists also expose a native
scroll-into-view action and retain room for up to three rows when preceding
controls consume the available height; their parent scrolls instead of collapsing
them into a sliver. Application windows
and panels expose vertical scroll actions when their content exceeds the view.
Touch themes reserve a 48-unit scrollbar and minimum thumb before display scaling;
desktop themes use a 20-unit track and 24-unit minimum thumb. List swipes start
only inside the content area so they cannot fight a scrollbar drag. High-contrast
styling also applies to the thumb. Theme scale supports 0.5–16 so physical display
density and text enlargement can be combined without capping 200% text at scale 3.
Input labels wrap, and fields stay within their available width.

`scroll(id)` returns the cached vertical position of the root (`id=1`) or a
virtualized list. Save it with the application's view state. `restore_scroll(id,
y)` applies a nonnegative position when that container is next drawn, including
after `list_reset` or renderer recreation. Positions are clamped to current
content. `back_requested()` reports AppBack or Alt+Left; the application owns its
navigation history. The Android application host can call optional
`vimgui_android_application_can_back` and `vimgui_android_application_back`
exports to route the system Back key, falling through at the root view.

An embedding host can install `set_text_edit_handler` to apply its platform's
selection-aware IME edits to the active input. The callback receives borrowed
`ImGuiInputTextCallbackData*` and host userdata on the rendering thread. Android
hosts call `vimgui_android_apply_text_edit`; UIKit hosts call
`vimgui_ios_text_view_apply_edit` with their text-view handle.

## Android application host

`VIMGUI_ANDROID_APPLICATION_HOST=ON` with `VIMGUI_BUILD_ANDROID_DEMO=ON` and
`VIMGUI_APPLICATION_UI=ON` reuses the NativeActivity Vulkan host for an external
application. It excludes `VIMGUI_ANDROID_ACCESSIBLE_DEMO`. The Activity loads
`libvimgui_android_application.so` on the process main thread before creating
its native host. Applications using a collector must register every foreign
render thread and preserve their frontend state across renderer recreation.

The library exports `vimgui_android_application_begin(const char *state_path,
float scale)` (bool), `vimgui_android_application_mount(float scale)` (void),
`vimgui_android_application_draw()` (bool), and
`vimgui_android_application_end()` (void). Begin/end bracket the NativeActivity
render-thread lifetime. Mount runs after each application UI context is created
and when display density changes. Draw constructs widgets between the embedding
host's ImGui NewFrame/Render calls and owns the application UI frame transaction.
The supplied host converts its base 16sp font through Android `TypedValue`,
respecting display density and the system font-size preference at startup and
configuration changes. App text enlargement multiplies that base scale. Other
Android hosts can use `impl_android.ui_scale(vm, context, fallback)`.
Java hosts forward input-device removal to
`ImGuiInputView.notifyGamepadDisconnected(deviceId)`, whose JNI implementation
lives in the helper's explicitly loaded backend library.
An optional `vimgui_android_application_title()` returns a borrowed, persistent
UTF-8 title; its fallback is "Application". A false begin/draw return reports
failure and closes the Activity. The library remains loaded while its
retained state and workers exist. The Activity must expose the same keyboard and
accessibility helper methods used by the sample host.

## Native accessibility

The C accessibility context is independent of V and ImGui. Native callbacks enqueue
owned actions; they never enter V from a foreign thread. The UI thread stages a
transaction and commits a valid root/focus pair. Rejected commits preserve the
last published tree. Stable IDs must be nonzero and below 2^63; the high bit is
reserved for synthetic text runs and scroll-content containers. The application
layer reserves ID 1 for its root.

On mobile, the host passes the retained context to the OS main thread to attach
and update the native adapter. It must follow the platform adapter's lifetime
requirements and free it before releasing its native View/window. Safe-area values
are expressed in the same logical units as ImGui layout.

When rendering and native UI use different threads, retain the context before
passing it across threads. Detach the adapter on the OS UI thread before releasing
that thread's reference. The render owner can then free its detached reference
independently. `android/java/io/antono2/imgui/ImGuiAccessibility.java` implements
this ownership pattern, schedules accessibility updates on the UI thread, and
must be closed before its host View is destroyed. Load `libvimgui` before using
the Java helper; hosts should report `hasFailed()` and offer a retry.

`scripts/run_android_accessible.sh --build-only` packages an independent Android
test app with a 1,000-row list, editable search, and keeper action. Set
`ANDROID_SDK_ROOT`, `ANDROID_NDK_HOME`, and `ANDROID_ABI`; omit `--build-only` to
install and run it. It builds the native C++ bridge and Java node provider,
including `armeabi-v7a`.
This validates the reusable native widgets; it is not the duplicate-finder app.
`scripts/test_android_accessible.sh` builds and installs this app plus a separate
instrumentation package to exercise native accessibility and input. Set
`ANDROID_SERIAL` when more than one device is connected. It preserves the user's
configured accessibility services.

Linux end-to-end checks must run inside an isolated D-Bus session and X server:

```
GSETTINGS_BACKEND=memory dbus-run-session -- xvfb-run -a \
  build/native-atspi-smoke build/accessible-review
```

Compile the probe with `c++ -std=c++17 tests/accessibility/atspi_smoke.cpp $(pkg-config --cflags --libs atspi-2 gio-2.0) -o build/native-atspi-smoke`.
It requires the native AT-SPI development headers and the desktop accessibility bus. Native retained-tree tests are available
through CTest in `build/appui/accessibility`.
The desktop portal client can be checked without opening the user's chooser:

```
c++ -std=c++17 tests/accessibility/portal_picker.cpp $(pkg-config --cflags --libs gio-2.0) -ldl -pthread -o build/native-portal-check
GSETTINGS_BACKEND=memory dbus-run-session -- build/native-portal-check lib/appui/libvimgui_app.so
```

This uses a controlled portal to verify UTF-8 selection, initial-folder handling,
cancellation, and errors. Actual platform dialogs still need device validation.

## Current limits

This is a development preview, not a claim of complete platform accessibility.
Linux AT-SPI has been exercised end to end with 100,000 retained rows, off-screen
selection, scrolled bounds, button invocation, and editable search. The application retains every row; the native accessibility tree contains only
the viewport, adjacent rows, and any focused row awaiting a scroll. Stable row
identities and position/total metadata survive materialization. Android arm64 cross-builds; the 32-bit test host also
passes device instrumentation on an Android tablet: accessibility actions,
touch scrollbar drags, list swipes without selection, last-row geometry,
text replacement/selection, IME editing, high contrast,
text scaling, and Activity recreation. This does not replace human TalkBack
and switch-access testing.
Downstream consuming-application checks have also built the macOS Metal and
Windows Vulkan hosts and passed their retained accessibility-tree tests. The
iOS UIKit/Metal host completed simulator UI frames and a process restart while
retaining application data. These checks do not replace VoiceOver, Narrator,
physical-device, or platform folder-dialog interaction tests.

Outstanding work includes mobile host lifecycle and IME integration, Unicode
text segmentation beyond code points,
large-tree startup/filter latency across platforms, and a full assistive
technology/device test matrix. Applications own their file operations, persistent
jobs, navigation history, localization, and platform storage permissions.
