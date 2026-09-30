module impl_metal

import antono2.imgui

#flag -I @VMODROOT/native/apple
#include "vimgui_metal.h"

fn C.vimgui_metal_init(device voidptr) bool
fn C.vimgui_metal_new_frame(render_pass_descriptor voidptr)
fn C.vimgui_metal_render_draw_data(draw_data voidptr, command_buffer voidptr, render_command_encoder voidptr)
fn C.vimgui_metal_shutdown()

// Metal objects are borrowed Objective-C pointers owned by the application.
pub fn init(device voidptr) bool {
	return C.vimgui_metal_init(device)
}

pub fn new_frame(render_pass_descriptor voidptr) {
	C.vimgui_metal_new_frame(render_pass_descriptor)
}

pub fn render_draw_data(draw_data &imgui.ImDrawData, command_buffer voidptr, render_command_encoder voidptr) {
	C.vimgui_metal_render_draw_data(draw_data, command_buffer, render_command_encoder)
}

pub fn shutdown() {
	C.vimgui_metal_shutdown()
}
