// Declares the C boundary around the Objective-C Metal renderer backend.
#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Objective-C Metal objects are borrowed pointers owned by the host app.
bool vimgui_metal_init(void* device);
void vimgui_metal_new_frame(void* render_pass_descriptor);
void vimgui_metal_render_draw_data(void* draw_data, void* command_buffer, void* render_command_encoder);
void vimgui_metal_shutdown(void);

#ifdef __cplusplus
}
#endif
