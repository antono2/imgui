#include "vimgui_android.h"

#include "../../cimgui/imgui/backends/imgui_impl_android.h"
#include "../../cimgui/imgui/imgui.h"

#include <jni.h>
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
}

extern "C" bool vimgui_android_init(void* native_window)
{
    return native_window != nullptr && ImGui_ImplAndroid_Init(static_cast<ANativeWindow*>(native_window));
}

extern "C" int32_t vimgui_android_handle_input_event(const void* input_event)
{
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
