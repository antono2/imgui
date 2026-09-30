module impl_ios

import antono2.imgui

#flag -I @VMODROOT/native/apple
#include "vimgui_ios.h"

fn C.vimgui_ios_init() bool
fn C.vimgui_ios_new_frame(width f32, height f32, framebuffer_scale f32, delta_seconds f32)
fn C.vimgui_ios_touch(touch_id u64, x f32, y f32, down bool)
fn C.vimgui_ios_key(imgui_key int, down bool)
fn C.vimgui_ios_text_utf8(committed_text &char)
fn C.vimgui_ios_wants_text_input() bool
fn C.vimgui_ios_keyboard_create(parent_view voidptr) voidptr
fn C.vimgui_ios_keyboard_set_visible(keyboard voidptr, visible bool) bool
fn C.vimgui_ios_keyboard_destroy(keyboard voidptr)
fn C.vimgui_ios_shutdown()

pub fn init_platform() bool {
	return C.vimgui_ios_init()
}

// new_frame accepts UIKit point dimensions; the scale maps points to drawable pixels.
pub fn new_frame(width f32, height f32, framebuffer_scale f32, delta_seconds f32) {
	C.vimgui_ios_new_frame(width, height, framebuffer_scale, delta_seconds)
}

// touch uses a stable UITouch identity and maps the primary touch to ImGui's pointer.
pub fn touch(touch_id u64, x f32, y f32, down bool) {
	C.vimgui_ios_touch(touch_id, x, y, down)
}

pub fn key(key imgui.Key, down bool) {
	C.vimgui_ios_key(int(key), down)
}

// Feed only committed UTF-8 text; marked-text preedit is not supported yet.
pub fn text_utf8(committed_text string) {
	C.vimgui_ios_text_utf8(committed_text.str)
}

pub fn wants_text_input() bool {
	return C.vimgui_ios_wants_text_input()
}

// keyboard_create attaches a small UIKit UIKeyInput responder to a UIView.
// Call on the UIKit thread after init_platform; destroy before the parent view.
// It handles committed text and Backspace, but not marked-text composition.
pub fn keyboard_create(parent_view voidptr) voidptr {
	return C.vimgui_ios_keyboard_create(parent_view)
}

pub fn keyboard_set_visible(keyboard voidptr, visible bool) bool {
	return C.vimgui_ios_keyboard_set_visible(keyboard, visible)
}

pub fn keyboard_destroy(keyboard voidptr) {
	C.vimgui_ios_keyboard_destroy(keyboard)
}

pub fn shutdown() {
	C.vimgui_ios_shutdown()
}
