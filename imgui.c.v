module imgui

#flag -I @VMODROOT/include

$if android {
	$if arm64 {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/android-vulkan/arm64-v8a/freetype/libvimgui.a
				#flag @VMODROOT/lib/android-vulkan/arm64-v8a/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/android-vulkan/arm64-v8a/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/android-vulkan/arm64-v8a/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/android-vulkan/arm64-v8a
			}
		}
	} $else $if amd64 {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/android-vulkan/x86_64/freetype/libvimgui.a
				#flag @VMODROOT/lib/android-vulkan/x86_64/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/android-vulkan/x86_64/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/android-vulkan/x86_64/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/android-vulkan/x86_64
			}
		}
	} $else {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/android-vulkan/armeabi-v7a/freetype/libvimgui.a
				#flag @VMODROOT/lib/android-vulkan/armeabi-v7a/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/android-vulkan/armeabi-v7a/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/android-vulkan/armeabi-v7a/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/android-vulkan/armeabi-v7a
			}
		}
	}
	$if !imgui_static ? {
		#flag -l vimgui
	}
	#flag -landroid -llog
	$if imgui_static ? {
		#flag -lc++_static -lc++abi -latomic
	}
} $else $if ios {
	$if imgui_ios_device ? {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/iphoneos/arm64/freetype/libvimgui.a
				#flag @VMODROOT/lib/apple-metal/iphoneos/arm64/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/iphoneos/arm64/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/iphoneos/arm64/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/iphoneos/arm64
			}
		}
	} $else $if arm64 {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/iphonesimulator/arm64/freetype/libvimgui.a
				#flag @VMODROOT/lib/apple-metal/iphonesimulator/arm64/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/iphonesimulator/arm64/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/iphonesimulator/arm64/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/iphonesimulator/arm64
			}
		}
	} $else {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/iphonesimulator/x86_64/freetype/libvimgui.a
				#flag @VMODROOT/lib/apple-metal/iphonesimulator/x86_64/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/iphonesimulator/x86_64/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/iphonesimulator/x86_64/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/iphonesimulator/x86_64
			}
		}
	}
	$if !imgui_static ? {
		#flag -l vimgui
	}
	#flag darwin -lc++ -framework Foundation -framework Metal -framework MetalKit -framework QuartzCore -framework UIKit -framework GameController
} $else $if macos && imgui_metal ? {
	$if arm64 {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/macosx/arm64/freetype/libvimgui.a
				#flag @VMODROOT/lib/apple-metal/macosx/arm64/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/macosx/arm64/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/macosx/arm64/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/macosx/arm64
			}
		}
	} $else {
		$if use_freetype ? {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/macosx/x86_64/freetype/libvimgui.a
				#flag @VMODROOT/lib/apple-metal/macosx/x86_64/freetype/libfreetype.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/macosx/x86_64/freetype
			}
		} $else {
			$if imgui_static ? {
				#flag @VMODROOT/lib/apple-metal/macosx/x86_64/libvimgui.a
			} $else {
				#flag -L @VMODROOT/lib/apple-metal/macosx/x86_64
			}
		}
	}
	$if !imgui_static ? {
		#flag -l vimgui
	}
	#flag darwin -lc++ -framework Foundation -framework Metal -framework MetalKit -framework QuartzCore -framework AppKit -framework GameController
} $else {
	$if imgui_static ? {
		$if use_freetype ? {
			#flag @VMODROOT/lib/freetype/libvimgui.a
			#flag -L @VMODROOT/lib/freetype
			#flag -l freetype
		} $else {
			#flag @VMODROOT/lib/libvimgui.a
		}
		#flag linux -lstdc++
		// Volk stores Vulkan commands in global variables. Keep those executable
		// symbols out of the dynamic symbol table so dlsym(libvulkan, "vk...")
		// cannot resolve back to a pointer slot in the application itself.
		#flag linux -fvisibility=hidden
	} $else {
		$if use_freetype ? {
			#flag -L @VMODROOT/lib/freetype
			#flag linux -Wl,-rpath,@VMODROOT/lib/freetype
		} $else {
			#flag -L @VMODROOT/lib
			#flag linux -Wl,-rpath,@VMODROOT/lib
		}
		#flag -l vimgui
		#flag darwin -Wl,-rpath,@loader_path/../lib
	}
}

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#include "cimgui.h"
