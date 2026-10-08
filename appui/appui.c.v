// Hand-maintained application widgets; intentionally independent of generated
// bindings so small applications do not compile the entire ImGui/ImPlot API.
module appui

#flag -I @VMODROOT/native/application
#flag -I @VMODROOT/native/accessibility
$if appui_embedded ? {
	// The embedding host supplies its backend profile's library search path.
	#flag -lvimgui
} $else {
	#flag -L @VMODROOT/lib/appui
	#flag -lvimgui_app
	#flag linux -Wl,-rpath,@VMODROOT/lib/appui
	#flag darwin -Wl,-rpath,@VMODROOT/lib/appui
}
#include "vimgui_app.h"

fn C.vimgui_app_run(&char, int, int, fn (voidptr), voidptr, int) int
fn C.vimgui_app_theme(bool, bool, f32, bool)
fn C.vimgui_app_width() f32
fn C.vimgui_app_height() f32
fn C.vimgui_app_next_control_name(&char)
fn C.vimgui_app_set_text_edit_handler(fn (voidptr, voidptr), voidptr)
fn C.vimgui_app_button(u64, &char) bool
fn C.vimgui_app_checkbox(u64, &char, &bool) bool
fn C.vimgui_app_radio(u64, &char, bool) bool
fn C.vimgui_app_input(u64, &char, &char, usize) bool
fn C.vimgui_app_text(u64, &char)
fn C.vimgui_app_status(u64, &char)
fn C.vimgui_app_progress(u64, &char, f32, &char)
fn C.vimgui_app_same_line()
fn C.vimgui_app_pick_folder(&char, &&char) &char
fn C.vimgui_app_same_line_width(f32)
fn C.vimgui_app_control_width(&char, bool) f32
fn C.vimgui_app_begin_columns(u64, f32, f32)
fn C.vimgui_app_next_column(bool)
fn C.vimgui_app_end_columns()
fn C.vimgui_app_separator()
fn C.vimgui_app_set_width(f32)
fn C.vimgui_app_begin_panel(u64, &char, f32, f32)
fn C.vimgui_app_end_panel()
fn C.vimgui_app_list_reset(u64)
fn C.vimgui_app_list_add(u64, u64, &char) bool
fn C.vimgui_app_list(u64, &char, u64, f32) u64
fn C.vimgui_app_focus(u64)
fn C.vimgui_app_reveal(u64)
fn C.vimgui_app_back_requested() bool
fn C.vimgui_app_scroll(u64) f32
fn C.vimgui_app_restore_scroll(u64,f32)
fn C.vimgui_app_error() &char

pub struct Options {
pub:
	title        string = 'Application'
	width        int    = 1280
	height       int    = 800
	smoke_frames int
}

pub fn run(options Options, frame fn (voidptr), data voidptr) ! {
	$if appui_embedded ? {
		return error('The embedding host owns the application frame loop.')
	} $else {
		code := C.vimgui_app_run(options.title.str, options.width, options.height, frame, data, options.smoke_frames)
		if code != 0 {
			return error('Application host failed (${code}).')
		}
	}
}

pub fn theme(dark bool, contrast bool, scale f32, touch bool) {
	C.vimgui_app_theme(dark, contrast, scale, touch)
}

pub fn width() f32 {
	return C.vimgui_app_width()
}

pub fn height() f32 {
	return C.vimgui_app_height()
}

// Give the next button, checkbox or radio a contextual screen-reader name.
// Include its visible label so speech-control users can identify it too.
pub fn next_control_name(name string) {
	C.vimgui_app_next_control_name(name.str)
}

// Install the embedding host's selection-aware IME callback. Both pointers are
// borrowed and the callback runs on the ImGui rendering thread.
pub fn set_text_edit_handler(handler fn (voidptr, voidptr), userdata voidptr) {
	C.vimgui_app_set_text_edit_handler(handler, userdata)
}

pub fn button(id u64, label string) bool {
	return C.vimgui_app_button(id, label.str)
}

pub fn checkbox(id u64, label string, value &bool) bool {
	return C.vimgui_app_checkbox(id, label.str, value)
}

pub fn radio(id u64, label string, selected bool) bool {
	return C.vimgui_app_radio(id, label.str, selected)
}

pub fn text(id u64, value string) {
	C.vimgui_app_text(id, value.str)
}

pub fn status(id u64, value string) {
	C.vimgui_app_status(id, value.str)
}

// Use a negative fraction while the total amount of work is unknown.
pub fn progress(id u64, label string, fraction f32, detail string) {
	C.vimgui_app_progress(id, label.str, fraction, detail.str)
}

