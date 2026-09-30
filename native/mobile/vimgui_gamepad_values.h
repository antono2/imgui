#pragma once

#include <algorithm>

namespace vimgui {

// Android stick axes are -1..1. Apply a dead zone before feeding ImGui's
// directional, 0..1 analog keys.
inline float gamepad_direction(float axis, bool positive, float dead_zone = 0.20f)
{
    const float value = positive ? axis : -axis;
    return std::max(0.0f, std::min(1.0f, (value - dead_zone) / (1.0f - dead_zone)));
}

inline float gamepad_trigger(float axis)
{
    return std::max(0.0f, std::min(1.0f, axis));
}

inline bool gamepad_dpad(bool key_down, float hat_axis, bool positive)
{
    return key_down || (positive ? hat_axis > 0.5f : hat_axis < -0.5f);
}

} // namespace vimgui
