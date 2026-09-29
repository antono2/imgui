module impl_android

#flag -I @VMODROOT/native/android
#include "vimgui_android.h"

fn C.vimgui_android_init(native_window voidptr) bool
fn C.vimgui_android_handle_input_event(input_event voidptr) int
fn C.vimgui_android_new_frame()
fn C.vimgui_android_text_utf8(committed_text &char)
fn C.vimgui_android_wants_text_input() bool
fn C.vimgui_android_shutdown()

// init connects Dear ImGui to an Android ANativeWindow.
pub fn init(native_window voidptr) bool {
	return C.vimgui_android_init(native_window)
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

pub fn shutdown() {
	C.vimgui_android_shutdown()
}
