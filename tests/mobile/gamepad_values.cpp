#include "../../native/mobile/vimgui_gamepad_values.h"

int main()
{
    if (vimgui::gamepad_direction(0.19f, true) != 0.0f) return 1;
    if (vimgui::gamepad_direction(-0.19f, false) != 0.0f) return 2;
    if (vimgui::gamepad_direction(1.0f, true) != 1.0f) return 3;
    if (vimgui::gamepad_direction(-1.0f, false) != 1.0f) return 4;
    if (vimgui::gamepad_direction(-1.0f, true) != 0.0f) return 5;
    if (vimgui::gamepad_trigger(-1.0f) != 0.0f) return 6;
    if (vimgui::gamepad_trigger(2.0f) != 1.0f) return 7;
    if (!vimgui::gamepad_dpad(true, 0.0f, true)) return 8;
    if (!vimgui::gamepad_dpad(false, -1.0f, false)) return 9;
    if (vimgui::gamepad_dpad(false, -1.0f, true)) return 10;
}
