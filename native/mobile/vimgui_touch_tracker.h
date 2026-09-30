#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

// Dear ImGui exposes one mouse pointer. Keep all native touch IDs so a
// secondary finger cannot move the selected pointer or leave it stuck down.
namespace vimgui {

struct TouchSignal {
    enum Kind { Position, Button } kind;
    float x;
    float y;
    bool down;
    bool position_valid;
};

struct TouchSignals {
    TouchSignal items[4];
    size_t count = 0;

    void position(float x, float y) { items[count++] = {TouchSignal::Position, x, y, false, true}; }
    void clear_position() { items[count++] = {TouchSignal::Position, 0.0f, 0.0f, false, false}; }
    void button(bool down) { items[count++] = {TouchSignal::Button, 0.0f, 0.0f, down, false}; }
};

class TouchTracker {
public:
    TouchSignals down(uint64_t id, float x, float y)
    {
        for (TouchPoint& point : points_)
            if (point.id == id)
                return move(id, x, y);
        points_.push_back({id, x, y});
        TouchSignals signals;
        if (points_.size() == 1)
        {
            signals.position(x, y);
            signals.button(true);
        }
        return signals;
    }

    TouchSignals move(uint64_t id, float x, float y)
    {
        TouchSignals signals;
        for (TouchPoint& point : points_)
        {
            if (point.id != id)
                continue;
            point.x = x;
            point.y = y;
            if (&point == &points_.front())
                signals.position(x, y);
            break;
        }
        return signals;
    }

    TouchSignals up(uint64_t id)
    {
        TouchSignals signals;
        for (size_t index = 0; index < points_.size(); ++index)
        {
            if (points_[index].id != id)
                continue;
            const bool was_primary = index == 0;
            points_.erase(points_.begin() + index);
            if (was_primary)
            {
                signals.button(false);
                signals.clear_position();
                if (!points_.empty())
                {
                    signals.position(points_.front().x, points_.front().y);
                    signals.button(true);
                }
            }
            break;
        }
        return signals;
    }

    TouchSignals reset()
    {
        TouchSignals signals;
        if (!points_.empty())
        {
            signals.button(false);
            signals.clear_position();
        }
        points_.clear();
        return signals;
    }

    size_t active_count() const { return points_.size(); }
    uint64_t primary_id() const { return points_.empty() ? 0 : points_.front().id; }

private:
    struct TouchPoint { uint64_t id; float x; float y; };
    std::vector<TouchPoint> points_;
};

} // namespace vimgui