pub fn same_line() {
	C.vimgui_app_same_line()
}

// An empty path means the user cancelled. Mobile/embedding hosts provide their
// own picker and permission handling instead of invoking the desktop dialog.
pub fn pick_folder(initial string) !string {
	$if appui_embedded ? {
		return error('This embedding host must provide its own folder chooser.')
	} $else {
		mut message := unsafe { &char(nil) }
		path := C.vimgui_app_pick_folder(initial.str, &message)
		if message != unsafe { nil } { return error(unsafe { cstring_to_vstring(message) }) }
		if path == unsafe { nil } { return '' }
		return unsafe { cstring_to_vstring(path) }
	}
}

// Wrap buttons, radio controls and checkboxes using their current font/metrics.
pub fn same_line_for(label string, choice bool) {
	C.vimgui_app_same_line_width(C.vimgui_app_control_width(label.str, choice))
}

pub fn same_line_width(width f32) { C.vimgui_app_same_line_width(width) }

pub fn control_width(label string, choice bool) f32 { return C.vimgui_app_control_width(label.str, choice) }
pub fn begin_columns(id u64, minimum f32, trailing f32) { C.vimgui_app_begin_columns(id, minimum, trailing) }
pub fn next_column(align_input bool) { C.vimgui_app_next_column(align_input) }
pub fn end_columns() { C.vimgui_app_end_columns() }

pub fn separator() {
	C.vimgui_app_separator()
}

pub fn set_width(value f32) {
	C.vimgui_app_set_width(value)
}

pub fn begin_panel(id u64, label string, width f32, height f32) {
	C.vimgui_app_begin_panel(id, label.str, width, height)
}

pub fn end_panel() {
	C.vimgui_app_end_panel()
}

pub fn list_reset(id u64) {
	C.vimgui_app_list_reset(id)
}

pub fn list_add(list u64, id u64, label string) ! {
	if !C.vimgui_app_list_add(list, id, label.str) {
		return error(last_error())
	}
}

pub fn list(id u64, label string, selected u64, height f32) u64 {
	return C.vimgui_app_list(id, label.str, selected, height)
}

// Bring a control into its parent viewport when next rendered.
pub fn reveal(id u64) { C.vimgui_app_reveal(id) }

pub fn focus(id u64) {
	C.vimgui_app_focus(id)
}

pub fn last_error() string {
	return unsafe { cstring_to_vstring(C.vimgui_app_error()) }
}

pub struct TextBuffer {
mut:
	bytes []u8
}

pub fn text_buffer(initial string, capacity int) !TextBuffer {
	if capacity <= initial.len || capacity < 2 {
		return error('Text capacity must include the terminating byte.')
	}
	mut buffer := TextBuffer{ bytes: []u8{len: capacity} }
	buffer.set(initial)!
	return buffer
}

pub fn (mut buffer TextBuffer) set(value string) ! {
	if value.len >= buffer.bytes.len {
		return error('Text exceeds field capacity.')
	}
	for i, byte in value.bytes() {
		buffer.bytes[i] = byte
	}
	buffer.bytes[value.len] = 0
}

pub fn (buffer &TextBuffer) text() string {
	mut length := 0
	for length < buffer.bytes.len && buffer.bytes[length] != 0 { length++ }
	return buffer.bytes[..length].bytestr()
}

pub fn input(id u64, label string, mut buffer TextBuffer) bool {
	return unsafe { C.vimgui_app_input(id, label.str, &char(buffer.bytes.data), usize(buffer.bytes.len)) }
}

fn C.vimgui_app_initialize(&char) bool
fn C.vimgui_app_shutdown()
fn C.vimgui_app_frame_begin()
fn C.vimgui_app_frame_end() bool
fn C.vimgui_app_safe_area(f32, f32, f32, f32)

// Embedding hosts call these with an active ImGui context on the render thread.
pub fn initialize(title string) ! {
	if !C.vimgui_app_initialize(title.str) { return error('Could not initialize application UI.') }
}
pub fn shutdown() { C.vimgui_app_shutdown() }
pub fn begin_frame() { C.vimgui_app_frame_begin() }
pub fn end_frame() ! {
	if !C.vimgui_app_frame_end() { return error(last_error()) }
}
pub fn safe_area(left f32, top f32, right f32, bottom f32) {
	C.vimgui_app_safe_area(left, top, right, bottom)
}

pub fn back_requested() bool { return C.vimgui_app_back_requested() }

pub fn scroll(id u64) f32 { return C.vimgui_app_scroll(id) }
pub fn restore_scroll(id u64,position f32) { C.vimgui_app_restore_scroll(id,position) }
