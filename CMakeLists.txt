cmake_minimum_required(VERSION 3.16)

Project(vimgui)
set(NAME ${PROJECT_NAME})

set(VIMGUI_PROFILE "desktop" CACHE STRING "Native backend profile: desktop, android-vulkan, or apple-metal")
set_property(CACHE VIMGUI_PROFILE PROPERTY STRINGS desktop android-vulkan apple-metal)
if(NOT VIMGUI_PROFILE STREQUAL "desktop" AND NOT VIMGUI_PROFILE STREQUAL "android-vulkan" AND NOT VIMGUI_PROFILE STREQUAL "apple-metal")
	message(FATAL_ERROR "Unsupported VIMGUI_PROFILE: ${VIMGUI_PROFILE}")
endif()
if(VIMGUI_PROFILE STREQUAL "android-vulkan" AND NOT ANDROID)
	message(FATAL_ERROR "android-vulkan requires the Android NDK toolchain")
endif()
if(ANDROID AND NOT VIMGUI_PROFILE STREQUAL "android-vulkan")
	message(FATAL_ERROR "Android builds require VIMGUI_PROFILE=android-vulkan")
endif()
if(VIMGUI_PROFILE STREQUAL "apple-metal")
	if(NOT APPLE)
		message(FATAL_ERROR "apple-metal requires an Apple SDK and Clang")
	endif()
	enable_language(OBJCXX)
endif()

if(WIN32) # For mingw
	set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif(WIN32)

set(CMAKE_CXX_STANDARD 11)
if(VIMGUI_PROFILE STREQUAL "apple-metal")
	set(CMAKE_OBJCXX_STANDARD 11)
endif()

# General settings
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cimgui/imgui/backends)
	set(BACKENDS_FOLDER "cimgui/imgui/backends")
else()
	set(BACKENDS_FOLDER "cimgui/imgui/examples")
endif()

if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cimgui/imgui/imgui_tables.cpp)
	set(TABLES_SOURCE "cimgui/imgui/imgui_tables.cpp")
else()
	set(TABLES_SOURCE "")
endif()

include_directories(cimgui/imgui)
include_directories(cimgui)
include_directories(cimplot)
include_directories(cimgui/generator/output/)
add_definitions("-DIMGUI_USER_CONFIG=\"../include/cimconfig.h\"")
add_definitions("-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1")

option(CIMGUI_NO_EXPORT "Do not export cimgui/cimplot API symbols from a Windows DLL" ON)
if(CIMGUI_NO_EXPORT)
	add_compile_definitions(CIMGUI_NO_EXPORT)
endif()

set(IMGUI_SOURCES 
cimgui/cimgui.cpp 
cimgui/imgui/imgui.cpp 
cimgui/imgui/imgui_draw.cpp 
cimgui/imgui/imgui_demo.cpp 
cimgui/imgui/imgui_widgets.cpp
${TABLES_SOURCE} 
cimplot/cimplot.cpp
cimplot/implot/implot.cpp
cimplot/implot/implot_demo.cpp
cimplot/implot/implot_items.cpp
)

set(VIMGUI_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/lib" CACHE PATH "Output directory for libvimgui")
set(LIBDIR "${VIMGUI_OUTPUT_DIR}")
message(STATUS "LIBDIR: ${LIBDIR}")

set(IMGUI_LIBRARIES )

if(NOT VIMGUI_PROFILE STREQUAL "apple-metal")
	add_compile_definitions("IMGUI_IMPL_VULKAN")
endif()

# Optional FreeType loader. The bundled provider is pinned by .gitmodules.
option(IMGUI_FREETYPE "Enable Dear ImGui's FreeType font loader" OFF)
set(VIMGUI_FREETYPE_PROVIDER "system" CACHE STRING "FreeType provider: system or bundled")
set_property(CACHE VIMGUI_FREETYPE_PROVIDER PROPERTY STRINGS system bundled)

if(IMGUI_FREETYPE)
	if(VIMGUI_FREETYPE_PROVIDER STREQUAL "bundled")
		if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/freetype/CMakeLists.txt")
			message(FATAL_ERROR "Missing FreeType submodule; run git submodule update --init --recursive")
		endif()
		set(FT_DISABLE_ZLIB ON CACHE BOOL "" FORCE)
		set(FT_DISABLE_BZIP2 ON CACHE BOOL "" FORCE)
		set(FT_DISABLE_PNG ON CACHE BOOL "" FORCE)
		set(FT_DISABLE_HARFBUZZ ON CACHE BOOL "" FORCE)
		set(FT_DISABLE_BROTLI ON CACHE BOOL "" FORCE)
		set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
		set(BUILD_SHARED_LIBS OFF)
		add_subdirectory(third_party/freetype)
		unset(BUILD_SHARED_LIBS)
		list(APPEND IMGUI_LIBRARIES freetype)
	elseif(VIMGUI_FREETYPE_PROVIDER STREQUAL "system")
		if(ANDROID OR CMAKE_SYSTEM_NAME STREQUAL "iOS")
			message(FATAL_ERROR "Mobile cross-builds require VIMGUI_FREETYPE_PROVIDER=bundled")
		endif()
		find_package(Freetype REQUIRED)
		list(APPEND IMGUI_LIBRARIES Freetype::Freetype)
	else()
		message(FATAL_ERROR "VIMGUI_FREETYPE_PROVIDER must be system or bundled")
	endif()
	list(APPEND IMGUI_SOURCES cimgui/imgui/misc/freetype/imgui_freetype.cpp)
	# cimgui's generated bridge still exports the stb loader entry point, so
	# retain its implementation while FreeType becomes ImGui's default loader.
	add_compile_definitions(IMGUI_ENABLE_FREETYPE=1 IMGUI_ENABLE_STB_TRUETYPE=1)
endif(IMGUI_FREETYPE)

# Vulkan headers are required, but do not link Vulkan::Vulkan here. Applications
# in this repository use Volk, whose vk* globals share names with loader entry
# points. Mixing both dispatch strategies caused calls through uninitialized
# storage on some systems. IMGUI_IMPL_VULKAN_NO_PROTOTYPES below gives ImGui a
# private function table populated through ImGui_ImplVulkan_LoadFunctions.
if(VIMGUI_PROFILE STREQUAL "desktop")
	find_package(Vulkan REQUIRED)
	include_directories(${Vulkan_INCLUDE_DIRS})
endif()
if(NOT VIMGUI_PROFILE STREQUAL "apple-metal")
	list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_vulkan.cpp)
