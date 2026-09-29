module main

import antono2.imgui
import antono2.imgui.impl_android
import antono2.imgui.impl_mobile

fn main() {
	context := imgui.create_context(unsafe { nil })
	if context == unsafe { nil } {
		panic('Dear ImGui context creation failed')
	}
	assert impl_mobile.set_ui_scale(1.5)
	_ = impl_android.wants_text_input()
	imgui.destroy_context(context)
	println('V Android bindings linked')
}
