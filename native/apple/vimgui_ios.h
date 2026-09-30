#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Dimensions and touch coordinates are in UIKit points, not pixels.
bool vimgui_ios_init(void);
void vimgui_ios_new_frame(float width, float height, float framebuffer_scale, float delta_seconds);
void vimgui_ios_touch(uint64_t touch_id, float x, float y, bool down);
void vimgui_ios_key(int32_t imgui_key, bool down);
void vimgui_ios_text_utf8(const char* committed_text);
bool vimgui_ios_wants_text_input(void);
// Optional UIKit UIKeyInput responder. Create/destroy on the UIKit thread;
// the opaque handle is owned by the caller and must be destroyed before the
// parent UIView. This supports committed text and Backspace, not marked text.
void* vimgui_ios_keyboard_create(void* parent_view);
bool vimgui_ios_keyboard_set_visible(void* keyboard, bool visible);
void vimgui_ios_keyboard_destroy(void* keyboard);
void vimgui_ios_shutdown(void);

#ifdef __cplusplus
}
#endif