endif()

# Platform backend
if(VIMGUI_PROFILE STREQUAL "android-vulkan")
	list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_android.cpp)
	list(APPEND IMGUI_SOURCES native/android/vimgui_android.cpp)
	list(APPEND IMGUI_SOURCES native/mobile/vimgui_scale.cpp)
	list(APPEND IMGUI_LIBRARIES android log)
elseif(VIMGUI_PROFILE STREQUAL "apple-metal")
	list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_metal.mm)
	list(APPEND IMGUI_SOURCES native/apple/vimgui_metal.mm)
	list(APPEND IMGUI_SOURCES native/mobile/vimgui_scale.cpp)
	list(APPEND IMGUI_LIBRARIES "-framework Foundation" "-framework Metal" "-framework MetalKit" "-framework QuartzCore")
	if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
		list(APPEND IMGUI_SOURCES native/apple/vimgui_ios.mm)
		list(APPEND IMGUI_LIBRARIES "-framework UIKit")
	else()
		list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_osx.mm)
		list(APPEND IMGUI_SOURCES native/apple/vimgui_osx.mm)
		list(APPEND IMGUI_LIBRARIES "-framework AppKit" "-framework GameController")
	endif()
else()
	list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_glfw.cpp)
endif()

set(VIMGUI_GLFW_PROVIDER "system" CACHE STRING "GLFW provider: system or bundled")
set_property(CACHE VIMGUI_GLFW_PROVIDER PROPERTY STRINGS system bundled)
set(VIMGUI_GLFW_VERSION "3.3" CACHE STRING "Bundled GLFW release tag")

if(NOT VIMGUI_PROFILE STREQUAL "desktop")
	# Android uses ANativeWindow and AInputEvent; GLFW is a desktop dependency.
elseif(VIMGUI_GLFW_PROVIDER STREQUAL "system")
	find_package(glfw3 CONFIG REQUIRED)
