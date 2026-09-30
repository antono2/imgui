#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool vimgui_osx_init(void* ns_view);
void vimgui_osx_new_frame(void* ns_view);
void vimgui_osx_shutdown(void);

#ifdef __cplusplus
}
#endif
