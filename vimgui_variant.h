#ifndef VIMGUI_VARIANT_H
#define VIMGUI_VARIANT_H

#include "cimgui.h"

static inline bool vimgui_configure_docking(bool enabled) {
    ImGuiIO *io = igGetIO_Nil();
    if (enabled) {
        io->ConfigFlags |= ImGuiConfigFlags_DockingEnable;
    } else {
        io->ConfigFlags &= ~ImGuiConfigFlags_DockingEnable;
    }
    return true;
}

static inline bool vimgui_configure_platform_viewports(bool enabled) {
    ImGuiIO *io = igGetIO_Nil();
    if (enabled) {
        io->ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;
    } else {
        io->ConfigFlags &= ~ImGuiConfigFlags_ViewportsEnable;
    }
    return true;
}

static inline bool vimgui_create_main_dockspace(void) {
    igDockSpaceOverViewport(0, NULL, ImGuiDockNodeFlags_None, NULL);
    return true;
}

static inline void vimgui_render_platform_viewports(void) {
    ImGuiIO *io = igGetIO_Nil();
    if ((io->ConfigFlags & ImGuiConfigFlags_ViewportsEnable) != 0) {
        igUpdatePlatformWindows();
        igRenderPlatformWindowsDefault(NULL, NULL);
    }
}

#endif
