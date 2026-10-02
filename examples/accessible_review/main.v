module main

import antono2.imgui.appui
import os

struct Demo {
mut:
	initialized bool
	contrast    bool
	large_text  bool
	selected    u64 = 1000
	query       appui.TextBuffer
	status      string = 'Choose a file. Keyboard and screen-reader actions use the same controls.'
}

fn populate(query string) {
	appui.list_reset(20)
	count := if os.getenv('VIMGUI_DEMO_ROWS') != '' { os.getenv('VIMGUI_DEMO_ROWS').int() } else { 100000 }
	for i in 0 .. count {
		label := 'Photo ${i:06}.jpg — Pictures / Archive'
		if query == '' || label.to_lower().contains(query.to_lower()) {
			appui.list_add(20, u64(i + 1000), label) or { panic(err) }
		}
	}
}

fn frame(data voidptr) {
	mut demo := unsafe { &Demo(data) }
	if !demo.initialized {
		appui.theme(true, false, 1, false)
		populate('')
		demo.initialized = true
	}
	appui.text(2, 'Accessible file review')
	if appui.checkbox(3, 'High contrast', &demo.contrast) {
		appui.theme(true, demo.contrast, if demo.large_text { f32(2) } else { f32(1) }, false)
	}
	appui.same_line()
	if appui.checkbox(4, '200% text', &demo.large_text) {
		appui.theme(true, demo.contrast, if demo.large_text { f32(2) } else { f32(1) }, false)
	}
	appui.set_width(-1)
	if appui.input(5, 'Search files', mut demo.query) { populate(demo.query.text()) }
	if appui.button(6, 'Focus last file') { appui.focus(100999) }
	appui.same_line()
	if appui.button(7, 'Keep selected') {
		demo.status = 'Keeper saved: Photo ${demo.selected - 1000:06}.jpg'
	}
	appui.status(8, demo.status)
	selected := appui.list(20, 'Files', demo.selected, 0)
	if selected != 0 {
		demo.selected = selected
	}
}

fn main() {
	mut demo := &Demo{ query: appui.text_buffer('', 4096) or { panic(err) } }
	appui.run(appui.Options{ title: 'Accessible ImGui review', smoke_frames: if '--smoke-test' in os.args {
		5
	} else {
		0
	} }, frame, demo) or { panic(err) }
}
