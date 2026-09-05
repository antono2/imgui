cmake_minimum_required(VERSION 3.16)

Project(vimgui)
set(NAME ${PROJECT_NAME})

if(WIN32) # For mingw
	set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif(WIN32)

set(CMAKE_CXX_STANDARD 11)

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

add_compile_definitions("IMGUI_IMPL_VULKAN")

# Optional freetype
option(IMGUI_FREETYPE "add Freetype2" OFF)

if(IMGUI_FREETYPE)
	FIND_PACKAGE(freetype REQUIRED PATHS ${FREETYPE_PATH})
	list(APPEND IMGUI_LIBRARIES freetype)
	list(APPEND IMGUI_SOURCES include/imgui/misc/freetype/imgui_freetype.cpp)
	add_definitions("-DCIMGUI_FREETYPE=1")
endif(IMGUI_FREETYPE)

# Vulkan headers are required, but do not link Vulkan::Vulkan here. Applications
# in this repository use Volk, whose vk* globals share names with loader entry
# points. Mixing both dispatch strategies caused calls through uninitialized
# storage on some systems. IMGUI_IMPL_VULKAN_NO_PROTOTYPES below gives ImGui a
# private function table populated through ImGui_ImplVulkan_LoadFunctions.
find_package(Vulkan REQUIRED)
list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_vulkan.cpp)
include_directories(${Vulkan_INCLUDE_DIRS})

# GLFW
list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_glfw.cpp)

set(VIMGUI_GLFW_PROVIDER "system" CACHE STRING "GLFW provider: system or bundled")
set_property(CACHE VIMGUI_GLFW_PROVIDER PROPERTY STRINGS system bundled)
set(VIMGUI_GLFW_VERSION "3.3" CACHE STRING "Bundled GLFW release tag")

if(VIMGUI_GLFW_PROVIDER STREQUAL "system")
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

target_compile_definitions(${NAME} PUBLIC
	-DCIMGUI_USE_VULKAN
	-DCIMGUI_USE_GLFW
	-DIMGUI_IMPL_VULKAN_NO_PROTOTYPES)

# GCC can report a false-positive bounds warning from ImVector::push_back while
# optimizing the upstream Vulkan backend. Keep warnings from our own sources
# visible while silencing this known header-level diagnostic.
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
	target_compile_options(${NAME} PRIVATE -Wno-stringop-overflow)
endif()

target_link_libraries(${NAME} PUBLIC ${IMGUI_LIBRARIES} glfw)