elseif(VIMGUI_GLFW_PROVIDER STREQUAL "bundled")
	include(FetchContent)
	FetchContent_Declare(glfw
		URL "https://github.com/glfw/glfw/archive/refs/tags/${VIMGUI_GLFW_VERSION}.tar.gz"
		DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
	set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
	set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
	set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
	set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
	if(NOT STATIC_BUILD)
		set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
	endif()
	FetchContent_MakeAvailable(glfw)
	include_directories(${glfw_SOURCE_DIR}/include)
else()
	message(FATAL_ERROR "VIMGUI_GLFW_PROVIDER must be system or bundled")
endif()

# Create target
if (NOT STATIC_BUILD)
    add_library(${NAME} SHARED ${IMGUI_SOURCES})
else()
    add_library(${NAME} STATIC ${IMGUI_SOURCES})
    add_definitions("-DIMGUI_STATIC=1")
endif()

set_target_properties(${NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${LIBDIR}
    ARCHIVE_OUTPUT_DIRECTORY ${LIBDIR}
    RUNTIME_OUTPUT_DIRECTORY ${LIBDIR}
)
if(TARGET freetype AND IMGUI_FREETYPE AND VIMGUI_FREETYPE_PROVIDER STREQUAL "bundled")
	set_target_properties(freetype PROPERTIES
		ARCHIVE_OUTPUT_DIRECTORY ${LIBDIR}
		POSITION_INDEPENDENT_CODE ON)
endif()

# Multi-config generators such as Visual Studio otherwise append a Release or
# Debug subdirectory, while the V module looks for the import library directly
# in lib/. Keep every supported configuration in the documented location.
foreach(OUTPUT_CONFIG Debug Release RelWithDebInfo MinSizeRel)
	string(TOUPPER "${OUTPUT_CONFIG}" OUTPUT_CONFIG_UPPER)
	set_target_properties(${NAME} PROPERTIES
		LIBRARY_OUTPUT_DIRECTORY_${OUTPUT_CONFIG_UPPER} ${LIBDIR}
		ARCHIVE_OUTPUT_DIRECTORY_${OUTPUT_CONFIG_UPPER} ${LIBDIR}
		RUNTIME_OUTPUT_DIRECTORY_${OUTPUT_CONFIG_UPPER} ${LIBDIR})
endforeach()

if(UNIX AND NOT APPLE AND NOT STATIC_BUILD)
	# Resolve a packaged GLFW beside libvimgui rather than from this build tree.
	set_target_properties(${NAME} PROPERTIES BUILD_RPATH "\$ORIGIN" INSTALL_RPATH "\$ORIGIN")
endif()

if(UNIX)
    set_property(TARGET ${NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)
endif(UNIX)

if (MINGW)
    target_link_options(${NAME} PRIVATE -mconsole)
endif(MINGW)

if (WIN32)
    target_compile_definitions(${NAME} PUBLIC "-DIMGUI_IMPL_API=extern \"C\" __declspec\(dllexport\)")
else(WIN32)
    target_compile_definitions(${NAME} PUBLIC "-DIMGUI_IMPL_API=extern \"C\" ")
endif(WIN32)

if(VIMGUI_PROFILE STREQUAL "apple-metal")
	target_compile_definitions(${NAME} PUBLIC CIMGUI_USE_METAL)
else()
	target_compile_definitions(${NAME} PUBLIC CIMGUI_USE_VULKAN IMGUI_IMPL_VULKAN_NO_PROTOTYPES)
endif()
if(VIMGUI_PROFILE STREQUAL "desktop")
	target_compile_definitions(${NAME} PUBLIC CIMGUI_USE_GLFW)
elseif(VIMGUI_PROFILE STREQUAL "apple-metal")
	target_compile_options(${NAME} PRIVATE $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>)
endif()

# GCC can report a false-positive bounds warning from ImVector::push_back while
# optimizing the upstream Vulkan backend. Keep warnings from our own sources
# visible while silencing this known header-level diagnostic.
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
	target_compile_options(${NAME} PRIVATE -Wno-stringop-overflow)
endif()

target_link_libraries(${NAME} PUBLIC ${IMGUI_LIBRARIES})
if(VIMGUI_PROFILE STREQUAL "desktop")
	target_link_libraries(${NAME} PUBLIC glfw)
endif()

option(VIMGUI_BUILD_SMOKE_TESTS "Build platform link smoke tests" OFF)
if(VIMGUI_BUILD_SMOKE_TESTS AND VIMGUI_PROFILE STREQUAL "android-vulkan")
	add_library(vimgui_android_link_smoke SHARED tests/android/native_link_smoke.cpp)
	target_include_directories(vimgui_android_link_smoke PRIVATE native/android)
	target_link_libraries(vimgui_android_link_smoke PRIVATE ${NAME})
	target_link_options(vimgui_android_link_smoke PRIVATE -Wl,--no-undefined)
	add_executable(vimgui_android_device_probe tests/android/vulkan_device_probe.cpp)
	target_link_libraries(vimgui_android_device_probe PRIVATE ${NAME} vulkan)
	target_link_options(vimgui_android_device_probe PRIVATE -Wl,--no-undefined)
	add_executable(vimgui_vulkan_offscreen_probe tests/vulkan/offscreen_probe.cpp)
	target_link_libraries(vimgui_vulkan_offscreen_probe PRIVATE ${NAME} vulkan)
	target_link_options(vimgui_vulkan_offscreen_probe PRIVATE -Wl,--no-undefined)
endif()
if(VIMGUI_BUILD_SMOKE_TESTS AND VIMGUI_PROFILE STREQUAL "desktop" AND UNIX AND NOT APPLE)
	add_executable(vimgui_vulkan_offscreen_probe
		tests/vulkan/offscreen_probe.cpp
		native/mobile/vimgui_scale.cpp)
	target_link_libraries(vimgui_vulkan_offscreen_probe PRIVATE ${NAME} Vulkan::Vulkan)
endif()
if(VIMGUI_BUILD_SMOKE_TESTS AND VIMGUI_PROFILE STREQUAL "apple-metal")
	add_library(vimgui_apple_link_smoke SHARED tests/apple/native_link_smoke.mm)
	target_link_libraries(vimgui_apple_link_smoke PRIVATE ${NAME})
	target_link_options(vimgui_apple_link_smoke PRIVATE -Wl,-undefined,error)
	if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
		target_compile_definitions(vimgui_apple_link_smoke PRIVATE VIMGUI_TEST_IOS=1)
	endif()
endif()
