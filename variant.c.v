module imgui

#flag -I @VMODROOT

#flag -I @VMODROOT/include

#include "vimgui_variant.h"

fn C.vimgui_configure_docking(enabled bool) bool

fn C.vimgui_configure_platform_viewports(enabled bool) bool

fn C.vimgui_create_main_dockspace() bool

fn C.vimgui_render_platform_viewports()

// configure_docking enables or disables docking when the selected upstream
// variant supports it. It returns false for the standard variant.
pub fn configure_docking(enabled bool) bool {
	return C.vimgui_configure_docking(enabled)
}

// configure_platform_viewports enables or disables secondary OS windows when
// supported by the selected upstream variant. It returns false for standard.
pub fn configure_platform_viewports(enabled bool) bool {
	return C.vimgui_configure_platform_viewports(enabled)
}

// create_main_dockspace creates a dockspace over the main viewport when
// docking is available. It returns false for the standard variant.
pub fn create_main_dockspace() bool {
	return C.vimgui_create_main_dockspace()
}

// render_platform_viewports updates and renders secondary OS windows when
// that feature is enabled. It is a no-op for the standard variant.
pub fn render_platform_viewports() {
	C.vimgui_render_platform_viewports()
}
