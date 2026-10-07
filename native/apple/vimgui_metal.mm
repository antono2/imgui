// Adapts opaque C handles to Metal objects for ImGui renderer lifecycle calls.
#include "vimgui_metal.h"

#include "../../cimgui/imgui/backends/imgui_impl_metal.h"
#import <Metal/Metal.h>

extern "C" bool vimgui_metal_init(void* device)
{
    return device != nullptr && ImGui_ImplMetal_Init((__bridge id<MTLDevice>)device);
}

extern "C" void vimgui_metal_new_frame(void* render_pass_descriptor)
{
    ImGui_ImplMetal_NewFrame((__bridge MTLRenderPassDescriptor*)render_pass_descriptor);
}

extern "C" void vimgui_metal_render_draw_data(void* draw_data, void* command_buffer, void* render_command_encoder)
{
    ImGui_ImplMetal_RenderDrawData(static_cast<ImDrawData*>(draw_data),
                                  (__bridge id<MTLCommandBuffer>)command_buffer,
                                  (__bridge id<MTLRenderCommandEncoder>)render_command_encoder);
}

extern "C" void vimgui_metal_shutdown(void)
{
    ImGui_ImplMetal_Shutdown();
}
