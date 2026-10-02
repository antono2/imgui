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
