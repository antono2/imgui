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
void vimgui_android_shutdown(void);

#ifdef __cplusplus
}
#endif
