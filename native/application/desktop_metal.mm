// Adapted from Dear ImGui's GLFW + Metal example (MIT, see cimgui/imgui/LICENSE.txt).
#include "vimgui_app.h"
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_metal.h"
#include <cstdio>
#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

int vimgui_app_run(const char *title, int width, int height,
                   vimgui_app_frame frame, void *data, int smoke_frames) {
    if (!frame || !glfwInit()) return 1;
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow *window=glfwCreateWindow(width,height,title,nullptr,nullptr);
    if (!window) { glfwTerminate(); return 2; }
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> queue=[device newCommandQueue];
    if (!device || !queue) { glfwDestroyWindow(window); glfwTerminate(); return 3; }
    IMGUI_CHECKVERSION(); ImGui::CreateContext();
    auto &io=ImGui::GetIO(); io.IniFilename=nullptr;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard | ImGuiConfigFlags_NavEnableGamepad;
    ImGui_ImplGlfw_InitForOther(window,true);
    ImGui_ImplMetal_Init(device);
    NSWindow *native=glfwGetCocoaWindow(window);
    CAMetalLayer *layer=[CAMetalLayer layer];
    layer.device=device; layer.pixelFormat=MTLPixelFormatBGRA8Unorm;
    native.contentView.layer=layer; native.contentView.wantsLayer=YES;
    int result=0, frames=0;
    if (!vimgui_app_initialize(title) || !vimgui_accessibility_attach(vimgui_app_accessibility(),(__bridge void*)native,nullptr)) result=4;
    else vimgui_app_theme(true,false,1,false);
    while (!result && !glfwWindowShouldClose(window)) {
        @autoreleasepool {
            glfwPollEvents();
            int w,h; glfwGetFramebufferSize(window,&w,&h);
            if (w<=0 || h<=0) { glfwWaitEventsTimeout(0.05); continue; }
            layer.drawableSize=CGSizeMake(w,h);
            id<CAMetalDrawable> drawable=[layer nextDrawable];
            if (!drawable) continue;
            MTLRenderPassDescriptor *pass=[MTLRenderPassDescriptor renderPassDescriptor];
            pass.colorAttachments[0].texture=drawable.texture;
            pass.colorAttachments[0].loadAction=MTLLoadActionClear;
            pass.colorAttachments[0].storeAction=MTLStoreActionStore;
            pass.colorAttachments[0].clearColor=MTLClearColorMake(.08,.12,.09,1);
            ImGui_ImplMetal_NewFrame(pass); ImGui_ImplGlfw_NewFrame(); ImGui::NewFrame();
            vimgui_app_frame_begin(); frame(data);
            if (!vimgui_app_frame_end()) { std::fprintf(stderr,"%s\n",vimgui_app_error()); result=5; }
            vimgui_accessibility_window_state(vimgui_app_accessibility(),native.keyWindow,0,0,width,height);
            vimgui_accessibility_update(vimgui_app_accessibility());
            ImGui::Render();
            id<MTLCommandBuffer> command=[queue commandBuffer];
            id<MTLRenderCommandEncoder> encoder=[command renderCommandEncoderWithDescriptor:pass];
            ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(),command,encoder);
            [encoder endEncoding]; [command presentDrawable:drawable]; [command commit];
            if (smoke_frames>0 && ++frames>=smoke_frames) break;
        }
    }
    vimgui_app_shutdown(); ImGui_ImplMetal_Shutdown(); ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext(); glfwDestroyWindow(window); glfwTerminate();
    return result;
}
