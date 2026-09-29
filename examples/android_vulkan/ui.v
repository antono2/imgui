module main

import antono2.imgui

// The native Android host owns the Vulkan swapchain and ImGui frame. This
// exported function keeps the example's actual widget construction in V.
// Its arguments are borrowed for this call and stay owned by the host.
@[export: 'vimgui_android_demo_draw_ui']
fn draw_ui(zoom &f32, tap_count &int, text &char, text_capacity int, display_width f32, display_height f32) bool {
	imgui.set_next_window_pos(imgui.ImVec2_c{ x: 24, y: 24 }, imgui.Cond(imgui.Cond_.first_use_ever), imgui.ImVec2_c{})
	imgui.set_next_window_size(imgui.ImVec2_c{ x: 700, y: 420 }, imgui.Cond(imgui.Cond_.first_use_ever))
	imgui.begin(c'Android Vulkan + FreeType', unsafe { nil }, 0)
	imgui.text_unformatted(c'Tap the button; rotate or background the app.', unsafe { nil })
	if imgui.button(c'Tap here', imgui.ImVec2_c{}) {
		unsafe { *tap_count = *tap_count + 1 }
	}
	imgui.same_line(0, -1)
	count_label := 'count = ${unsafe { *tap_count }}'
	imgui.text_unformatted(count_label.str, unsafe { nil })
	unsafe { count_label.free() }
	imgui.input_text(c'Text', text, usize(text_capacity), 0, unsafe { nil }, unsafe { nil })
	imgui.text_unformatted(c'Committed:', unsafe { nil })
	imgui.same_line(0, -1)
	imgui.text_unformatted(text, unsafe { nil })
	changed := imgui.slider_float(c'UI zoom', zoom, 0.75, 2.0, c'%.3f', 0)
	size_label := 'Display ${int(display_width)} x ${int(display_height)}'
	imgui.text_unformatted(size_label.str, unsafe { nil })
	unsafe { size_label.free() }
	imgui.end()
	return changed
}
