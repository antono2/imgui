module main

import antono2.imgui
import antono2.imgui.impl_metal
import antono2.imgui.impl_mobile
import antono2.imgui.impl_osx

// Cross-linked by CI against the macOS SDK; no view or GPU is required.
fn main() {
	context := imgui.create_context(unsafe { nil })
	if context == unsafe { nil } {
		panic('Dear ImGui context creation failed')
	}
	assert impl_mobile.set_ui_scale(2)
	_ = impl_osx.init(unsafe { nil })
	impl_osx.new_frame(unsafe { nil })
	_ = impl_metal.init(unsafe { nil })
	impl_metal.new_frame(unsafe { nil })
	impl_metal.render_draw_data(imgui.get_draw_data(), unsafe { nil }, unsafe { nil })
	impl_metal.shutdown()
	impl_osx.shutdown()
	imgui.destroy_context(context)
	println('V macOS Metal bindings linked')
}
