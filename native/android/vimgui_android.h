#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque NDK pointers keep the V-facing header usable by a C compiler.
bool vimgui_android_init(void* native_window);
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
