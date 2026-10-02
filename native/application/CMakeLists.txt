cmake_minimum_required(VERSION 3.20)
project(vimgui_application LANGUAGES C CXX)
if(APPLE)
  # Enable this in the parent scope before the folder-dialog dependency uses it.
  enable_language(OBJCXX)
endif()
set(VIMGUI_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
add_subdirectory("${VIMGUI_ROOT}/native/accessibility" accessibility)
find_package(glfw3 REQUIRED)
include(FetchContent)
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()
set(NFD_PORTAL ON CACHE BOOL "Use the desktop portal folder chooser on Linux")
set(NFD_BUILD_TESTS OFF CACHE BOOL "Build native file dialog tests")
set(NFD_INSTALL OFF CACHE BOOL "Install native file dialog separately")
FetchContent_Declare(nfd
  URL https://codeload.github.com/btzy/nativefiledialog-extended/tar.gz/refs/tags/v1.3.0
  URL_HASH SHA256=2fea19102cf4d5283a80fb87a784792166988e85bb92baa962d34f72b22dcc1a)
function(vimgui_prepare_dialogs)
  set(BUILD_SHARED_LIBS OFF)
  FetchContent_MakeAvailable(nfd)
  set_target_properties(nfd PROPERTIES POSITION_INDEPENDENT_CODE ON)
endfunction()
vimgui_prepare_dialogs()
add_library(vimgui_app SHARED
  vimgui_app.cpp
  desktop_dialog.cpp
  "${VIMGUI_ROOT}/cimgui/imgui/imgui.cpp"
  "${VIMGUI_ROOT}/cimgui/imgui/imgui_draw.cpp"
  "${VIMGUI_ROOT}/cimgui/imgui/imgui_tables.cpp"
  "${VIMGUI_ROOT}/cimgui/imgui/imgui_widgets.cpp"
  "${VIMGUI_ROOT}/cimgui/imgui/backends/imgui_impl_glfw.cpp")
target_compile_features(vimgui_app PRIVATE cxx_std_17)
target_include_directories(vimgui_app PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}"
  PRIVATE "${VIMGUI_ROOT}/cimgui/imgui" "${VIMGUI_ROOT}/cimgui/imgui/backends")
target_link_libraries(vimgui_app PRIVATE vimgui_accessibility glfw nfd)
if(APPLE)
  target_sources(vimgui_app PRIVATE desktop_metal.mm "${VIMGUI_ROOT}/cimgui/imgui/backends/imgui_impl_metal.mm")
  target_compile_options(vimgui_app PRIVATE "$<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>")
  target_link_libraries(vimgui_app PRIVATE "-framework Metal" "-framework QuartzCore" "-framework Cocoa")
else()
  find_package(Vulkan REQUIRED)
  target_sources(vimgui_app PRIVATE desktop_vulkan.cpp "${VIMGUI_ROOT}/cimgui/imgui/backends/imgui_impl_vulkan.cpp")
  target_link_libraries(vimgui_app PRIVATE Vulkan::Vulkan)
endif()
set_target_properties(vimgui_app PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON
  LIBRARY_OUTPUT_DIRECTORY "${VIMGUI_ROOT}/lib/appui" RUNTIME_OUTPUT_DIRECTORY "${VIMGUI_ROOT}/lib/appui")
option(VIMGUI_APPLICATION_TESTS "Build the desktop host smoke test" ON)
if(VIMGUI_APPLICATION_TESTS)
  add_executable(application_host_smoke ../../tests/accessibility/host_smoke.cpp)
  target_link_libraries(application_host_smoke PRIVATE vimgui_app)
  target_include_directories(application_host_smoke PRIVATE "${VIMGUI_ROOT}/native/accessibility" "${VIMGUI_ROOT}/cimgui/imgui")
endif()
