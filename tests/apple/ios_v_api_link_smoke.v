module main

import antono2.imgui
import antono2.imgui.impl_ios
import antono2.imgui.impl_metal
import antono2.imgui.impl_mobile

// Cross-linked by CI against the iOS SDK; this executable is not launched.
fn main() {
	context := imgui.create_context(unsafe { nil })
	if context == unsafe { nil } {
		panic('Dear ImGui context creation failed')
	}
	assert impl_ios.init_platform()
	impl_ios.new_frame(320, 240, 2, 1.0 / 60.0)
	assert impl_mobile.set_ui_scale(2)
	impl_ios.touch(1, 10, 10, true)
	impl_ios.text_utf8('a')
	_ = impl_ios.wants_text_input()
	text_view := impl_ios.text_view_create(unsafe { nil })
	_ = impl_ios.text_view_error(text_view)
	impl_ios.text_view_destroy(text_view)
	_ = impl_metal.init(unsafe { nil })
	impl_metal.new_frame(unsafe { nil })
	impl_metal.render_draw_data(imgui.get_draw_data(), unsafe { nil }, unsafe { nil })
	impl_metal.shutdown()
	impl_ios.shutdown()
	imgui.destroy_context(context)
	println('V iOS bindings linked')
}
