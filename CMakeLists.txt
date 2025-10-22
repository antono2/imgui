cmake_minimum_required(VERSION 3.16)

Project(vimgui)
set(NAME ${PROJECT_NAME})

if(WIN32) # For mingw
	set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif(WIN32)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DVK_PROTOTYPES")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DVK_PROTOTYPES")

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

if(APPLE)
    set(BASEDIR @loader_path)
else()
    set(BASEDIR ${CMAKE_CURRENT_BINARY_DIR})
endif()
# LIBDIR is absolute path
set(LIBDIR "${BASEDIR}/lib")
message(STATUS "LIBDIR: ${LIBDIR}")

set(CMAKE_INSTALL_PREFIX ${BASEDIR})

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

# Vulkan
find_package(Vulkan REQUIRED)
list(APPEND IMGUI_LIBRARIES Vulkan::Vulkan)
list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_vulkan.cpp)
include_directories(${Vulkan_INCLUDE_DIRS})

# GLFW
list(APPEND IMGUI_SOURCES ${BACKENDS_FOLDER}/imgui_impl_glfw.cpp)

set(GLFW_VERSION 3.4)
include(FetchContent)
	FetchContent_Declare(
   	 glfw
   	 URL https://github.com/glfw/glfw/archive/refs/tags/${GLFW_VERSION}.tar.gz)

FetchContent_GetProperties(glfw)
if (NOT glfw_POPULATED)
	set(FETCHCONTENT_QUIET NO)
	FetchContent_Populate(glfw)
	set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
	set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
	set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
	if (NOT STATIC_BUILD)
		set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
	endif()
	#add_subdirectory(${glfw_SOURCE_DIR} ${glfw_BINARY_DIR} EXCLUDE_FROM_ALL)
	add_subdirectory(${glfw_SOURCE_DIR} ${glfw_BINARY_DIR})
endif()
include_directories(${glfw_SOURCE_DIR}/include)

# If dynamic glfw then install
if (NOT STATIC_BUILD)
  install(TARGETS glfw RUNTIME DESTINATION ${LIBDIR} LIBRARY DESTINATION ${LIBDIR})
  #FIND_PACKAGE(glfw3 PATHS "C:/LuaGL/gitsources/BUILDS/GLFW/install" REQUIRED)
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

target_compile_definitions(${NAME} PUBLIC -DCIMGUI_USE_VULKAN -DCIMGUI_USE_GLFW)

target_link_libraries(${NAME} PUBLIC ${IMGUI_LIBRARIES} glfw)


