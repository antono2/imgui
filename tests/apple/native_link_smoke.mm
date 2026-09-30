#include "../../cimgui/imgui/imgui.h"
#include "../../cimgui/imgui/imgui_internal.h"
#include "../../cimgui/cimgui.h"
#include "../../native/apple/vimgui_metal.h"

#if VIMGUI_TEST_IOS
#include "../../native/apple/vimgui_ios.h"
#else
#include "../../native/apple/vimgui_osx.h"
#endif

extern "C" int vimgui_apple_link_smoke(void* host_view, void* device,
                                        void* render_pass, void* command_buffer,
                                        void* command_encoder)
{
    ImGuiContext* context = igCreateContext(nullptr);
    if (context == nullptr)
        return 1;

#if VIMGUI_TEST_IOS
    bool platform_ready = vimgui_ios_init();
    if (platform_ready)
        vimgui_ios_new_frame(100.0f, 100.0f, 2.0f, 1.0f / 60.0f);
    // Keep the optional UIKit keyboard entry points in the linked test.
    if (host_view != nullptr && platform_ready)
    {
        void* keyboard = vimgui_ios_keyboard_create(host_view);
        vimgui_ios_keyboard_set_visible(keyboard, false);
        vimgui_ios_keyboard_destroy(keyboard);
        void* text_view = vimgui_ios_text_view_create(host_view);
        vimgui_ios_text_view_set_anchor(text_view, 0.0f, 0.0f);
        int32_t start = 0, end = 0;
        vimgui_ios_text_view_marked_range(text_view, &start, &end);
        vimgui_ios_text_view_error(text_view);
        vimgui_ios_text_view_set_visible(text_view, false);
        vimgui_ios_text_view_destroy(text_view);
    }
#else
    bool platform_ready = host_view != nullptr && vimgui_osx_init(host_view);
    if (platform_ready)
        vimgui_osx_new_frame(host_view);
#endif

    if (device != nullptr && render_pass != nullptr && command_buffer != nullptr && command_encoder != nullptr)
    {
        if (vimgui_metal_init(device))
        {
            vimgui_metal_new_frame(render_pass);
            vimgui_metal_render_draw_data(igGetDrawData(), command_buffer, command_encoder);
            vimgui_metal_shutdown();
        }
    }

    if (platform_ready)
    {
#if VIMGUI_TEST_IOS
        vimgui_ios_shutdown();
#else
        vimgui_osx_shutdown();
#endif
    }
    igDestroyContext(context);
    return 0;
}
