module impl_android

import antono2.imgui

#flag -I @VMODROOT/native/android
#include "vimgui_android.h"

fn C.vimgui_android_init(native_window voidptr) bool
fn C.vimgui_android_ui_scale(java_vm voidptr, context voidptr, fallback f32) f32
fn C.vimgui_android_set_clipboard_context(java_vm voidptr, context voidptr) bool
fn C.vimgui_android_handle_input_event(input_event voidptr) int
fn C.vimgui_android_new_frame()
fn C.vimgui_android_text_utf8(committed_text &char)
fn C.vimgui_android_wants_text_input() bool
fn C.vimgui_android_clear_gamepad()
fn C.vimgui_android_gamepad_disconnected(device_id int)
fn C.vimgui_android_apply_text_edit(callback_data voidptr) bool
fn C.vimgui_android_shutdown()

// init connects Dear ImGui to an Android ANativeWindow.
pub fn init(native_window voidptr) bool {
	return C.vimgui_android_init(native_window)
}

// set_clipboard_context enables Android clipboard copy/paste. Pass the
// JavaVM and Activity/Context jobject (NativeActivity.vm and .clazz).
// Call after init on the ImGui thread; shutdown releases the JNI references.
pub fn set_clipboard_context(java_vm voidptr, context voidptr) bool {
	return C.vimgui_android_set_clipboard_context(java_vm, context)
}

// ui_scale combines display density and the system text-size preference.
// Query at startup and on configuration changes using a live Context jobject.
pub fn ui_scale(java_vm voidptr, context voidptr, fallback f32) f32 {
    return C.vimgui_android_ui_scale(java_vm, context, fallback)
}

// handle_input_event forwards an AInputEvent from the application's input loop.
pub fn handle_input_event(input_event voidptr) bool {
	return C.vimgui_android_handle_input_event(input_event) != 0
}

pub fn new_frame() {
	C.vimgui_android_new_frame()
}

// Feed text committed by an Android InputConnection, not raw keycodes.
pub fn text_utf8(committed_text string) {
	C.vimgui_android_text_utf8(committed_text.str)
}

pub fn wants_text_input() bool {
	return C.vimgui_android_wants_text_input()
}

// clear_gamepad releases navigation input when a controller disconnects or
// the app loses focus. Android applications should call this on either event.
pub fn clear_gamepad() {
	C.vimgui_android_clear_gamepad()
}

// gamepad_disconnected is safe to call from an Android InputDeviceListener.
pub fn gamepad_disconnected(device_id int) {
	C.vimgui_android_gamepad_disconnected(device_id)
}

// apply_text_edit synchronizes an Android InputConnection with an active
// InputText widget. Call it from a CallbackAlways callback. Cursor and
// selection positions are converted between Java UTF-16 and ImGui UTF-8.
pub fn apply_text_edit(mut data imgui.InputTextCallbackData) bool {
	return C.vimgui_android_apply_text_edit(voidptr(data))
}

pub fn shutdown() {
	C.vimgui_android_shutdown()
}
