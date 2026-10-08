// Exercises desktop binding integration against the advisory moving-dependency configuration.
module main

import os
import antono2.glfw
import antono2.imgui
import antono2.imgui.impl_glfw
import antono2.imgui.impl_vulkan
import antono2.vulkan as vk

fn no_vulkan_function(function_name &char, user_data voidptr) voidptr {
	_ = function_name
	_ = user_data
	return unsafe { nil }
}

// The CI job links this against the native library and current V, Vulkan and
// GLFW modules. No display or GPU is needed to execute the safe path.
fn main() {
	context := imgui.create_context(unsafe { nil })
	assert context != unsafe { nil }
	assert int(vk.Result.success) == 0
	if os.args.len > 100 {
		// Keep representative platform and renderer calls in the linked binary.
		_ = glfw.initialize()
		_ = impl_glfw.init_for_vulkan(unsafe { nil }, false)
		_ = impl_vulkan.load_functions(0, no_vulkan_function, unsafe { nil })
	}
	imgui.destroy_context(context)
	println('Moving V/Vulkan/GLFW integration linked')
}
