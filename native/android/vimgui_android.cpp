#include "vimgui_android.h"

#include "../../cimgui/imgui/backends/imgui_impl_android.h"
#include "../../cimgui/imgui/imgui.h"
#include "../mobile/vimgui_text_offsets.h"
#include "../mobile/vimgui_touch_tracker.h"
#include "../mobile/vimgui_gamepad_values.h"

#include <jni.h>
#include <android/input.h>
#include <android/keycodes.h>
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstring>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

namespace {
struct QueuedInput {
    std::u16string text;
    ImGuiKey key;
    bool down;
};
struct TextState {
    std::u16string text;
    int selection_start = 0;
    int selection_end = 0;
    int serial = 0;
    int generation = 0;
    bool valid = false;
};
std::mutex g_input_mutex;
std::vector<QueuedInput> g_queued_input;
TextState g_text_snapshot;
TextState g_pending_text;
bool g_stateful_text = false;
ImGuiID g_text_widget = 0;
int g_text_generation = 1;
int g_text_revision = 1;
vimgui::TouchTracker g_touches;
int g_gamepad_device = -1;
bool g_gamepad_active = false;
std::mutex g_gamepad_mutex;
std::vector<int32_t> g_disconnected_gamepads;
bool g_gamepad_keys[4] = {};
bool g_trigger_keys[2] = {};
float g_trigger_axes[2] = {};
float g_hat_x = 0.0f;
float g_hat_y = 0.0f;
JavaVM* g_clipboard_vm = nullptr;
jobject g_clipboard_context = nullptr;
jobject g_clipboard_manager = nullptr;
std::string g_clipboard_text;

struct ScopedJNIEnv {
    JavaVM* vm;
    JNIEnv* env = nullptr;
    bool attached = false;

    explicit ScopedJNIEnv(JavaVM* value) : vm(value)
    {
        if (vm == nullptr)
            return;
        const jint status = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
        if (status == JNI_EDETACHED && vm->AttachCurrentThread(&env, nullptr) == JNI_OK)
            attached = true;
        else if (status != JNI_OK)
            env = nullptr;
    }

