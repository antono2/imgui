module imgui


#flag -I @VMODROOT/include
#flag -I @VMODROOT/include/imgui
#flag -I @VMODROOT/include/imgui/backends
#flag -Wl,-rpath=@VMODROOT/lib
#flag -L @VMODROOT/lib
#flag -l cimgui

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS

#include "cimgui.h"

