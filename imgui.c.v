module imgui

#flag -I @VMODROOT/include
$if imgui_static ? {
	#flag @VMODROOT/lib/libvimgui.a
	#flag linux -lstdc++
	// Volk stores Vulkan commands in global variables. Keep those executable
	// symbols out of the dynamic symbol table so dlsym(libvulkan, "vk...")
	// cannot resolve back to a pointer slot in the application itself.
	#flag linux -fvisibility=hidden
} $else {
	#flag -L @VMODROOT/lib
	#flag -l vimgui
	#flag linux -Wl,-rpath,@VMODROOT/lib
	#flag darwin -Wl,-rpath,@loader_path/../lib
}

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#include "cimgui.h"
