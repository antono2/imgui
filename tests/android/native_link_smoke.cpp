#include "../../cimgui/imgui/imgui.h"
#include "../../cimgui/imgui/imgui_internal.h"
#include "../../cimgui/cimgui.h"
#include "../../cimgui/imgui/backends/imgui_impl_vulkan.h"
#include "../../native/android/vimgui_android.h"

// The library is linked into an Android ELF, but this entry point is never
// executed by CI. A device test must provide a real window and Vulkan device.
extern "C" int vimgui_android_link_smoke(void* native_window, const void* event)
{
    ImGuiContext* context = igCreateContext(nullptr);
    if (context == nullptr)
        return 1;

    int result = 0;
    if (native_window != nullptr && vimgui_android_init(native_window))
    {
        result = event != nullptr ? vimgui_android_handle_input_event(event) : 0;
        vimgui_android_shutdown();
    }

    // This intentionally references the Vulkan backend from the final ELF.
    // No Vulkan state is needed because the branch is not run in CI.
    if (result == -1)
        ImGui_ImplVulkan_NewFrame();

    igDestroyContext(context);
    return result;
}
