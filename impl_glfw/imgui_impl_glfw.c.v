module impl_glfw

import glfw

#define CIMGUI_USE_GLFW
#define IMGUI_IMPL_VULKAN

#include "cimgui_impl.h"


@[keep_args_alive]
fn C.ImGui_ImplGlfw_InitForOpenGL(window &glfw.Window, install_callbacks bool) bool

@[inline]
pub fn init_for_open_gl(window &glfw.Window, install_callbacks bool) bool {
	return C.ImGui_ImplGlfw_InitForOpenGL(window, install_callbacks)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_InitForVulkan(window &glfw.Window, install_callbacks bool) bool

@[inline]
pub fn init_for_vulkan(window &glfw.Window, install_callbacks bool) bool {
	return C.ImGui_ImplGlfw_InitForVulkan(window, install_callbacks)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_InitForOther(window &glfw.Window, install_callbacks bool) bool

@[inline]
pub fn init_for_other(window &glfw.Window, install_callbacks bool) bool {
	return C.ImGui_ImplGlfw_InitForOther(window, install_callbacks)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_Shutdown()

@[inline]
pub fn shutdown() {
	C.ImGui_ImplGlfw_Shutdown()
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_NewFrame()

@[inline]
pub fn new_frame() {
	C.ImGui_ImplGlfw_NewFrame()
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_InstallCallbacks(window &glfw.Window)

@[inline]
pub fn install_callbacks(window &glfw.Window) {
	C.ImGui_ImplGlfw_InstallCallbacks(window)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_RestoreCallbacks(window &glfw.Window)

@[inline]
pub fn restore_callbacks(window &glfw.Window) {
	C.ImGui_ImplGlfw_RestoreCallbacks(window)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_SetCallbacksChainForAllWindows(chain_for_all_windows bool)

@[inline]
pub fn set_callbacks_chain_for_all_windows(chain_for_all_windows bool) {
	C.ImGui_ImplGlfw_SetCallbacksChainForAllWindows(chain_for_all_windows)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_WindowFocusCallback(window &glfw.Window, focused int)

@[inline]
pub fn window_focus_callback(window &glfw.Window, focused int) {
	C.ImGui_ImplGlfw_WindowFocusCallback(window, focused)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_CursorEnterCallback(window &glfw.Window, entered int)

@[inline]
pub fn cursor_enter_callback(window &glfw.Window, entered int) {
	C.ImGui_ImplGlfw_CursorEnterCallback(window, entered)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_CursorPosCallback(window &glfw.Window, x f64, y f64)

@[inline]
pub fn cursor_pos_callback(window &glfw.Window, x f64, y f64) {
	C.ImGui_ImplGlfw_CursorPosCallback(window, x, y)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_MouseButtonCallback(window &glfw.Window, button int, action int, mods int)

@[inline]
pub fn mouse_button_callback(window &glfw.Window, button int, action int, mods int) {
	C.ImGui_ImplGlfw_MouseButtonCallback(window, button, action, mods)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_ScrollCallback(window &glfw.Window, xoffset f64, yoffset f64)

@[inline]
pub fn scroll_callback(window &glfw.Window, xoffset f64, yoffset f64) {
	C.ImGui_ImplGlfw_ScrollCallback(window, xoffset, yoffset)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_KeyCallback(window &glfw.Window, key int, scancode int, action int, mods int)

@[inline]
pub fn key_callback(window &glfw.Window, key int, scancode int, action int, mods int) {
	C.ImGui_ImplGlfw_KeyCallback(window, key, scancode, action, mods)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_CharCallback(window &glfw.Window, c u32)

@[inline]
pub fn char_callback(window &glfw.Window, c u32) {
	C.ImGui_ImplGlfw_CharCallback(window, c)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_MonitorCallback(monitor &glfw.Monitor, event int)

@[inline]
pub fn monitor_callback(monitor &glfw.Monitor, event int) {
	C.ImGui_ImplGlfw_MonitorCallback(monitor, event)
}

@[keep_args_alive]
fn C.ImGui_ImplGlfw_Sleep(milliseconds int)

@[inline]
pub fn sleep(milliseconds int) {
	C.ImGui_ImplGlfw_Sleep(milliseconds)
}
