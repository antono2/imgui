// Declares the Android native input and lifecycle bridge shared by V and JNI callers.
#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque NDK pointers keep the V-facing header usable by a C compiler.
bool vimgui_android_init(void* native_window);
// Convert the base 16sp font to pixels through Android TypedValue, including
// density and system text size. Context is a borrowed JNI jobject. Query on
// startup/configuration changes; returns fallback when unavailable. No UI
// context is required and no device setting is changed.
float vimgui_android_ui_scale(void* java_vm, void* context, float fallback);
// Install Android's ClipboardManager after init. The context is a JNI jobject
// (for example ANativeActivity.clazz); the VM is a JavaVM*. Call on the ImGui
// thread while both objects are alive. shutdown releases the JNI references.
bool vimgui_android_set_clipboard_context(void* java_vm, void* context);
int32_t vimgui_android_handle_input_event(const void* input_event);
void vimgui_android_new_frame(void);
void vimgui_android_text_utf8(const char* committed_text);
bool vimgui_android_wants_text_input(void);
// Release navigation keys when the selected controller disconnects or focus is lost.
void vimgui_android_clear_gamepad(void);
// Thread-safe notification; releases the selected device on the next frame.
void vimgui_android_gamepad_disconnected(int32_t device_id);
// Call from InputText's CallbackAlways event to opt into the stateful IME path.
bool vimgui_android_apply_text_edit(void* callback_data);
void vimgui_android_shutdown(void);

#ifdef __cplusplus
}
#endif
