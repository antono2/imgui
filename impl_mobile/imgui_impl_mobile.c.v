module impl_mobile

#flag -I @VMODROOT/native/mobile
#include "vimgui_scale.h"

fn C.vimgui_mobile_set_ui_scale(scale f32) bool
fn C.vimgui_mobile_reset_style_baseline()

// Scales both font rendering and widget metrics from a captured baseline.
// Call after styling, before the first ImGui frame; repeated calls are safe.
pub fn set_ui_scale(scale f32) bool {
	return C.vimgui_mobile_set_ui_scale(scale)
}

// Call after changing the style theme or creating a new ImGui context.
pub fn reset_style_baseline() {
	C.vimgui_mobile_reset_style_baseline()
}
