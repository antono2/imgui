#ifndef VIMGUI_VARIANT_H
#define VIMGUI_VARIANT_H

#include <stdbool.h>

static inline bool vimgui_configure_docking(bool enabled) {
    (void)enabled;
    return false;
}

static inline bool vimgui_configure_platform_viewports(bool enabled) {
    (void)enabled;
    return false;
}

static inline bool vimgui_create_main_dockspace(void) {
    return false;
}

static inline void vimgui_render_platform_viewports(void) {
}

#endif