    ~ScopedJNIEnv()
    {
        if (attached)
            vm->DetachCurrentThread();
    }
};

void clear_jni_exception(JNIEnv* env)
{
    if (env->ExceptionCheck())
        env->ExceptionClear();
}

const char* get_clipboard_text(ImGuiContext*)
{
    g_clipboard_text.clear();
    ScopedJNIEnv jni(g_clipboard_vm);
    JNIEnv* env = jni.env;
    if (env == nullptr || g_clipboard_manager == nullptr || env->PushLocalFrame(16) != JNI_OK)
        return g_clipboard_text.c_str();
    do
    {
        jclass manager_class = env->GetObjectClass(g_clipboard_manager);
        if (manager_class == nullptr) break;
        jmethodID get_clip = env->GetMethodID(manager_class, "getPrimaryClip", "()Landroid/content/ClipData;");
        if (get_clip == nullptr) break;
        jobject clip = env->CallObjectMethod(g_clipboard_manager, get_clip);
        if (env->ExceptionCheck() || clip == nullptr) break;
        jclass clip_class = env->GetObjectClass(clip);
        if (clip_class == nullptr) break;
        jmethodID count = env->GetMethodID(clip_class, "getItemCount", "()I");
        jmethodID item_at = env->GetMethodID(clip_class, "getItemAt", "(I)Landroid/content/ClipData$Item;");
        if (count == nullptr || item_at == nullptr || env->CallIntMethod(clip, count) < 1 || env->ExceptionCheck()) break;
        jobject item = env->CallObjectMethod(clip, item_at, 0);
        if (env->ExceptionCheck() || item == nullptr) break;
        jclass item_class = env->GetObjectClass(item);
        if (item_class == nullptr) break;
        jmethodID coerce = env->GetMethodID(item_class, "coerceToText", "(Landroid/content/Context;)Ljava/lang/CharSequence;");
        if (coerce == nullptr) break;
        jobject chars = env->CallObjectMethod(item, coerce, g_clipboard_context);
        if (env->ExceptionCheck() || chars == nullptr) break;
        jclass chars_class = env->FindClass("java/lang/CharSequence");
        if (chars_class == nullptr) break;
        jmethodID to_string = env->GetMethodID(chars_class, "toString", "()Ljava/lang/String;");
        if (to_string == nullptr) break;
        jstring value = static_cast<jstring>(env->CallObjectMethod(chars, to_string));
        if (env->ExceptionCheck() || value == nullptr) break;
        // JNI's GetStringUTFChars uses modified UTF-8. Convert UTF-16 instead
        // so emoji and embedded U+0000 reach Dear ImGui as ordinary UTF-8.
        const jchar* units = env->GetStringChars(value, nullptr);
        if (units == nullptr) break;
        const jsize length = env->GetStringLength(value);
        g_clipboard_text = vimgui::utf16_to_utf8(
            std::u16string(reinterpret_cast<const char16_t*>(units), size_t(length)));
        env->ReleaseStringChars(value, units);
    } while (false);
    clear_jni_exception(env);
    env->PopLocalFrame(nullptr);
    return g_clipboard_text.c_str();
}

void set_clipboard_text(ImGuiContext*, const char* text)
{
    ScopedJNIEnv jni(g_clipboard_vm);
    JNIEnv* env = jni.env;
    if (env == nullptr || g_clipboard_manager == nullptr || env->PushLocalFrame(12) != JNI_OK)
        return;
    do
    {
        const std::u16string utf16 = vimgui::utf8_to_utf16(text != nullptr ? text : "",
                                                           text != nullptr ? int(std::strlen(text)) : 0);
        jstring label = env->NewStringUTF("");
        jstring value = env->NewString(reinterpret_cast<const jchar*>(utf16.data()), jsize(utf16.size()));
        if (label == nullptr || value == nullptr) break;
        jclass clip_class = env->FindClass("android/content/ClipData");
        if (clip_class == nullptr) break;
        jmethodID plain_text = env->GetStaticMethodID(clip_class, "newPlainText",
            "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;");
        if (plain_text == nullptr) break;
        jobject clip = env->CallStaticObjectMethod(clip_class, plain_text, label, value);
        if (env->ExceptionCheck() || clip == nullptr) break;
        jclass manager_class = env->GetObjectClass(g_clipboard_manager);
        if (manager_class == nullptr) break;
        jmethodID set_clip = env->GetMethodID(manager_class, "setPrimaryClip", "(Landroid/content/ClipData;)V");
        if (set_clip == nullptr) break;
        env->CallVoidMethod(g_clipboard_manager, set_clip, clip);
    } while (false);
    clear_jni_exception(env);
    env->PopLocalFrame(nullptr);
}

void clear_clipboard_context()
{
    if (ImGui::GetCurrentContext() != nullptr)
    {
        ImGuiPlatformIO& platform_io = ImGui::GetPlatformIO();
        if (platform_io.Platform_GetClipboardTextFn == get_clipboard_text)
            platform_io.Platform_GetClipboardTextFn = nullptr;
        if (platform_io.Platform_SetClipboardTextFn == set_clipboard_text)
            platform_io.Platform_SetClipboardTextFn = nullptr;
    }
    ScopedJNIEnv jni(g_clipboard_vm);
    if (jni.env != nullptr)
    {
        if (g_clipboard_manager != nullptr)
            jni.env->DeleteGlobalRef(g_clipboard_manager);
        if (g_clipboard_context != nullptr)
            jni.env->DeleteGlobalRef(g_clipboard_context);
    }
    g_clipboard_manager = nullptr;
    g_clipboard_context = nullptr;
    g_clipboard_vm = nullptr;
    g_clipboard_text.clear();
}

void emit_dpad()
{
    ImGuiIO& io = ImGui::GetIO();
    io.AddKeyEvent(ImGuiKey_GamepadDpadLeft, vimgui::gamepad_dpad(g_gamepad_keys[0], g_hat_x, false));
    io.AddKeyEvent(ImGuiKey_GamepadDpadRight, vimgui::gamepad_dpad(g_gamepad_keys[1], g_hat_x, true));
    io.AddKeyEvent(ImGuiKey_GamepadDpadUp, vimgui::gamepad_dpad(g_gamepad_keys[2], g_hat_y, false));
    io.AddKeyEvent(ImGuiKey_GamepadDpadDown, vimgui::gamepad_dpad(g_gamepad_keys[3], g_hat_y, true));
}

void emit_triggers()
{
    ImGuiIO& io = ImGui::GetIO();
    const float left = g_trigger_keys[0] ? 1.0f : g_trigger_axes[0];
    const float right = g_trigger_keys[1] ? 1.0f : g_trigger_axes[1];
    io.AddKeyAnalogEvent(ImGuiKey_GamepadL2, left > 0.10f, left);
    io.AddKeyAnalogEvent(ImGuiKey_GamepadR2, right > 0.10f, right);
}

void clear_gamepad()
{
    if (!g_gamepad_active)
        return;
    ImGuiIO& io = ImGui::GetIO();
    for (int key = ImGuiKey_GamepadStart; key <= ImGuiKey_GamepadRStickDown; ++key)
        io.AddKeyAnalogEvent(static_cast<ImGuiKey>(key), false, 0.0f);
    io.BackendFlags &= ~ImGuiBackendFlags_HasGamepad;
    g_gamepad_device = -1;
    g_gamepad_active = false;
    std::fill_n(g_gamepad_keys, 4, false);
    std::fill_n(g_trigger_keys, 2, false);
    std::fill_n(g_trigger_axes, 2, 0.0f);
    g_hat_x = g_hat_y = 0.0f;
}

ImGuiKey gamepad_key(int32_t code)
{
    switch (code)
    {
        case AKEYCODE_BUTTON_START: return ImGuiKey_GamepadStart;
        case AKEYCODE_BUTTON_SELECT: return ImGuiKey_GamepadBack;
        case AKEYCODE_BUTTON_X: return ImGuiKey_GamepadFaceLeft;
        case AKEYCODE_BUTTON_B: return ImGuiKey_GamepadFaceRight;
        case AKEYCODE_BUTTON_Y: return ImGuiKey_GamepadFaceUp;
        case AKEYCODE_BUTTON_A: return ImGuiKey_GamepadFaceDown;
        case AKEYCODE_DPAD_CENTER: return ImGuiKey_GamepadFaceDown;
        case AKEYCODE_BUTTON_L1: return ImGuiKey_GamepadL1;
        case AKEYCODE_BUTTON_R1: return ImGuiKey_GamepadR1;
        case AKEYCODE_BUTTON_L2: return ImGuiKey_GamepadL2;
        case AKEYCODE_BUTTON_R2: return ImGuiKey_GamepadR2;
        case AKEYCODE_BUTTON_THUMBL: return ImGuiKey_GamepadL3;
        case AKEYCODE_BUTTON_THUMBR: return ImGuiKey_GamepadR3;
        default: return ImGuiKey_None;
    }
}

void emit_stick(ImGuiKey negative, ImGuiKey positive, float axis)
{
    ImGuiIO& io = ImGui::GetIO();
    const float neg = vimgui::gamepad_direction(axis, false);
    const float pos = vimgui::gamepad_direction(axis, true);
    io.AddKeyAnalogEvent(negative, neg > 0.0f, neg);
    io.AddKeyAnalogEvent(positive, pos > 0.0f, pos);
}

bool handle_gamepad(const AInputEvent* event)
{
    const int32_t source = AInputEvent_getSource(event);
    const bool controller = (source & AINPUT_SOURCE_GAMEPAD) == AINPUT_SOURCE_GAMEPAD ||
                            (source & AINPUT_SOURCE_JOYSTICK) == AINPUT_SOURCE_JOYSTICK ||
                            (source & AINPUT_SOURCE_DPAD) == AINPUT_SOURCE_DPAD;
    if (!controller)
        return false;
    const int32_t type = AInputEvent_getType(event);
    if (type != AINPUT_EVENT_TYPE_KEY && type != AINPUT_EVENT_TYPE_MOTION)
        return false;
    const int32_t device = AInputEvent_getDeviceId(event);
    if (g_gamepad_active && device != g_gamepad_device)
        return false; // Dear ImGui exposes one navigation controller.
    if (type == AINPUT_EVENT_TYPE_KEY)
    {
        const int32_t code = AKeyEvent_getKeyCode(event);
        const ImGuiKey key = gamepad_key(code);
        int dpad = -1;
        if (code == AKEYCODE_DPAD_LEFT) dpad = 0;
        if (code == AKEYCODE_DPAD_RIGHT) dpad = 1;
        if (code == AKEYCODE_DPAD_UP) dpad = 2;
        if (code == AKEYCODE_DPAD_DOWN) dpad = 3;
        if (key == ImGuiKey_None && dpad == -1)
            return false;
        const int32_t action = AKeyEvent_getAction(event);
        if (action != AKEY_EVENT_ACTION_DOWN && action != AKEY_EVENT_ACTION_UP)
            return true;
        g_gamepad_device = device;
        g_gamepad_active = true;
        ImGuiIO& io = ImGui::GetIO();
        io.BackendFlags |= ImGuiBackendFlags_HasGamepad;
        const bool down = action == AKEY_EVENT_ACTION_DOWN;
        if (dpad >= 0)
        {
            g_gamepad_keys[dpad] = down;
            emit_dpad();
        }
        else if (key == ImGuiKey_GamepadL2 || key == ImGuiKey_GamepadR2)
        {
            g_trigger_keys[key == ImGuiKey_GamepadL2 ? 0 : 1] = down;
            emit_triggers();
        }
        else
            io.AddKeyEvent(key, down);
        return true;
    }
    const int32_t action = AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
    if ((source & AINPUT_SOURCE_JOYSTICK) != AINPUT_SOURCE_JOYSTICK ||
        action != AMOTION_EVENT_ACTION_MOVE)
        return false;
    g_gamepad_device = device;
    g_gamepad_active = true;
    ImGuiIO& io = ImGui::GetIO();
    io.BackendFlags |= ImGuiBackendFlags_HasGamepad;
    emit_stick(ImGuiKey_GamepadLStickLeft, ImGuiKey_GamepadLStickRight,
               AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_X, 0));
    emit_stick(ImGuiKey_GamepadLStickUp, ImGuiKey_GamepadLStickDown,
               AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_Y, 0));
    emit_stick(ImGuiKey_GamepadRStickLeft, ImGuiKey_GamepadRStickRight,
               AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_Z, 0));
    emit_stick(ImGuiKey_GamepadRStickUp, ImGuiKey_GamepadRStickDown,
               AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RZ, 0));
    g_trigger_axes[0] = vimgui::gamepad_trigger(std::max(
        AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_LTRIGGER, 0),
        AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_BRAKE, 0)));
    g_trigger_axes[1] = vimgui::gamepad_trigger(std::max(
        AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RTRIGGER, 0),
        AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_GAS, 0)));
    emit_triggers();
    g_hat_x = AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_HAT_X, 0);
    g_hat_y = AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_HAT_Y, 0);
    emit_dpad();
    return true;
}

