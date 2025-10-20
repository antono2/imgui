@[translated] // Using @translated to write less
module impl_glfw

import glfw

#define CIMGUI_USE_GLFW
#define IMGUI_IMPL_VULKAN

#include "cimgui_impl.h"


@[c: 'ImGui_ImplGlfw_InitForOpenGL']
pub fn init_for_open_gl(window &glfw.Window, install_callbacks bool) bool

@[c: 'ImGui_ImplGlfw_InitForVulkan']
pub fn init_for_vulkan(window &glfw.Window, install_callbacks bool) bool

@[c: 'ImGui_ImplGlfw_InitForOther']
pub fn init_for_other(window &glfw.Window, install_callbacks bool) bool

@[c: 'ImGui_ImplGlfw_Shutdown']
pub fn shutdown()

@[c: 'ImGui_ImplGlfw_NewFrame']
pub fn new_frame()

@[c: 'ImGui_ImplGlfw_InstallCallbacks']
pub fn install_callbacks(window &glfw.Window)

@[c: 'ImGui_ImplGlfw_RestoreCallbacks']
pub fn restore_callbacks(window &glfw.Window)

@[c: 'ImGui_ImplGlfw_SetCallbacksChainForAllWindows']
pub fn set_callbacks_chain_for_all_windows(chain_for_all_windows bool)

@[c: 'ImGui_ImplGlfw_WindowFocusCallback']
pub fn window_focus_callback(window &glfw.Window, focused int)

@[c: 'ImGui_ImplGlfw_CursorEnterCallback']
pub fn cursor_enter_callback(window &glfw.Window, entered int)

@[c: 'ImGui_ImplGlfw_CursorPosCallback']
pub fn cursor_pos_callback(window &glfw.Window, x f64, y f64)

@[c: 'ImGui_ImplGlfw_MouseButtonCallback']
pub fn mouse_button_callback(window &glfw.Window, button int, action int, mods int)

@[c: 'ImGui_ImplGlfw_ScrollCallback']
pub fn scroll_callback(window &glfw.Window, xoffset f64, yoffset f64)

@[c: 'ImGui_ImplGlfw_KeyCallback']
pub fn key_callback(window &glfw.Window, key int, scancode int, action int, mods int)

@[c: 'ImGui_ImplGlfw_CharCallback']
pub fn char_callback(window &glfw.Window, c u32)

@[c: 'ImGui_ImplGlfw_MonitorCallback']
pub fn monitor_callback(monitor &glfw.Monitor, event int)

@[c: 'ImGui_ImplGlfw_Sleep']
pub fn sleep(milliseconds int)


