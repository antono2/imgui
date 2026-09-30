#undef IMGUI_IMPL_VULKAN_NO_PROTOTYPES
#include "../../cimgui/imgui/imgui.h"
#include "../../cimgui/imgui/backends/imgui_impl_vulkan.h"
#include "../../native/mobile/vimgui_scale.h"

#include <vulkan/vulkan.h>

#include <cstdio>
#include <cstdlib>
#include <vector>

static void require_vk(VkResult result, const char* operation)
{
    if (result != VK_SUCCESS)
    {
        std::fprintf(stderr, "%s failed: %d\n", operation, static_cast<int>(result));
        std::exit(10);
    }
}

static PFN_vkVoidFunction load_vulkan(const char* name, void* user_data)
{
    return vkGetInstanceProcAddr(*static_cast<VkInstance*>(user_data), name);
}

static uint32_t memory_type(VkPhysicalDevice physical_device, uint32_t bits)
{
    VkPhysicalDeviceMemoryProperties properties = {};
    vkGetPhysicalDeviceMemoryProperties(physical_device, &properties);
    for (uint32_t i = 0; i < properties.memoryTypeCount; ++i)
        if ((bits & (1u << i)) && (properties.memoryTypes[i].propertyFlags & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
            return i;
    std::fprintf(stderr, "No device-local image memory type\n");
    std::exit(11);
}

int main()
{
    VkApplicationInfo application = {};
    application.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    application.pApplicationName = "vimgui-offscreen-probe";
    application.apiVersion = VK_API_VERSION_1_0;
    VkInstanceCreateInfo instance_info = {};
    instance_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    instance_info.pApplicationInfo = &application;
    const char* instance_extensions[] = {VK_KHR_SURFACE_EXTENSION_NAME};
    instance_info.enabledExtensionCount = 1;
    instance_info.ppEnabledExtensionNames = instance_extensions;
    VkInstance instance = VK_NULL_HANDLE;
    require_vk(vkCreateInstance(&instance_info, nullptr, &instance), "vkCreateInstance");

    uint32_t device_count = 0;
    require_vk(vkEnumeratePhysicalDevices(instance, &device_count, nullptr), "vkEnumeratePhysicalDevices count");
    if (device_count == 0)
        return 12;
    std::vector<VkPhysicalDevice> physical_devices(device_count);
    require_vk(vkEnumeratePhysicalDevices(instance, &device_count, physical_devices.data()), "vkEnumeratePhysicalDevices");
    VkPhysicalDevice physical_device = physical_devices[0];

    uint32_t family_count = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &family_count, nullptr);
    std::vector<VkQueueFamilyProperties> families(family_count);
    vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &family_count, families.data());
    uint32_t queue_family = UINT32_MAX;
    for (uint32_t i = 0; i < family_count; ++i)
        if (families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT)
        {
            queue_family = i;
            break;
        }
    if (queue_family == UINT32_MAX)
        return 13;

    float priority = 1.0f;
    VkDeviceQueueCreateInfo queue_info = {};
    queue_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queue_info.queueFamilyIndex = queue_family;
    queue_info.queueCount = 1;
    queue_info.pQueuePriorities = &priority;
    VkDeviceCreateInfo device_info = {};
    device_info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    device_info.queueCreateInfoCount = 1;
    device_info.pQueueCreateInfos = &queue_info;
    const char* device_extensions[] = {VK_KHR_SWAPCHAIN_EXTENSION_NAME};
    device_info.enabledExtensionCount = 1;
    device_info.ppEnabledExtensionNames = device_extensions;
    VkDevice device = VK_NULL_HANDLE;
    require_vk(vkCreateDevice(physical_device, &device_info, nullptr, &device), "vkCreateDevice");
    VkQueue queue = VK_NULL_HANDLE;
    vkGetDeviceQueue(device, queue_family, 0, &queue);

    VkImageCreateInfo image_info = {};
    image_info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    image_info.imageType = VK_IMAGE_TYPE_2D;
    image_info.format = VK_FORMAT_R8G8B8A8_UNORM;
    image_info.extent = {256, 256, 1};
    image_info.mipLevels = 1;
    image_info.arrayLayers = 1;
    image_info.samples = VK_SAMPLE_COUNT_1_BIT;
    image_info.tiling = VK_IMAGE_TILING_OPTIMAL;
    image_info.usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    VkImage image = VK_NULL_HANDLE;
    require_vk(vkCreateImage(device, &image_info, nullptr, &image), "vkCreateImage");
    VkMemoryRequirements memory_requirements = {};
    vkGetImageMemoryRequirements(device, image, &memory_requirements);
    VkMemoryAllocateInfo allocation = {};
    allocation.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocation.allocationSize = memory_requirements.size;
    allocation.memoryTypeIndex = memory_type(physical_device, memory_requirements.memoryTypeBits);
    VkDeviceMemory image_memory = VK_NULL_HANDLE;
    require_vk(vkAllocateMemory(device, &allocation, nullptr, &image_memory), "vkAllocateMemory");
    require_vk(vkBindImageMemory(device, image, image_memory, 0), "vkBindImageMemory");

    VkImageViewCreateInfo view_info = {};
    view_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    view_info.image = image;
    view_info.viewType = VK_IMAGE_VIEW_TYPE_2D;
    view_info.format = image_info.format;
    view_info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    view_info.subresourceRange.levelCount = 1;
    view_info.subresourceRange.layerCount = 1;
    VkImageView view = VK_NULL_HANDLE;
    require_vk(vkCreateImageView(device, &view_info, nullptr, &view), "vkCreateImageView");

    VkAttachmentDescription attachment = {};
    attachment.format = image_info.format;
    attachment.samples = VK_SAMPLE_COUNT_1_BIT;
    attachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    attachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    attachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    attachment.finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    VkAttachmentReference color_reference = {0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL};
    VkSubpassDescription subpass = {};
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &color_reference;
    VkRenderPassCreateInfo pass_info = {};
    pass_info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    pass_info.attachmentCount = 1;
    pass_info.pAttachments = &attachment;
    pass_info.subpassCount = 1;
    pass_info.pSubpasses = &subpass;
    VkRenderPass render_pass = VK_NULL_HANDLE;
    require_vk(vkCreateRenderPass(device, &pass_info, nullptr, &render_pass), "vkCreateRenderPass");
    VkFramebufferCreateInfo framebuffer_info = {};
    framebuffer_info.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    framebuffer_info.renderPass = render_pass;
    framebuffer_info.attachmentCount = 1;
    framebuffer_info.pAttachments = &view;
    framebuffer_info.width = 256;
    framebuffer_info.height = 256;
    framebuffer_info.layers = 1;
    VkFramebuffer framebuffer = VK_NULL_HANDLE;
    require_vk(vkCreateFramebuffer(device, &framebuffer_info, nullptr, &framebuffer), "vkCreateFramebuffer");

    VkCommandPoolCreateInfo pool_info = {};
    pool_info.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pool_info.queueFamilyIndex = queue_family;
    VkCommandPool command_pool = VK_NULL_HANDLE;
    require_vk(vkCreateCommandPool(device, &pool_info, nullptr, &command_pool), "vkCreateCommandPool");
    VkCommandBufferAllocateInfo command_info = {};
    command_info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    command_info.commandPool = command_pool;
    command_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    command_info.commandBufferCount = 1;
    VkCommandBuffer command_buffer = VK_NULL_HANDLE;
    require_vk(vkAllocateCommandBuffers(device, &command_info, &command_buffer), "vkAllocateCommandBuffers");

    ImGuiContext* context = ImGui::CreateContext();
    if (!vimgui_mobile_set_ui_scale(1.5f))
        return 14;
    if (!ImGui_ImplVulkan_LoadFunctions(VK_API_VERSION_1_0, load_vulkan, &instance))
        return 15;
    ImGui_ImplVulkan_InitInfo imgui_info = {};
    imgui_info.ApiVersion = VK_API_VERSION_1_0;
    imgui_info.Instance = instance;
    imgui_info.PhysicalDevice = physical_device;
    imgui_info.Device = device;
    imgui_info.QueueFamily = queue_family;
    imgui_info.Queue = queue;
    imgui_info.DescriptorPoolSize = 32;
    imgui_info.MinImageCount = 2;
    imgui_info.ImageCount = 2;
    imgui_info.PipelineInfoMain.RenderPass = render_pass;
    imgui_info.PipelineInfoMain.MSAASamples = VK_SAMPLE_COUNT_1_BIT;
    if (!ImGui_ImplVulkan_Init(&imgui_info))
        return 16;

    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    io.DisplaySize = ImVec2(256, 256);
    io.DeltaTime = 1.0f / 60.0f;
    ImGui_ImplVulkan_NewFrame();
    ImGui::NewFrame();
    ImGui::SetNextWindowPos(ImVec2(10, 10));
    ImGui::SetNextWindowSize(ImVec2(220, 180));
    bool visible = ImGui::Begin("Android Vulkan / FreeType");
    std::printf("ImGui window visible: %d, display %.0fx%.0f\n", visible, io.DisplaySize.x, io.DisplaySize.y);
    ImGui::Text("GPU rasterized frame");
    ImGui::End();
    ImGui::Render();
    std::printf("ImGui vertices: %d, lists: %d\n", ImGui::GetDrawData()->TotalVtxCount,
                ImGui::GetDrawData()->CmdLists.Size);
    if (ImGui::GetDrawData()->TotalVtxCount == 0)
        return 17;

    VkCommandBufferBeginInfo begin_info = {};
    begin_info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    require_vk(vkBeginCommandBuffer(command_buffer, &begin_info), "vkBeginCommandBuffer");
    VkClearValue clear = {};
    clear.color.float32[0] = 0.1f;
    clear.color.float32[1] = 0.2f;
    clear.color.float32[2] = 0.3f;
    clear.color.float32[3] = 1.0f;
    VkRenderPassBeginInfo pass_begin = {};
    pass_begin.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    pass_begin.renderPass = render_pass;
    pass_begin.framebuffer = framebuffer;
    pass_begin.renderArea.extent = {256, 256};
    pass_begin.clearValueCount = 1;
    pass_begin.pClearValues = &clear;
    vkCmdBeginRenderPass(command_buffer, &pass_begin, VK_SUBPASS_CONTENTS_INLINE);
    ImGui_ImplVulkan_RenderDrawData(ImGui::GetDrawData(), command_buffer);
    vkCmdEndRenderPass(command_buffer);
    require_vk(vkEndCommandBuffer(command_buffer), "vkEndCommandBuffer");
    VkSubmitInfo submit = {};
    submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command_buffer;
    require_vk(vkQueueSubmit(queue, 1, &submit, VK_NULL_HANDLE), "vkQueueSubmit");
    require_vk(vkQueueWaitIdle(queue), "vkQueueWaitIdle");

    std::printf("Rendered one offscreen ImGui frame through Vulkan\n");
    ImGui_ImplVulkan_Shutdown();
    ImGui::DestroyContext(context);
    vkDestroyCommandPool(device, command_pool, nullptr);
    vkDestroyFramebuffer(device, framebuffer, nullptr);
    vkDestroyRenderPass(device, render_pass, nullptr);
    vkDestroyImageView(device, view, nullptr);
    vkDestroyImage(device, image, nullptr);
    vkFreeMemory(device, image_memory, nullptr);
    vkDestroyDevice(device, nullptr);
    vkDestroyInstance(instance, nullptr);
    return 0;
}
