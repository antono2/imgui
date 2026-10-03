// Installable Android Vulkan integration test. The application owns Vulkan;
// the platform and renderer code remain the unmodified upstream backends.
#undef IMGUI_IMPL_VULKAN_NO_PROTOTYPES
#include "../../cimgui/imgui/imgui.h"
#include "../../cimgui/imgui/backends/imgui_impl_vulkan.h"
#include "../../native/android/vimgui_android.h"
#include "../../native/mobile/vimgui_scale.h"
#if defined(VIMGUI_ACCESSIBLE_DEMO) || defined(VIMGUI_APPLICATION_HOST)
#include "../../native/application/vimgui_app.h"
#ifdef VIMGUI_ACCESSIBLE_DEMO
extern "C" bool vimgui_android_accessible_draw(float*,int*,char*,int,char*,int,float,float);
#endif
#endif

#include <android/asset_manager.h>
#include <android/configuration.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android_native_app_glue.h>
#include <dlfcn.h>
#include <jni.h>
#include <vulkan/vulkan.h>

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <vector>

namespace {
constexpr const char* kLogTag = "vimgui-android-demo";
constexpr uint32_t kMinImageCount = 2;

struct DemoState {
    android_app* app = nullptr;
    ANativeWindow* native_window = nullptr;
    VkInstance instance = VK_NULL_HANDLE;
    VkSurfaceKHR surface = VK_NULL_HANDLE;
    VkPhysicalDevice physical_device = VK_NULL_HANDLE;
    VkDevice device = VK_NULL_HANDLE;
    uint32_t queue_family = UINT32_MAX;
    VkQueue queue = VK_NULL_HANDLE;
    ImGui_ImplVulkanH_Window window;
    ImGuiContext* imgui_context = nullptr;
    bool platform_ready = false;
    bool renderer_ready = false;
    bool focused = false;
    bool resize_pending = false;
    bool keyboard_visible = false;
    bool keyboard_request_on_touch = false;
    float density_scale = 1.0f;
    float zoom = 1.0f;
    int tap_count = 0;
    char text[128] = {};
    char clipboard_preview[1024] = {};
};

DemoState g;
using DrawUiFn = bool (*)(float*, int*, char*, int, char*, int, float, float);
void* ui_library = nullptr;
DrawUiFn draw_ui = nullptr;
#ifdef VIMGUI_APPLICATION_HOST
// The Activity loads this library on the process main thread before NativeActivity.
// The application owns retained state; the renderer owns each ImGui context.
using BeginAppFn = bool (*)(const char *,float);
using TitleAppFn = const char *(*)();
using MountAppFn = void (*)(float);
using DrawAppFn = bool (*)();
using EndAppFn = void (*)();
using BackAppFn = bool (*)();
BeginAppFn begin_app = nullptr;
TitleAppFn title_app = nullptr;
MountAppFn mount_app = nullptr;
DrawAppFn draw_app = nullptr;
EndAppFn end_app = nullptr;
BackAppFn can_back_app = nullptr, back_app = nullptr;
#endif

bool load_v_ui()
{
#ifdef VIMGUI_APPLICATION_HOST
    if (draw_app) return true;
    ui_library=dlopen("libvimgui_android_application.so",RTLD_NOW|RTLD_LOCAL);
    if (!ui_library) { __android_log_print(ANDROID_LOG_ERROR,kLogTag,"Application load: %s",dlerror()); return false; }
    title_app=reinterpret_cast<TitleAppFn>(dlsym(ui_library,"vimgui_android_application_title"));
    begin_app=reinterpret_cast<BeginAppFn>(dlsym(ui_library,"vimgui_android_application_begin"));
    mount_app=reinterpret_cast<MountAppFn>(dlsym(ui_library,"vimgui_android_application_mount"));
    draw_app=reinterpret_cast<DrawAppFn>(dlsym(ui_library,"vimgui_android_application_draw"));
    end_app=reinterpret_cast<EndAppFn>(dlsym(ui_library,"vimgui_android_application_end"));
    can_back_app=reinterpret_cast<BackAppFn>(dlsym(ui_library,"vimgui_android_application_can_back"));
    back_app=reinterpret_cast<BackAppFn>(dlsym(ui_library,"vimgui_android_application_back"));
    if (!begin_app || !mount_app || !draw_app || !end_app) {
        draw_app=nullptr;
        __android_log_print(ANDROID_LOG_ERROR,kLogTag,"Application lifecycle symbols missing");
        return false;
    }
    // Keep the library loaded for process lifetime: retained state and workers use it.
    return true;
#elif defined(VIMGUI_ACCESSIBLE_DEMO)
    draw_ui = vimgui_android_accessible_draw;
    return true;
#else
    if (draw_ui != nullptr)
        return true;
    ui_library = dlopen("libvimgui_android_ui.so", RTLD_NOW | RTLD_LOCAL);
    if (ui_library == nullptr)
    {
        __android_log_print(ANDROID_LOG_ERROR, kLogTag, "V UI load failed: %s", dlerror());
        return false;
    }
    draw_ui = reinterpret_cast<DrawUiFn>(dlsym(ui_library, "vimgui_android_demo_draw_ui"));
    if (draw_ui == nullptr)
    {
        __android_log_print(ANDROID_LOG_ERROR, kLogTag, "V UI symbol missing: %s", dlerror());
        dlclose(ui_library);
        ui_library = nullptr;
        return false;
    }
    return true;
#endif
}

#if defined(VIMGUI_ACCESSIBLE_DEMO) || defined(VIMGUI_APPLICATION_HOST)
void set_accessibility_context(vimgui_accessibility *context) {
    JavaVM *vm=g.app->activity->vm;
    JNIEnv *env=nullptr;
    const bool detach=vm->GetEnv(reinterpret_cast<void**>(&env),JNI_VERSION_1_6)==JNI_EDETACHED;
    if (detach && vm->AttachCurrentThread(&env,nullptr)!=JNI_OK) return;
    if (!env) return;
    jobject activity=g.app->activity->clazz;
    jclass cls=env->GetObjectClass(activity);
    jmethodID method=env->GetMethodID(cls,"setImGuiAccessibilityContext","(J)V");
    if (method) env->CallVoidMethod(activity,method,static_cast<jlong>(reinterpret_cast<uintptr_t>(context)));
    if (env->ExceptionCheck()) { env->ExceptionDescribe(); env->ExceptionClear(); }
    env->DeleteLocalRef(cls);
    if (detach) vm->DetachCurrentThread();
}
#endif

void set_keyboard_visible(bool visible)
{
    if (g.app == nullptr || g.app->activity == nullptr)
        return;
    JavaVM* vm = g.app->activity->vm;
    JNIEnv* env = nullptr;
    const jint existing = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    const bool detach = existing == JNI_EDETACHED;
    if (detach && vm->AttachCurrentThread(&env, nullptr) != JNI_OK)
        return;
    if (env == nullptr)
        return;
    jobject activity = g.app->activity->clazz;
    jclass activity_class = env->GetObjectClass(activity);
    jmethodID method = env->GetMethodID(activity_class, "setImGuiKeyboardVisible", "(Z)V");
    if (method != nullptr)
        env->CallVoidMethod(activity, method, visible ? JNI_TRUE : JNI_FALSE);
    if (env->ExceptionCheck())
    {
        env->ExceptionDescribe();
        env->ExceptionClear();
    }
    env->DeleteLocalRef(activity_class);
    if (detach)
        vm->DetachCurrentThread();
}

float configured_ui_scale(android_app* app) {
    const int density=AConfiguration_getDensity(app->config);
    const float fallback=density>0 && density<1000 ? static_cast<float>(density)/160.0f : 1.0f;
    return vimgui_android_ui_scale(app->activity->vm,app->activity->clazz,fallback);
}

bool check(VkResult result, const char* operation)
{
    if (result == VK_SUCCESS)
        return true;
    __android_log_print(ANDROID_LOG_ERROR, kLogTag, "%s failed: %d", operation, static_cast<int>(result));
    return false;
}

PFN_vkVoidFunction load_vulkan(const char* name, void* user_data)
{
    return vkGetInstanceProcAddr(*static_cast<VkInstance*>(user_data), name);
}

void shutdown()
{
    if (g.keyboard_visible)
        set_keyboard_visible(false);
    g.keyboard_visible = false;
    g.keyboard_request_on_touch = false;
    if (g.device != VK_NULL_HANDLE)
        vkDeviceWaitIdle(g.device);
    if (g.renderer_ready)
        ImGui_ImplVulkan_Shutdown();
    if (g.platform_ready)
        vimgui_android_shutdown();
    g.renderer_ready = false;
    g.platform_ready = false;
    if (g.imgui_context != nullptr)
    {
#if defined(VIMGUI_ACCESSIBLE_DEMO) || defined(VIMGUI_APPLICATION_HOST)
        set_accessibility_context(nullptr);
        vimgui_app_shutdown();
#endif
        ImGui::DestroyContext(g.imgui_context);
        g.imgui_context = nullptr;
        vimgui_mobile_reset_style_baseline();
    }
    if (g.device != VK_NULL_HANDLE && g.window.Swapchain != VK_NULL_HANDLE)
        ImGui_ImplVulkanH_DestroyWindow(g.instance, g.device, &g.window, nullptr);
    if (g.instance != VK_NULL_HANDLE && g.surface != VK_NULL_HANDLE)
        vkDestroySurfaceKHR(g.instance, g.surface, nullptr);
    if (g.device != VK_NULL_HANDLE)
        vkDestroyDevice(g.device, nullptr);
    if (g.instance != VK_NULL_HANDLE)
        vkDestroyInstance(g.instance, nullptr);
    if (g.native_window != nullptr)
        ANativeWindow_release(g.native_window);
    g.native_window = nullptr;
    g.instance = VK_NULL_HANDLE;
    g.surface = VK_NULL_HANDLE;
    g.physical_device = VK_NULL_HANDLE;
    g.device = VK_NULL_HANDLE;
    g.queue = VK_NULL_HANDLE;
    g.queue_family = UINT32_MAX;
    g.window = ImGui_ImplVulkanH_Window();
    g.resize_pending = false;
    __android_log_print(ANDROID_LOG_INFO, kLogTag, "Window resources released");
}

bool select_device_and_queue()
{
    uint32_t count = 0;
    if (!check(vkEnumeratePhysicalDevices(g.instance, &count, nullptr), "vkEnumeratePhysicalDevices") || count == 0)
        return false;
    std::vector<VkPhysicalDevice> devices(count);
    if (!check(vkEnumeratePhysicalDevices(g.instance, &count, devices.data()), "vkEnumeratePhysicalDevices"))
        return false;
    for (VkPhysicalDevice candidate : devices)
    {
        uint32_t family_count = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(candidate, &family_count, nullptr);
        std::vector<VkQueueFamilyProperties> families(family_count);
        vkGetPhysicalDeviceQueueFamilyProperties(candidate, &family_count, families.data());
        for (uint32_t i = 0; i < family_count; ++i)
        {
            VkBool32 present = VK_FALSE;
            if (families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT)
                vkGetPhysicalDeviceSurfaceSupportKHR(candidate, i, g.surface, &present);
            if (present)
            {
                g.physical_device = candidate;
                g.queue_family = i;
                return true;
            }
        }
    }
    __android_log_print(ANDROID_LOG_ERROR, kLogTag, "No Vulkan graphics/present queue found");
    return false;
}

void load_font(AAssetManager* assets)
{
    AAsset* asset = AAssetManager_open(assets, "Roboto-Medium.ttf", AASSET_MODE_BUFFER);
    if (asset == nullptr)
        return;
    const int length = static_cast<int>(AAsset_getLength(asset));
    void* bytes = std::malloc(static_cast<size_t>(length));
    if (bytes != nullptr && AAsset_read(asset, bytes, length) == length)
    {
        if (ImGui::GetIO().Fonts->AddFontFromMemoryTTF(bytes, length, 20.0f) != nullptr)
        {
            __android_log_print(ANDROID_LOG_INFO, kLogTag, "Loaded FreeType font asset (%d bytes)", length);
            bytes = nullptr; // The atlas owns this allocation.
        }
    }
    std::free(bytes);
    AAsset_close(asset);
}

bool initialize(android_app* app)
{
    if (app->window == nullptr)
        return false;
    if (!load_v_ui())
        return false;
    g.app = app;
    g.native_window = app->window;
    ANativeWindow_acquire(g.native_window);

    const char* extensions[] = {VK_KHR_SURFACE_EXTENSION_NAME, VK_KHR_ANDROID_SURFACE_EXTENSION_NAME};
    VkApplicationInfo application = {};
    application.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    application.pApplicationName = "vimgui-android-demo";
    application.apiVersion = VK_API_VERSION_1_0;
    VkInstanceCreateInfo instance_info = {};
    instance_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    instance_info.pApplicationInfo = &application;
    instance_info.enabledExtensionCount = 2;
    instance_info.ppEnabledExtensionNames = extensions;
    if (!check(vkCreateInstance(&instance_info, nullptr, &g.instance), "vkCreateInstance"))
        return false;

    VkAndroidSurfaceCreateInfoKHR surface_info = {};
    surface_info.sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
    surface_info.window = g.native_window;
    if (!check(vkCreateAndroidSurfaceKHR(g.instance, &surface_info, nullptr, &g.surface), "vkCreateAndroidSurfaceKHR"))
        return false;
    if (!select_device_and_queue())
        return false;

    const float priority = 1.0f;
    VkDeviceQueueCreateInfo queue_info = {};
    queue_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queue_info.queueFamilyIndex = g.queue_family;
    queue_info.queueCount = 1;
    queue_info.pQueuePriorities = &priority;
    const char* device_extensions[] = {VK_KHR_SWAPCHAIN_EXTENSION_NAME};
    VkDeviceCreateInfo device_info = {};
    device_info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    device_info.queueCreateInfoCount = 1;
    device_info.pQueueCreateInfos = &queue_info;
    device_info.enabledExtensionCount = 1;
    device_info.ppEnabledExtensionNames = device_extensions;
    if (!check(vkCreateDevice(g.physical_device, &device_info, nullptr, &g.device), "vkCreateDevice"))
        return false;
    vkGetDeviceQueue(g.device, g.queue_family, 0, &g.queue);
    // The upstream ImGui Vulkan window helpers use the backend's private
    // dispatch table too, so load it before selecting the surface format.
    if (!ImGui_ImplVulkan_LoadFunctions(VK_API_VERSION_1_0, load_vulkan, &g.instance))
        return false;

    g.window.Surface = g.surface;
    const VkFormat formats[] = {VK_FORMAT_B8G8R8A8_UNORM, VK_FORMAT_R8G8B8A8_UNORM};
    g.window.SurfaceFormat = ImGui_ImplVulkanH_SelectSurfaceFormat(
        g.physical_device, g.surface, formats, 2, VK_COLORSPACE_SRGB_NONLINEAR_KHR);
    const VkPresentModeKHR present_mode = VK_PRESENT_MODE_FIFO_KHR;
    g.window.PresentMode = ImGui_ImplVulkanH_SelectPresentMode(g.physical_device, g.surface, &present_mode, 1);
    const int width = ANativeWindow_getWidth(g.native_window);
    const int height = ANativeWindow_getHeight(g.native_window);
    ImGui_ImplVulkanH_CreateOrResizeWindow(g.instance, g.physical_device, g.device, &g.window,
                                          g.queue_family, nullptr, width, height, kMinImageCount, 0);

    IMGUI_CHECKVERSION();
    g.imgui_context = ImGui::CreateContext();
    if (g.imgui_context == nullptr)
        return false;
    ImGui::GetIO().IniFilename = nullptr;
    ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;
    ImGui::StyleColorsDark();
    const float scale = configured_ui_scale(app);
    g.density_scale = scale;
    // The retained sample state survives native window/context recreation.
    if (!vimgui_mobile_set_ui_scale(scale * g.zoom))
        return false;
    load_font(app->activity->assetManager);
    if (!vimgui_android_init(g.native_window))
        return false;
    g.platform_ready = true;
    if (!vimgui_android_set_clipboard_context(app->activity->vm, app->activity->clazz))
        __android_log_print(ANDROID_LOG_WARN, kLogTag, "Android clipboard unavailable");
    ImGui_ImplVulkan_InitInfo imgui_info = {};
    imgui_info.ApiVersion = VK_API_VERSION_1_0;
    imgui_info.Instance = g.instance;
    imgui_info.PhysicalDevice = g.physical_device;
    imgui_info.Device = g.device;
    imgui_info.QueueFamily = g.queue_family;
    imgui_info.Queue = g.queue;
    imgui_info.DescriptorPoolSize = 32;
    imgui_info.MinImageCount = kMinImageCount;
    imgui_info.ImageCount = g.window.ImageCount;
    imgui_info.PipelineInfoMain.RenderPass = g.window.RenderPass;
    imgui_info.PipelineInfoMain.MSAASamples = VK_SAMPLE_COUNT_1_BIT;
    if (!ImGui_ImplVulkan_Init(&imgui_info))
        return false;
    g.renderer_ready = true;
#if defined(VIMGUI_ACCESSIBLE_DEMO) || defined(VIMGUI_APPLICATION_HOST)
#ifdef VIMGUI_APPLICATION_HOST
    if (!vimgui_app_initialize(title_app ? title_app() : "Application")) return false;
#else
    if (!vimgui_app_initialize("Accessible file review")) return false;
#endif
    vimgui_app_theme(true,false,scale,true);
    vimgui_app_set_text_edit_handler([](void *data,void *) { vimgui_android_apply_text_edit(data); },nullptr);
    set_accessibility_context(vimgui_app_accessibility());
#ifdef VIMGUI_APPLICATION_HOST
    mount_app(scale);
#endif
#endif
    __android_log_print(ANDROID_LOG_INFO, kLogTag, "Vulkan window ready: %dx%d, scale %.2f", width, height, scale);
    return true;
}

bool draw_frame()
{
    if (!g.renderer_ready)
        return false;
    const int width = ANativeWindow_getWidth(g.native_window);
    const int height = ANativeWindow_getHeight(g.native_window);
    if (width <= 0 || height <= 0)
        return true;
    if (g.resize_pending || width != g.window.Width || height != g.window.Height)
    {
        if (!check(vkDeviceWaitIdle(g.device), "vkDeviceWaitIdle before resize"))
            return false;
        ImGui_ImplVulkan_SetMinImageCount(kMinImageCount);
        ImGui_ImplVulkanH_CreateOrResizeWindow(g.instance, g.physical_device, g.device, &g.window,
                                              g.queue_family, nullptr, width, height, kMinImageCount, 0);
        g.window.FrameIndex = 0;
        g.resize_pending = false;
        __android_log_print(ANDROID_LOG_INFO, kLogTag, "Swapchain resized: %dx%d", width, height);
    }

    ImGui_ImplVulkan_NewFrame();
    vimgui_android_new_frame();
    ImGui::NewFrame();
    // NativeActivity reports the usable rectangle when system bars, the IME,
    // or the window layout change. Keep rendering/input in surface coordinates;
    // only the GUI work area is inset, so touch positions need no translation.
    ARect content;
    pthread_mutex_lock(&g.app->mutex);
    content = g.app->contentRect;
    pthread_mutex_unlock(&g.app->mutex);
    ImGuiViewport* viewport = ImGui::GetMainViewport();
    const ImVec2 display = ImGui::GetIO().DisplaySize;
    const float left = std::max(0.0f, std::min(static_cast<float>(content.left), display.x));
    const float top = std::max(0.0f, std::min(static_cast<float>(content.top), display.y));
    const float right = std::max(left, std::min(static_cast<float>(content.right), display.x));
    const float bottom = std::max(top, std::min(static_cast<float>(content.bottom), display.y));
    const bool valid_content = right > left && bottom > top;
    viewport->WorkPos = valid_content ? ImVec2(left, top) : viewport->Pos;
    viewport->WorkSize = valid_content ? ImVec2(right - left, bottom - top) : display;
#if defined(VIMGUI_ACCESSIBLE_DEMO) || defined(VIMGUI_APPLICATION_HOST)
    vimgui_app_safe_area(viewport->WorkPos.x, viewport->WorkPos.y,
        display.x - viewport->WorkPos.x - viewport->WorkSize.x,
        display.y - viewport->WorkPos.y - viewport->WorkSize.y);
#endif
#ifdef VIMGUI_APPLICATION_HOST
    const bool application_ok=draw_app();
    const bool zoom_changed=false;
#else
    const int previous_tap_count = g.tap_count;
    const bool zoom_changed = draw_ui(&g.zoom, &g.tap_count, g.text, sizeof(g.text),
                                      g.clipboard_preview, sizeof(g.clipboard_preview),
                                      viewport->WorkSize.x, viewport->WorkSize.y);
    if (g.tap_count != previous_tap_count)
        __android_log_print(ANDROID_LOG_INFO, kLogTag, "V UI tap count: %d", g.tap_count);
#endif
    ImGui::Render();
#ifdef VIMGUI_APPLICATION_HOST
    if (!application_ok) return false;
#endif
    if (zoom_changed)
        vimgui_mobile_set_ui_scale(g.density_scale * g.zoom);
    const bool wants_keyboard = vimgui_android_wants_text_input();
    const bool retry_keyboard = wants_keyboard && g.keyboard_request_on_touch;
    g.keyboard_request_on_touch = false;
    if (wants_keyboard != g.keyboard_visible || retry_keyboard)
    {
        set_keyboard_visible(wants_keyboard);
        g.keyboard_visible = wants_keyboard;
        __android_log_print(ANDROID_LOG_INFO, kLogTag, "IME visible: %d", wants_keyboard);
    }

    VkSemaphore acquired = g.window.FrameSemaphores[g.window.SemaphoreIndex].ImageAcquiredSemaphore;
    VkSemaphore rendered = g.window.FrameSemaphores[g.window.SemaphoreIndex].RenderCompleteSemaphore;
    VkResult result = vkAcquireNextImageKHR(g.device, g.window.Swapchain, UINT64_MAX, acquired,
                                            VK_NULL_HANDLE, &g.window.FrameIndex);
    if (result == VK_ERROR_OUT_OF_DATE_KHR)
    {
        g.resize_pending = true;
        return true;
    }
    if (result != VK_SUBOPTIMAL_KHR && !check(result, "vkAcquireNextImageKHR"))
        return false;

    ImGui_ImplVulkanH_Frame& frame = g.window.Frames[g.window.FrameIndex];
    if (!check(vkWaitForFences(g.device, 1, &frame.Fence, VK_TRUE, UINT64_MAX), "vkWaitForFences") ||
        !check(vkResetFences(g.device, 1, &frame.Fence), "vkResetFences") ||
        !check(vkResetCommandPool(g.device, frame.CommandPool, 0), "vkResetCommandPool"))
        return false;
    VkCommandBufferBeginInfo begin = {};
    begin.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    if (!check(vkBeginCommandBuffer(frame.CommandBuffer, &begin), "vkBeginCommandBuffer"))
        return false;
    VkRenderPassBeginInfo pass = {};
    pass.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    pass.renderPass = g.window.RenderPass;
    pass.framebuffer = frame.Framebuffer;
    pass.renderArea.extent = {static_cast<uint32_t>(g.window.Width), static_cast<uint32_t>(g.window.Height)};
    pass.clearValueCount = 1;
    pass.pClearValues = &g.window.ClearValue;
    vkCmdBeginRenderPass(frame.CommandBuffer, &pass, VK_SUBPASS_CONTENTS_INLINE);
    ImGui_ImplVulkan_RenderDrawData(ImGui::GetDrawData(), frame.CommandBuffer);
    vkCmdEndRenderPass(frame.CommandBuffer);
    if (!check(vkEndCommandBuffer(frame.CommandBuffer), "vkEndCommandBuffer"))
        return false;

    const VkPipelineStageFlags wait_stage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    VkSubmitInfo submit = {};
    submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submit.waitSemaphoreCount = 1;
    submit.pWaitSemaphores = &acquired;
    submit.pWaitDstStageMask = &wait_stage;
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &frame.CommandBuffer;
    submit.signalSemaphoreCount = 1;
    submit.pSignalSemaphores = &rendered;
    if (!check(vkQueueSubmit(g.queue, 1, &submit, frame.Fence), "vkQueueSubmit"))
        return false;
    VkPresentInfoKHR present = {};
    present.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    present.waitSemaphoreCount = 1;
    present.pWaitSemaphores = &rendered;
    present.swapchainCount = 1;
    present.pSwapchains = &g.window.Swapchain;
    present.pImageIndices = &g.window.FrameIndex;
    result = vkQueuePresentKHR(g.queue, &present);
    if (result == VK_ERROR_OUT_OF_DATE_KHR)
        g.resize_pending = true;
    else if (result != VK_SUBOPTIMAL_KHR && !check(result, "vkQueuePresentKHR"))
        return false;
    g.window.SemaphoreIndex = (g.window.SemaphoreIndex + 1) % g.window.SemaphoreCount;
    return true;
}

void on_command(android_app* app, int32_t command)
{
    switch (command)
    {
        case APP_CMD_INIT_WINDOW:
            if (app->window != nullptr && !initialize(app))
            {
                __android_log_print(ANDROID_LOG_ERROR, kLogTag, "Window initialization failed");
                shutdown();
#ifdef VIMGUI_APPLICATION_HOST
                ANativeActivity_finish(app->activity);
#endif
            }
            break;
        case APP_CMD_TERM_WINDOW:
            shutdown();
            break;
        case APP_CMD_WINDOW_RESIZED:
            g.resize_pending = true;
            break;
        case APP_CMD_CONFIG_CHANGED:
        {
            g.resize_pending = true;
            if (g.imgui_context != nullptr)
            {
                g.density_scale = configured_ui_scale(app);
#if defined(VIMGUI_ACCESSIBLE_DEMO) || defined(VIMGUI_APPLICATION_HOST)
#ifdef VIMGUI_APPLICATION_HOST
                mount_app(g.density_scale);
#else
                vimgui_app_theme(true,false,g.density_scale,true);
#endif
#else
                vimgui_mobile_set_ui_scale(g.density_scale * g.zoom);
#endif
            }
            break;
        }
        case APP_CMD_GAINED_FOCUS:
            g.focused = true;
            break;
        case APP_CMD_LOST_FOCUS:
            g.focused = false;
            if (g.platform_ready)
                vimgui_android_clear_gamepad();
            break;
        default:
            break;
    }
}

int32_t on_input(android_app*, AInputEvent* event)
{
#ifdef VIMGUI_APPLICATION_HOST
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY &&
        AKeyEvent_getKeyCode(event) == AKEYCODE_BACK && can_back_app && back_app && can_back_app()) {
        if (AKeyEvent_getAction(event) == AKEY_EVENT_ACTION_UP) back_app();
        return 1;
    }
#endif
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION &&
        (AInputEvent_getSource(event) & AINPUT_SOURCE_TOUCHSCREEN) == AINPUT_SOURCE_TOUCHSCREEN &&
        (AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK) == AMOTION_EVENT_ACTION_DOWN)
        g.keyboard_request_on_touch = true;
    return g.platform_ready ? vimgui_android_handle_input_event(event) : 0;
}
} // namespace

