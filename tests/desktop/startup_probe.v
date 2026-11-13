// Drive the real standalone application's C entry point from V; render three frames.
module main

#flag -I @VMODROOT/native/application
#flag -I @VMODROOT/native/accessibility
#flag -L @VMODROOT/lib/appui
#flag -lvimgui_app
#flag linux -Wl,-rpath,@VMODROOT/lib/appui
#include "vimgui_app.h"

fn C.vimgui_app_run(&char, int, int, fn (voidptr), voidptr, int) int
fn C.vimgui_app_text(u64, &char)

fn draw(raw voidptr) {
	unsafe {
		mut frames := &int(raw)
		*frames += 1
	}
	C.vimgui_app_text(2, c'Window startup probe')
}

fn main() {
	mut frames := 0
	code := C.vimgui_app_run(c'ImGui startup probe', 640, 480, draw, &frames, 3)
	if code != 0 { exit(code) }
	assert frames == 3
}
