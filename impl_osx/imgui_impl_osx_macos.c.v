module impl_osx

#flag -I @VMODROOT/native/apple
#include "vimgui_osx.h"

fn C.vimgui_osx_init(ns_view voidptr) bool
fn C.vimgui_osx_new_frame(ns_view voidptr)
fn C.vimgui_osx_shutdown()

pub fn init(ns_view voidptr) bool {
	return C.vimgui_osx_init(ns_view)
}

pub fn new_frame(ns_view voidptr) {
	C.vimgui_osx_new_frame(ns_view)
}

pub fn shutdown() {
	C.vimgui_osx_shutdown()
}