void android_main(android_app* app)
{
    __android_log_print(ANDROID_LOG_INFO,kLogTag,"NativeActivity render thread starting");
    app->onAppCmd = on_command;
    app->onInputEvent = on_input;
    g.app = app;
#ifdef VIMGUI_APPLICATION_HOST
    const float scale=configured_ui_scale(app);
    if (!load_v_ui() || !begin_app(app->activity->internalDataPath,scale)) {
        __android_log_print(ANDROID_LOG_ERROR,kLogTag,"Application startup failed");
        ANativeActivity_finish(app->activity);
        return;
    }
    __android_log_print(ANDROID_LOG_INFO,kLogTag,"Retained application ready");
#endif
    for (;;)
    {
        int events = 0;
        android_poll_source* source = nullptr;
        while (ALooper_pollOnce(g.renderer_ready && g.focused ? 0 : -1,
                                nullptr, &events, reinterpret_cast<void**>(&source)) >= 0)
        {
            if (source != nullptr)
                source->process(app, source);
            if (app->destroyRequested)
            {
                shutdown();
#ifdef VIMGUI_APPLICATION_HOST
                end_app();
#endif
                return;
            }
        }
        if (g.renderer_ready && g.focused && !draw_frame())
        {
            __android_log_print(ANDROID_LOG_ERROR, kLogTag, "Frame failed; closing window resources");
            shutdown();
#ifdef VIMGUI_APPLICATION_HOST
            ANativeActivity_finish(app->activity);
#endif
        }
    }
}
