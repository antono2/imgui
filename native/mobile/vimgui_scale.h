#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Call after customizing the initial style and before the first frame.
bool vimgui_mobile_set_ui_scale(float scale);
void vimgui_mobile_reset_style_baseline(void);

#ifdef __cplusplus
}
#endif