std::u16string jstring_to_utf16(JNIEnv* env, jstring value)
{
    const jsize length = env->GetStringLength(value);
    const jchar* units = env->GetStringChars(value, nullptr);
    if (units == nullptr)
        return {};
    std::u16string text(reinterpret_cast<const char16_t*>(units), size_t(length));
    env->ReleaseStringChars(value, units);
    return text;
}

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

extern "C" float vimgui_android_ui_scale(void* java_vm, void* context, float fallback)
{
    if (!std::isfinite(fallback) || fallback<=0) fallback=1;
    ScopedJNIEnv jni(static_cast<JavaVM*>(java_vm));
    JNIEnv* env=jni.env;
    if (!env || !context) return fallback;
    if (env->PushLocalFrame(16)!=JNI_OK) { clear_jni_exception(env); return fallback; }
    const float result=[&]() -> float {
        jclass cls=env->GetObjectClass(static_cast<jobject>(context));
        if (!cls || env->ExceptionCheck()) return fallback;
        jmethodID resources_method=env->GetMethodID(cls,"getResources","()Landroid/content/res/Resources;");
        if (!resources_method || env->ExceptionCheck()) return fallback;
        jobject resources=env->CallObjectMethod(static_cast<jobject>(context),resources_method);
        if (!resources || env->ExceptionCheck()) return fallback;
        cls=env->GetObjectClass(resources);
        if (!cls || env->ExceptionCheck()) return fallback;
        jmethodID metrics_method=env->GetMethodID(cls,"getDisplayMetrics","()Landroid/util/DisplayMetrics;");
        if (!metrics_method || env->ExceptionCheck()) return fallback;
        jobject metrics=env->CallObjectMethod(resources,metrics_method);
        if (!metrics || env->ExceptionCheck()) return fallback;
        cls=env->FindClass("android/util/TypedValue");
        if (!cls || env->ExceptionCheck()) return fallback;
        jmethodID convert=env->GetStaticMethodID(cls,"applyDimension","(IFLandroid/util/DisplayMetrics;)F");
        if (!convert || env->ExceptionCheck()) return fallback;
        // SP conversion respects the OS font preference and Android 14's
        // nonlinear conversion for the application's base 16sp font.
        const float scale=env->CallStaticFloatMethod(cls,convert,2,16.0f,metrics)/16.0f;
        if (env->ExceptionCheck() || !std::isfinite(scale) || scale<=0) return fallback;
        return scale;
    }();
    clear_jni_exception(env);
    env->PopLocalFrame(nullptr);
    return result;
}

