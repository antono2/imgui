// Implements platform file-dialog integration for the desktop application host.
#include "vimgui_app.h"
#include "imgui.h"
#include <nfd.h>
#include <string>
#if !defined(_WIN32) && !defined(__APPLE__)
#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_X11
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>
#endif

const char *vimgui_app_pick_folder(const char *initial, const char **error) {
    static thread_local std::string path, failure;
    path.clear(); failure.clear();
    if (error) *error=nullptr;
    if (NFD_Init()!=NFD_OKAY) {
        const char *message=NFD_GetError();
        failure=message?message:"Could not initialize the native folder chooser.";
        if (error) *error=failure.c_str();
        return nullptr;
    }
    nfdpickfolderu8args_t args{};
    args.defaultPath=initial && *initial?initial:nullptr;
    if (ImGui::GetCurrentContext()) {
        auto *viewport=ImGui::GetMainViewport();
#if defined(_WIN32)
        args.parentWindow={NFD_WINDOW_HANDLE_TYPE_WINDOWS,viewport->PlatformHandleRaw};
#elif defined(__APPLE__)
        args.parentWindow={NFD_WINDOW_HANDLE_TYPE_COCOA,viewport->PlatformHandleRaw};
#else
        if (viewport->PlatformHandle) {
            auto *window=static_cast<GLFWwindow *>(viewport->PlatformHandle);
            args.parentWindow={NFD_WINDOW_HANDLE_TYPE_X11,reinterpret_cast<void *>(glfwGetX11Window(window))};
        }
#endif
    }
    nfdu8char_t *selected=nullptr;
    const nfdresult_t result=NFD_PickFolderU8_With(&selected,&args);
    if (result==NFD_OKAY) { path=selected; NFD_FreePathU8(selected); }
    else if (result==NFD_ERROR) {
        const char *message=NFD_GetError();
        failure=message?message:"The native folder chooser failed.";
    }
    NFD_Quit();
    if (!failure.empty() && error) *error=failure.c_str();
    return result==NFD_OKAY?path.c_str():nullptr;
}
