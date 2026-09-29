#include "vimgui_ios.h"

#include "../../cimgui/imgui/imgui.h"
#include "../mobile/vimgui_touch_tracker.h"
#import <UIKit/UIKit.h>

#include <string>
#include <cfloat>

static std::string g_clipboard_text;
static vimgui::TouchTracker g_touches;

static void vimgui_ios_emit_touch(const vimgui::TouchSignals& signals)
{
    ImGuiIO& io = ImGui::GetIO();
    for (size_t index = 0; index < signals.count; ++index)
    {
        const vimgui::TouchSignal& signal = signals.items[index];
        io.AddMouseSourceEvent(ImGuiMouseSource_TouchScreen);
        if (signal.kind == vimgui::TouchSignal::Position)
            io.AddMousePosEvent(signal.position_valid ? signal.x : -FLT_MAX,
                                signal.position_valid ? signal.y : -FLT_MAX);
        else
            io.AddMouseButtonEvent(0, signal.down);
    }
}

static const char* vimgui_ios_get_clipboard(ImGuiContext*)
{
    NSString* text = [UIPasteboard generalPasteboard].string;
    g_clipboard_text = text ? [text UTF8String] : "";
    return g_clipboard_text.c_str();
}

static void vimgui_ios_set_clipboard(ImGuiContext*, const char* text)
{
    [UIPasteboard generalPasteboard].string = text ? [NSString stringWithUTF8String:text] : @"";
}

extern "C" bool vimgui_ios_init(void)
{
    if (ImGui::GetCurrentContext() == nullptr)
        return false;
    ImGuiIO& io = ImGui::GetIO();
    io.BackendPlatformName = "imgui_impl_v_ios";
    ImGuiPlatformIO& platform_io = ImGui::GetPlatformIO();
    platform_io.Platform_GetClipboardTextFn = vimgui_ios_get_clipboard;
    platform_io.Platform_SetClipboardTextFn = vimgui_ios_set_clipboard;
    g_touches.reset();
    return true;
}

extern "C" void vimgui_ios_new_frame(float width, float height, float framebuffer_scale, float delta_seconds)
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2(width, height);
    io.DisplayFramebufferScale = ImVec2(framebuffer_scale, framebuffer_scale);
    io.DeltaTime = delta_seconds > 0.0f ? delta_seconds : 1.0f / 60.0f;
}

extern "C" void vimgui_ios_touch(uint64_t touch_id, float x, float y, bool down)
{
    vimgui_ios_emit_touch(down ? g_touches.down(touch_id, x, y) : g_touches.up(touch_id));
}

extern "C" void vimgui_ios_key(int32_t imgui_key, bool down)
{
    ImGui::GetIO().AddKeyEvent(static_cast<ImGuiKey>(imgui_key), down);
}

extern "C" void vimgui_ios_text_utf8(const char* committed_text)
{
    if (committed_text != nullptr)
        ImGui::GetIO().AddInputCharactersUTF8(committed_text);
}

extern "C" bool vimgui_ios_wants_text_input(void)
{
    return ImGui::GetIO().WantTextInput;
}

extern "C" void vimgui_ios_shutdown(void)
{
    if (ImGui::GetCurrentContext() == nullptr)
        return;
    ImGuiPlatformIO& platform_io = ImGui::GetPlatformIO();
    platform_io.Platform_GetClipboardTextFn = nullptr;
    platform_io.Platform_SetClipboardTextFn = nullptr;
    ImGui::GetIO().BackendPlatformName = nullptr;
    g_clipboard_text.clear();
    vimgui_ios_emit_touch(g_touches.reset());
}
