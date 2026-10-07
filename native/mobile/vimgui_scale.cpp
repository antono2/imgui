// Applies UI scaling relative to a preserved style baseline to avoid cumulative scaling.
#include "vimgui_scale.h"

#include "../../cimgui/imgui/imgui.h"

#include <cmath>

static ImGuiContext* g_scale_context = nullptr;
static ImGuiStyle g_base_style;
static bool g_have_base_style = false;

extern "C" bool vimgui_mobile_set_ui_scale(float scale)
{
    ImGuiContext* context = ImGui::GetCurrentContext();
    if (context == nullptr || !std::isfinite(scale) || scale <= 0.0f)
        return false;
    if (!g_have_base_style || g_scale_context != context)
    {
        g_base_style = ImGui::GetStyle();
        g_scale_context = context;
        g_have_base_style = true;
    }
    ImGuiStyle& style = ImGui::GetStyle();
    style = g_base_style;
    style.ScaleAllSizes(scale);
    style.FontScaleMain = g_base_style.FontScaleMain * scale;
    return true;
}

extern "C" void vimgui_mobile_reset_style_baseline(void)
{
    g_scale_context = nullptr;
    g_have_base_style = false;
}
