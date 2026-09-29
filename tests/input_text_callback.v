module main

import antono2.imgui

struct SelectionProbe {
mut:
	calls              int
	observed_selection bool
}

fn track_selection(mut data imgui.InputTextCallbackData) i32 {
	unsafe {
		probe := &SelectionProbe(data.UserData)
		probe.calls++
		if probe.calls == 1 {
			// The callback uses UTF-8 byte offsets, not Unicode scalar indices.
			imgui.input_text_callback_data_set_selection(data, 1, 7)
		} else if data.SelectionStart == 1 && data.SelectionEnd == 7 {
			probe.observed_selection = true
		}
	}
	assert data.CursorPos >= 0
	assert data.CursorPos <= data.BufTextLen
	assert data.SelectionStart >= 0
	assert data.SelectionStart <= data.BufTextLen
	assert data.SelectionEnd >= 0
	assert data.SelectionEnd <= data.BufTextLen
	return 0
}

fn main() {
	context := imgui.create_context(unsafe { nil })
	assert context != unsafe { nil }
	io := imgui.get_io_nil()
	unsafe {
		io.DisplaySize = imgui.ImVec2_c{ x: 640, y: 480 }
		io.DeltaTime = 1.0 / 60.0
		io.BackendFlags = imgui.BackendFlags(imgui.BackendFlags_.renderer_has_textures)
		io.IniFilename = nil
	}
	mut probe := SelectionProbe{}
	mut buffer := [128]u8{}
	for index, byte in 'aé🙂z'.bytes() {
		buffer[index] = byte
	}
	for _ in 0 .. 3 {
		imgui.new_frame()
		imgui.begin(c'InputText callback smoke', unsafe { nil }, 0)
		imgui.set_keyboard_focus_here(0)
		imgui.input_text(c'Text', unsafe { &char(&buffer[0]) }, usize(buffer.len),
			imgui.InputTextFlags(imgui.InputTextFlags_.callback_always), track_selection,
			voidptr(&probe))
		imgui.end()
		imgui.render()
	}
	assert probe.calls > 1
	assert probe.observed_selection
	imgui.destroy_context(context)
}
