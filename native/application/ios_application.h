#pragma once
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
// The linked application library initializes its runtime before UIApplicationMain.
// All hooks run on the UIKit main thread. State outlives renderer recreation;
// end releases a view's participation, not live jobs or retained application state.
bool vimgui_ios_application_begin(const char *state_path, float text_scale, void *view_controller);
void vimgui_ios_application_mount(float text_scale);
bool vimgui_ios_application_draw(void);
void vimgui_ios_application_end(void);
const char *vimgui_ios_application_title(void);
#ifdef __cplusplus
}
#endif
