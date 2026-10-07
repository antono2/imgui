// Declares the iOS input and keyboard bridge consumed by native hosts and V bindings.
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
// Optional UITextView-backed IME. UIKit calls and InputText callbacks must run
// on the main thread. The caller owns the handle. Error codes: 0=OK,
// 1=invalid handle/thread, 2=text exceeds ImGui buffer, 3=invalid callback.
void* vimgui_ios_text_view_create(void* parent_view);
bool vimgui_ios_text_view_set_visible(void* text_view, bool visible);
bool vimgui_ios_text_view_apply_edit(void* text_view, void* callback_data);
bool vimgui_ios_text_view_marked_range(void* text_view, int32_t* start, int32_t* end);
void vimgui_ios_text_view_set_anchor(void* text_view, float x, float y);
int32_t vimgui_ios_text_view_error(void* text_view);
void vimgui_ios_text_view_destroy(void* text_view);
void vimgui_ios_shutdown(void);

#ifdef __cplusplus
}
#endif