extern "C" bool vimgui_android_init(void* native_window)
{
    g_touches.reset();
    g_gamepad_device = -1;
    g_gamepad_active = false;
    {
        std::lock_guard<std::mutex> lock(g_gamepad_mutex);
        g_disconnected_gamepads.clear();
    }
    return native_window != nullptr && ImGui_ImplAndroid_Init(static_cast<ANativeWindow*>(native_window));
}

extern "C" bool vimgui_android_set_clipboard_context(void* java_vm, void* context)
{
    if (ImGui::GetCurrentContext() == nullptr || java_vm == nullptr || context == nullptr)
        return false;
    clear_clipboard_context();
    JavaVM* vm = static_cast<JavaVM*>(java_vm);
    ScopedJNIEnv jni(vm);
    JNIEnv* env = jni.env;
    if (env == nullptr || env->PushLocalFrame(8) != JNI_OK)
        return false;
    jobject global_context = nullptr;
    jobject global_manager = nullptr;
    do
    {
        jclass context_class = env->GetObjectClass(static_cast<jobject>(context));
        if (context_class == nullptr) break;
        jmethodID get_service = env->GetMethodID(context_class, "getSystemService",
                                                  "(Ljava/lang/String;)Ljava/lang/Object;");
        if (get_service == nullptr) break;
        jstring clipboard = env->NewStringUTF("clipboard");
        if (clipboard == nullptr) break;
        jobject manager = env->CallObjectMethod(static_cast<jobject>(context), get_service, clipboard);
        if (env->ExceptionCheck() || manager == nullptr) break;
        global_context = env->NewGlobalRef(static_cast<jobject>(context));
        global_manager = env->NewGlobalRef(manager);
    } while (false);
    clear_jni_exception(env);
    env->PopLocalFrame(nullptr);
    if (global_context == nullptr || global_manager == nullptr)
    {
        if (global_context != nullptr) env->DeleteGlobalRef(global_context);
        if (global_manager != nullptr) env->DeleteGlobalRef(global_manager);
        return false;
    }
    g_clipboard_vm = vm;
    g_clipboard_context = global_context;
    g_clipboard_manager = global_manager;
    ImGuiPlatformIO& platform_io = ImGui::GetPlatformIO();
    platform_io.Platform_GetClipboardTextFn = get_clipboard_text;
    platform_io.Platform_SetClipboardTextFn = set_clipboard_text;
    return true;
}

