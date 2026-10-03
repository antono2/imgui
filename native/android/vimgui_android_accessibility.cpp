#include "../accessibility/vimgui_accessibility.h"
#include <jni.h>
#include <cstdint>

namespace {
vimgui_accessibility *context(jlong value) {
    return reinterpret_cast<vimgui_accessibility *>(static_cast<uintptr_t>(value));
}
}
extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeRetain(JNIEnv *, jclass, jlong value) {
    vimgui_accessibility_retain(context(value));
}
extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeRelease(JNIEnv *, jclass, jlong value) {
    vimgui_accessibility_free(context(value));
}
extern "C" JNIEXPORT jboolean JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeAttach(JNIEnv *env, jclass, jlong value, jobject view) {
    return vimgui_accessibility_attach(context(value), view, env) ? JNI_TRUE : JNI_FALSE;
}
extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeDetach(JNIEnv *, jclass, jlong value) {
    vimgui_accessibility_detach(context(value));
}
extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeUpdate(JNIEnv *, jclass, jlong value) {
    vimgui_accessibility_update(context(value));
}

extern "C" JNIEXPORT void JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeVisualFocus(JNIEnv *, jclass, jlong value,
                                                        jboolean visible, jint x, jint y, jint width, jint height) {
    vimgui_accessibility_set_visual_focus(context(value), visible, x, y, width, height);
}

#include "../accessibility/platform.h"
#include <codecvt>
#include <locale>
#include <sstream>
namespace {
void json_string(std::ostream &out,const std::string &value) {
    out<<'"';
    for(unsigned char c:value) {
        if(c=='"'||c=='\\')out<<'\\'<<char(c);
        else if(c<32){const char *hex="0123456789abcdef";out<<"\\u00"<<hex[c>>4]<<hex[c&15];}
        else out<<char(c);
    }
    out<<'"';
}
}
extern "C" JNIEXPORT jstring JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeSnapshot(JNIEnv *env,jclass,jlong value,jlong revision) {
    auto tree=accessibility_snapshot(context(value));
    if(tree.revision==static_cast<uint64_t>(revision))return nullptr;
    std::ostringstream out;
    out<<"{\"revision\":"<<tree.revision<<",\"root\":"<<tree.root<<",\"focus\":"<<tree.focus<<",\"nodes\":[";
    bool first=true;
    for(const auto &entry:tree.nodes) {
        const auto &n=*entry.second;auto bounds=accessibility_bounds(tree,n);
        if(!first)out<<',';first=false;
        out<<"{\"id\":"<<n.id<<",\"role\":"<<n.role<<",\"label\":";json_string(out,n.label);
        out<<",\"value\":";json_string(out,n.value);
        out<<",\"parent\":"<<accessibility_parent(tree,n.id)<<",\"x\":"<<bounds.x<<",\"y\":"<<bounds.y
           <<",\"width\":"<<bounds.width<<",\"height\":"<<bounds.height
           <<",\"actions\":"<<n.actions<<",\"flags\":"<<n.flags<<",\"anchor\":"<<n.text_anchor<<",\"focus\":"<<n.text_focus
           <<",\"number\":"<<n.numeric_value<<",\"min\":"<<n.numeric_min<<",\"max\":"<<n.numeric_max
           <<",\"position\":"<<n.position_in_set<<",\"size\":"<<n.size_of_set<<",\"scroll\":"<<n.scroll_y
           <<",\"scrollMax\":"<<n.scroll_y_max<<",\"children\":[";
        bool child_first=true;for(auto child:n.children){if(!child_first)out<<',';child_first=false;out<<child;}
        out<<"]}";
    }
    out<<"]}";
    try {
        const auto utf16=std::wstring_convert<std::codecvt_utf8_utf16<char16_t>,char16_t>{}.from_bytes(out.str());
        return env->NewString(reinterpret_cast<const jchar *>(utf16.data()),static_cast<jsize>(utf16.size()));
    } catch(const std::range_error &) {return nullptr;}
}
extern "C" JNIEXPORT jboolean JNICALL
Java_io_antono2_imgui_ImGuiAccessibility_nativeAction(JNIEnv *env,jclass,jlong value,jlong id,jint action,jstring text,jint anchor,jint focus) {
    Event event{};event.target=static_cast<uint64_t>(id);event.action=action;
    if(text) {
        const auto *characters=env->GetStringChars(text,nullptr);
        if(!characters)return JNI_FALSE;
        try {event.value=std::wstring_convert<std::codecvt_utf8_utf16<char16_t>,char16_t>{}.to_bytes(
            reinterpret_cast<const char16_t *>(characters),reinterpret_cast<const char16_t *>(characters)+env->GetStringLength(text));}
        catch(const std::range_error &){env->ReleaseStringChars(text,characters);return JNI_FALSE;}
        env->ReleaseStringChars(text,characters);
    }
    if(anchor<0||focus<0)return JNI_FALSE;
    event.anchor=static_cast<size_t>(anchor);event.focus=static_cast<size_t>(focus);
    return accessibility_enqueue(context(value),std::move(event))?JNI_TRUE:JNI_FALSE;
}
