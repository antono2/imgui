#include "../../cimgui/imgui/imgui.h"
#include "../../native/mobile/vimgui_scale.h"
#include <vulkan/vulkan.h>

#include <cstdio>
#include <vector>

int main()
{
    ImGuiContext* context = ImGui::CreateContext();
    if (context == nullptr)
        return 1;
    if (!vimgui_mobile_set_ui_scale(1.5f) || ImGui::GetStyle().FontScaleMain != 1.5f)
        return 5;
    if (!vimgui_mobile_set_ui_scale(2.0f) || ImGui::GetStyle().FontScaleMain != 2.0f)
        return 6;
    std::printf("Dear ImGui %s context ready\n", ImGui::GetVersion());
    ImGui::DestroyContext(context);

    VkApplicationInfo application_info = {};
    application_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    application_info.pApplicationName = "vimgui-device-probe";
    application_info.apiVersion = VK_API_VERSION_1_0;
    VkInstanceCreateInfo create_info = {};
    create_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    create_info.pApplicationInfo = &application_info;

    VkInstance instance = VK_NULL_HANDLE;
    VkResult result = vkCreateInstance(&create_info, nullptr, &instance);
    if (result != VK_SUCCESS)
    {
        std::fprintf(stderr, "vkCreateInstance failed: %d\n", static_cast<int>(result));
        return 2;
    }

    uint32_t count = 0;
    result = vkEnumeratePhysicalDevices(instance, &count, nullptr);
    if (result != VK_SUCCESS || count == 0)
    {
        std::fprintf(stderr, "No Vulkan physical device: %d\n", static_cast<int>(result));
        vkDestroyInstance(instance, nullptr);
        return 3;
    }
    std::vector<VkPhysicalDevice> devices(count);
    result = vkEnumeratePhysicalDevices(instance, &count, devices.data());
    if (result == VK_SUCCESS)
    {
        VkPhysicalDeviceProperties properties = {};
        vkGetPhysicalDeviceProperties(devices[0], &properties);
        std::printf("Vulkan GPU: %s, API %u.%u.%u\n", properties.deviceName,
                    VK_API_VERSION_MAJOR(properties.apiVersion),
                    VK_API_VERSION_MINOR(properties.apiVersion),
                    VK_API_VERSION_PATCH(properties.apiVersion));
    }
    vkDestroyInstance(instance, nullptr);
    return result == VK_SUCCESS ? 0 : 4;
}
