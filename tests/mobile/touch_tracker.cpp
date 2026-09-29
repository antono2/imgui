#include "../../native/mobile/vimgui_touch_tracker.h"

#include <cassert>

int main()
{
    vimgui::TouchTracker touches;
    vimgui::TouchSignals signals = touches.down(11, 10.0f, 20.0f);
    assert(signals.count == 2);
    assert(signals.items[0].kind == vimgui::TouchSignal::Position);
    assert(signals.items[0].x == 10.0f);
    assert(signals.items[1].kind == vimgui::TouchSignal::Button && signals.items[1].down);

    assert(touches.down(22, 30.0f, 40.0f).count == 0);
    assert(touches.move(22, 35.0f, 45.0f).count == 0);
    signals = touches.move(11, 12.0f, 24.0f);
    assert(signals.count == 1 && signals.items[0].x == 12.0f);

    signals = touches.up(11);
    assert(signals.count == 4);
    assert(signals.items[0].kind == vimgui::TouchSignal::Button && !signals.items[0].down);
    assert(signals.items[1].kind == vimgui::TouchSignal::Position && !signals.items[1].position_valid);
    assert(signals.items[2].kind == vimgui::TouchSignal::Position && signals.items[2].x == 35.0f);
    assert(signals.items[3].kind == vimgui::TouchSignal::Button && signals.items[3].down);
    assert(touches.primary_id() == 22);

    assert(touches.up(99).count == 0);
    signals = touches.up(22);
    assert(signals.count == 2);
    assert(touches.active_count() == 0);
    assert(touches.reset().count == 0);

    touches.down(33, 1.0f, 2.0f);
    touches.down(44, 3.0f, 4.0f);
    signals = touches.reset();
    assert(signals.count == 2);
    assert(touches.active_count() == 0);
}
