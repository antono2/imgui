#include "vimgui_ios.h"

#include "../../cimgui/imgui/imgui.h"
#include "../mobile/vimgui_touch_tracker.h"
#include "../mobile/vimgui_gamepad_values.h"
#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

#include <string>
#include <cfloat>

static std::string g_clipboard_text;
static vimgui::TouchTracker g_touches;
static bool g_gamepad_active = false;

// UIKit owns keyboard presentation. Keep this responder deliberately small:
// UIKeyInput supplies committed characters and deletion but not marked ranges.
@interface VImGuiKeyboardView : UIView <UIKeyInput>
@end

@implementation VImGuiKeyboardView
- (BOOL)canBecomeFirstResponder { return YES; }
- (BOOL)hasText { return YES; } // ImGui owns the actual InputText buffer.
- (void)insertText:(NSString*)text
{
    if ([text isEqualToString:@"\n"])
    {
        vimgui_ios_key(ImGuiKey_Enter, true);
        vimgui_ios_key(ImGuiKey_Enter, false);
    }
    else if (text.length > 0)
        vimgui_ios_text_utf8(text.UTF8String);
}
- (void)deleteBackward
{
    vimgui_ios_key(ImGuiKey_Backspace, true);
    vimgui_ios_key(ImGuiKey_Backspace, false);
}
@end

static void vimgui_ios_clear_gamepad()
{
    if (!g_gamepad_active)
        return;
    ImGuiIO& io = ImGui::GetIO();
    for (int key = ImGuiKey_GamepadStart; key <= ImGuiKey_GamepadRStickDown; ++key)
        io.AddKeyAnalogEvent(static_cast<ImGuiKey>(key), false, 0.0f);
    io.BackendFlags &= ~ImGuiBackendFlags_HasGamepad;
    g_gamepad_active = false;
}

static void vimgui_ios_gamepad_button(ImGuiIO& io, ImGuiKey key, GCControllerButtonInput* button)
{
    io.AddKeyEvent(key, button != nil && button.isPressed);
}

static void vimgui_ios_gamepad_stick(ImGuiIO& io, ImGuiKey negative, ImGuiKey positive,
                                     float value, bool invert)
{
    const float axis = invert ? -value : value;
    const float neg = vimgui::gamepad_direction(axis, false);
    const float pos = vimgui::gamepad_direction(axis, true);
    io.AddKeyAnalogEvent(negative, neg > 0.0f, neg);
    io.AddKeyAnalogEvent(positive, pos > 0.0f, pos);
}

static void vimgui_ios_update_gamepad()
{
    GCExtendedGamepad* gp = nil;
    for (GCController* controller in [GCController controllers])
    {
        if (controller.extendedGamepad != nil)
        {
            gp = controller.extendedGamepad;
            break;
        }
    }
    if (gp == nil)
    {
        vimgui_ios_clear_gamepad();
        return;
    }
    ImGuiIO& io = ImGui::GetIO();
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadStart, gp.buttonMenu);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadBack, gp.buttonOptions);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadFaceLeft, gp.buttonX);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadFaceRight, gp.buttonB);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadFaceUp, gp.buttonY);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadFaceDown, gp.buttonA);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadDpadLeft, gp.dpad.left);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadDpadRight, gp.dpad.right);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadDpadUp, gp.dpad.up);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadDpadDown, gp.dpad.down);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadL1, gp.leftShoulder);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadR1, gp.rightShoulder);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadL3, gp.leftThumbstickButton);
    vimgui_ios_gamepad_button(io, ImGuiKey_GamepadR3, gp.rightThumbstickButton);
    const float left = vimgui::gamepad_trigger(gp.leftTrigger.value);
    const float right = vimgui::gamepad_trigger(gp.rightTrigger.value);
    io.AddKeyAnalogEvent(ImGuiKey_GamepadL2, left > 0.10f, left);
    io.AddKeyAnalogEvent(ImGuiKey_GamepadR2, right > 0.10f, right);
    vimgui_ios_gamepad_stick(io, ImGuiKey_GamepadLStickLeft, ImGuiKey_GamepadLStickRight,
                             gp.leftThumbstick.xAxis.value, false);
    vimgui_ios_gamepad_stick(io, ImGuiKey_GamepadLStickUp, ImGuiKey_GamepadLStickDown,
                             gp.leftThumbstick.yAxis.value, true);
    vimgui_ios_gamepad_stick(io, ImGuiKey_GamepadRStickLeft, ImGuiKey_GamepadRStickRight,
                             gp.rightThumbstick.xAxis.value, false);
    vimgui_ios_gamepad_stick(io, ImGuiKey_GamepadRStickUp, ImGuiKey_GamepadRStickDown,
                             gp.rightThumbstick.yAxis.value, true);
    io.BackendFlags |= ImGuiBackendFlags_HasGamepad;
    g_gamepad_active = true;
}

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
    g_gamepad_active = false;
    return true;
}

extern "C" void vimgui_ios_new_frame(float width, float height, float framebuffer_scale, float delta_seconds)
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2(width, height);
    io.DisplayFramebufferScale = ImVec2(framebuffer_scale, framebuffer_scale);
    io.DeltaTime = delta_seconds > 0.0f ? delta_seconds : 1.0f / 60.0f;
    vimgui_ios_update_gamepad();
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

extern "C" void* vimgui_ios_keyboard_create(void* parent_view)
{
    if (parent_view == nullptr || ![NSThread isMainThread])
        return nullptr;
    UIView* parent = (__bridge UIView*)parent_view;
    VImGuiKeyboardView* keyboard = [[VImGuiKeyboardView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    keyboard.backgroundColor = UIColor.clearColor;
    keyboard.accessibilityElementsHidden = YES;
    [parent addSubview:keyboard];
    return (__bridge_retained void*)keyboard;
}

extern "C" bool vimgui_ios_keyboard_set_visible(void* handle, bool visible)
{
    if (handle == nullptr || ![NSThread isMainThread])
        return false;
    VImGuiKeyboardView* keyboard = (__bridge VImGuiKeyboardView*)handle;
    if (visible && !keyboard.isFirstResponder)
        [keyboard becomeFirstResponder];
    else if (!visible && keyboard.isFirstResponder)
        [keyboard resignFirstResponder];
    return keyboard.isFirstResponder == visible;
}

extern "C" void vimgui_ios_keyboard_destroy(void* handle)
{
    if (handle == nullptr || ![NSThread isMainThread])
        return;
    VImGuiKeyboardView* keyboard = CFBridgingRelease(handle);
    [keyboard resignFirstResponder];
    [keyboard removeFromSuperview];
}

extern "C" void vimgui_ios_shutdown(void)
{
    if (ImGui::GetCurrentContext() == nullptr)
        return;
    ImGuiPlatformIO& platform_io = ImGui::GetPlatformIO();
    platform_io.Platform_GetClipboardTextFn = nullptr;
    platform_io.Platform_SetClipboardTextFn = nullptr;
    ImGui::GetIO().BackendPlatformName = nullptr;
    vimgui_ios_clear_gamepad();
    g_clipboard_text.clear();
    vimgui_ios_emit_touch(g_touches.reset());
}