extern "C" int32_t vimgui_android_handle_input_event(const void* input_event)
{
    if (handle_gamepad(static_cast<const AInputEvent*>(input_event)))
        return 1;
    if (handle_touch(static_cast<const AInputEvent*>(input_event)))
        return 1;
    return ImGui_ImplAndroid_HandleInputEvent(static_cast<const AInputEvent*>(input_event));
}

extern "C" void vimgui_android_new_frame(void)
{
    std::vector<int32_t> disconnected;
    {
        std::lock_guard<std::mutex> lock(g_gamepad_mutex);
        disconnected.swap(g_disconnected_gamepads);
    }
    if (g_gamepad_active &&
        std::find(disconnected.begin(), disconnected.end(), g_gamepad_device) != disconnected.end())
        clear_gamepad();
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

extern "C" bool vimgui_android_apply_text_edit(void* callback_data)
{
    ImGuiInputTextCallbackData* data = static_cast<ImGuiInputTextCallbackData*>(callback_data);
    if (data == nullptr || data->EventFlag != ImGuiInputTextFlags_CallbackAlways)
        return false;
    TextState pending;
    {
        std::lock_guard<std::mutex> lock(g_input_mutex);
        if (g_text_widget != data->ID || data->EventActivated)
        {
            g_text_widget = data->ID;
            g_pending_text = TextState{};
            g_text_snapshot = TextState{};
            ++g_text_generation;
        }
        g_stateful_text = true;
        pending = g_pending_text;
        g_pending_text.valid = false;
    }
    const std::string utf8 = pending.valid ? vimgui::utf16_to_utf8(pending.text) : std::string();
    // Reject an oversized replacement before deleting the existing buffer.
    const bool applied = pending.valid && (data->Flags & ImGuiInputTextFlags_ReadOnly) == 0 &&
        (utf8.size() < static_cast<size_t>(data->BufSize) ||
         (data->Flags & ImGuiInputTextFlags_CallbackResize) != 0);
    if (applied)
    {
        if (data->BufTextLen != int(utf8.size()) ||
            std::memcmp(data->Buf, utf8.data(), utf8.size()) != 0)
        {
            data->DeleteChars(0, data->BufTextLen);
            data->InsertChars(0, utf8.data(), utf8.data() + utf8.size());
        }
        const int start = vimgui::utf16_index_to_utf8_offset(pending.text, pending.selection_start);
        const int end = vimgui::utf16_index_to_utf8_offset(pending.text, pending.selection_end);
        data->SetSelection(std::min(start, data->BufTextLen), std::min(end, data->BufTextLen));
    }
    TextState snapshot;
    snapshot.text = vimgui::utf8_to_utf16(data->Buf, data->BufTextLen);
    snapshot.selection_start = vimgui::utf8_offset_to_utf16_index(data->Buf, data->SelectionStart);
    snapshot.selection_end = vimgui::utf8_offset_to_utf16_index(data->Buf, data->SelectionEnd);
    snapshot.valid = true;
    {
        std::lock_guard<std::mutex> lock(g_input_mutex);
        snapshot.serial = pending.valid ? pending.serial : g_text_snapshot.serial;
        snapshot.generation = g_text_generation;
        if (!g_text_snapshot.valid || g_text_snapshot.text != snapshot.text ||
            g_text_snapshot.selection_start != snapshot.selection_start ||
            g_text_snapshot.selection_end != snapshot.selection_end ||
            g_text_snapshot.serial != snapshot.serial ||
            g_text_snapshot.generation != snapshot.generation)
        {
            g_text_snapshot = std::move(snapshot);
            ++g_text_revision;
        }
    }
    return applied;
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

extern "C" void vimgui_android_clear_gamepad(void)
{
    clear_gamepad();
}

extern "C" void vimgui_android_gamepad_disconnected(int32_t device_id)
{
    std::lock_guard<std::mutex> lock(g_gamepad_mutex);
    g_disconnected_gamepads.push_back(device_id);
}

extern "C" void vimgui_android_shutdown(void)
{
    clear_clipboard_context();
    clear_gamepad();
    {
        std::lock_guard<std::mutex> lock(g_gamepad_mutex);
        g_disconnected_gamepads.clear();
    }
    emit_touch(g_touches.reset());
    ImGui_ImplAndroid_Shutdown();
    std::lock_guard<std::mutex> lock(g_input_mutex);
    g_queued_input.clear();
    g_pending_text = TextState{};
    g_text_snapshot = TextState{};
    g_stateful_text = false;
    g_text_widget = 0;
    ++g_text_generation;
    ++g_text_revision;
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeSetEditingState(JNIEnv* env, jclass, jstring text,
                                                            jint selection_start, jint selection_end,
                                                            jint serial, jint generation)
{
    if (text == nullptr)
        return;
    TextState state;
    state.text = jstring_to_utf16(env, text);
    state.selection_start = selection_start;
    state.selection_end = selection_end;
    state.serial = serial;
    state.generation = generation;
    state.valid = true;
    std::lock_guard<std::mutex> lock(g_input_mutex);
    if (g_stateful_text && generation == g_text_generation)
        g_pending_text = std::move(state);
}

extern "C" JNIEXPORT jobject JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeGetEditingState(JNIEnv* env, jclass)
{
    TextState snapshot;
    {
        std::lock_guard<std::mutex> lock(g_input_mutex);
        snapshot = g_text_snapshot;
    }
    if (!snapshot.valid)
        return nullptr;
    jclass klass = env->FindClass("io/antono2/imgui/ImGuiInputView$TextState");
    if (klass == nullptr)
        return nullptr;
    jmethodID constructor = env->GetMethodID(klass, "<init>", "(Ljava/lang/String;IIII)V");
    if (constructor == nullptr)
    {
        env->DeleteLocalRef(klass);
        return nullptr;
    }
    jstring text = env->NewString(reinterpret_cast<const jchar*>(snapshot.text.data()),
                                  jsize(snapshot.text.size()));
    if (text == nullptr)
    {
        env->DeleteLocalRef(klass);
        return nullptr;
    }
    jobject result = env->NewObject(klass, constructor, text, snapshot.selection_start,
                                    snapshot.selection_end, snapshot.serial, snapshot.generation);
    env->DeleteLocalRef(text);
    env->DeleteLocalRef(klass);
    return result;
}

extern "C" JNIEXPORT jint JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeGetEditingRevision(JNIEnv*, jclass)
{
    std::lock_guard<std::mutex> lock(g_input_mutex);
    return g_text_revision;
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeDiscardPendingEdits(JNIEnv*, jclass)
{
    std::lock_guard<std::mutex> lock(g_input_mutex);
    g_pending_text = TextState{};
    g_text_snapshot = TextState{};
    ++g_text_revision;
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeCommitText(JNIEnv* env, jclass, jstring text)
{
    if (text == nullptr)
        return;
    std::u16string committed = jstring_to_utf16(env, text);
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

extern "C" JNIEXPORT jfloat JNICALL
Java_io_antono2_imgui_ImGuiInputView_nativeUiScale(JNIEnv* env, jclass, jobject context) {
    JavaVM* vm=nullptr;
    if (env->GetJavaVM(&vm)!=JNI_OK) return 1;
    return vimgui_android_ui_scale(vm,context,1);
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiInputView_notifyGamepadDisconnected(JNIEnv*, jclass, jint device_id) {
    vimgui_android_gamepad_disconnected(device_id);
}
