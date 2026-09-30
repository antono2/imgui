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
void vimgui_ios_shutdown(void);

#ifdef __cplusplus
}
#endif
