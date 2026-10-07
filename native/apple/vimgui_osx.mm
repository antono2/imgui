// Adapts application-owned Cocoa views to the ImGui macOS backend.
#include "vimgui_osx.h"

#include "../../cimgui/imgui/backends/imgui_impl_osx.h"
#import <AppKit/AppKit.h>

extern "C" bool vimgui_osx_init(void* ns_view)
{
    return ns_view != nullptr && ImGui_ImplOSX_Init((__bridge NSView*)ns_view);
}

extern "C" void vimgui_osx_new_frame(void* ns_view)
{
    ImGui_ImplOSX_NewFrame((__bridge NSView*)ns_view);
}

extern "C" void vimgui_osx_shutdown(void)
{
    ImGui_ImplOSX_Shutdown();
}
