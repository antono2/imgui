#include "vimgui_android.h"

#include "../../cimgui/imgui/backends/imgui_impl_android.h"
#include "../../cimgui/imgui/imgui.h"
#include "../mobile/vimgui_touch_tracker.h"

#include <jni.h>
#include <android/input.h>
#include <cfloat>
#include <mutex>
#include <string>
#include <vector>

namespace {
struct QueuedInput {
    std::u16string text;
    ImGuiKey key;
    bool down;
};
std::mutex g_input_mutex;
std::vector<QueuedInput> g_queued_input;
vimgui::TouchTracker g_touches;

void emit_touch(const vimgui::TouchSignals& signals)
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

bool handle_touch(const AInputEvent* event)
{
    if (AInputEvent_getType(event) != AINPUT_EVENT_TYPE_MOTION ||
        (AInputEvent_getSource(event) & AINPUT_SOURCE_TOUCHSCREEN) != AINPUT_SOURCE_TOUCHSCREEN)
        return false;
    const int action = AMotionEvent_getAction(event);
    const int masked = action & AMOTION_EVENT_ACTION_MASK;
    const size_t index = static_cast<size_t>((action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >>
                                             AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT);
    const size_t count = static_cast<size_t>(AMotionEvent_getPointerCount(event));
    if (index >= count && masked != AMOTION_EVENT_ACTION_CANCEL)
        return false;

    if (masked == AMOTION_EVENT_ACTION_DOWN || masked == AMOTION_EVENT_ACTION_POINTER_DOWN)
    {
        emit_touch(g_touches.down(static_cast<uint64_t>(AMotionEvent_getPointerId(event, index)),
                                  AMotionEvent_getX(event, index), AMotionEvent_getY(event, index)));
    }
    else if (masked == AMOTION_EVENT_ACTION_MOVE)
    {
        for (size_t pointer = 0; pointer < count; ++pointer)
            emit_touch(g_touches.move(static_cast<uint64_t>(AMotionEvent_getPointerId(event, pointer)),
                                      AMotionEvent_getX(event, pointer), AMotionEvent_getY(event, pointer)));
    }
    else if (masked == AMOTION_EVENT_ACTION_UP || masked == AMOTION_EVENT_ACTION_POINTER_UP)
    {
        // Android includes all surviving pointer coordinates in a POINTER_UP event.
        for (size_t pointer = 0; pointer < count; ++pointer)
            if (pointer != index)
                emit_touch(g_touches.move(static_cast<uint64_t>(AMotionEvent_getPointerId(event, pointer)),
                                          AMotionEvent_getX(event, pointer), AMotionEvent_getY(event, pointer)));
        emit_touch(g_touches.up(static_cast<uint64_t>(AMotionEvent_getPointerId(event, index))));
    }
    else if (masked == AMOTION_EVENT_ACTION_CANCEL)
    {
        emit_touch(g_touches.reset());
    }
    else
    {
        return false;
    }
    return true;
}
}

extern "C" bool vimgui_android_init(void* native_window)
{
    g_touches.reset();
    return native_window != nullptr && ImGui_ImplAndroid_Init(static_cast<ANativeWindow*>(native_window));
}

extern "C" int32_t vimgui_android_handle_input_event(const void* input_event)
{
    if (handle_touch(static_cast<const AInputEvent*>(input_event)))
        return 1;
    return ImGui_ImplAndroid_HandleInputEvent(static_cast<const AInputEvent*>(input_event));
}

extern "C" void vimgui_android_new_frame(void)
{
    std::vector<QueuedInput> pending;
    {
        std::lock_guard<std::mutex> lock(g_input_mutex);
        pending.swap(g_queued_input);
    }
    ImGuiIO& io = ImGui::GetIO();
    for (const QueuedInput& input : pending)
    {
        for (char16_t unit : input.text)
            io.AddInputCharacterUTF16(static_cast<ImWchar16>(unit));
        if (input.key != ImGuiKey_None)
            io.AddKeyEvent(input.key, input.down);
    }
    ImGui_ImplAndroid_NewFrame();
}

extern "C" void vimgui_android_text_utf8(const char* committed_text)
{
    if (committed_text != nullptr)
        ImGui::GetIO().AddInputCharactersUTF8(committed_text);
}

extern "C" bool vimgui_android_wants_text_input(void)
{
    return ImGui::GetIO().WantTextInput;
}

extern "C" void vimgui_android_shutdown(void)
{
    emit_touch(g_touches.reset());
    ImGui_ImplAndroid_Shutdown();
    std::lock_guard<std::mutex> lock(g_input_mutex);
    g_queued_input.clear();
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeCommitText(JNIEnv* env, jclass, jstring text)
{
    if (text == nullptr)
        return;
    const jchar* units = env->GetStringChars(text, nullptr);
    if (units == nullptr)
        return;
    const jsize length = env->GetStringLength(text);
    std::u16string committed;
    committed.reserve(static_cast<size_t>(length));
    for (jsize i = 0; i < length; ++i)
        committed.push_back(static_cast<char16_t>(units[i]));
    env->ReleaseStringChars(text, units);
    {
        std::lock_guard<std::mutex> lock(g_input_mutex);
        g_queued_input.push_back({committed, ImGuiKey_None, false});
    }
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeKey(JNIEnv*, jclass, jint key, jboolean down)
{
    ImGuiKey imgui_key = ImGuiKey_None;
    switch (key)
    {
        case 1: imgui_key = ImGuiKey_Backspace; break;
        case 2: imgui_key = ImGuiKey_Enter; break;
        case 3: imgui_key = ImGuiKey_Tab; break;
        case 4: imgui_key = ImGuiKey_Delete; break;
        default: return;
    }
    std::lock_guard<std::mutex> lock(g_input_mutex);
    g_queued_input.push_back({std::u16string(), imgui_key, down == JNI_TRUE});
}
