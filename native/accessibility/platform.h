// Defines the internal snapshot, node and event boundary shared by native accessibility adapters.
#ifndef VIMGUI_ACCESSIBILITY_PLATFORM_H
#define VIMGUI_ACCESSIBILITY_PLATFORM_H
#include "vimgui_accessibility.h"
#include <atomic>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>
constexpr uint64_t text_run_bit = uint64_t(1) << 63;
struct Node {
    uint64_t id;
    int role;
    std::string label, value;
    double x, y, width, height;
    unsigned actions, flags;
    std::vector<uint64_t> children;
    double numeric_value, numeric_min, numeric_max;
    size_t text_anchor, text_focus;
    double scroll_y, scroll_y_max;
    size_t position_in_set, size_of_set;
    explicit Node(const vimgui_accessibility_node &n) : id(n.id), role(n.role),
        label(n.label ? n.label : ""), value(n.value ? n.value : ""),
        x(n.x), y(n.y), width(n.width), height(n.height), actions(n.actions),
        flags(n.flags), numeric_value(n.numeric_value), numeric_min(n.numeric_min),
        numeric_max(n.numeric_max), text_anchor(n.text_anchor), text_focus(n.text_focus),
        scroll_y(n.scroll_y), scroll_y_max(n.scroll_y_max), position_in_set(n.position_in_set), size_of_set(n.size_of_set) {
        if (n.child_count) children.assign(n.children, n.children + n.child_count);
    }
    bool operator==(const Node &n) const {
        return id == n.id && role == n.role && label == n.label && value == n.value &&
            x == n.x && y == n.y && width == n.width && height == n.height &&
            actions == n.actions && flags == n.flags && children == n.children &&
            scroll_y == n.scroll_y && scroll_y_max == n.scroll_y_max &&
            position_in_set == n.position_in_set && size_of_set == n.size_of_set &&
            text_anchor == n.text_anchor && text_focus == n.text_focus && numeric_value == n.numeric_value && numeric_min == n.numeric_min && numeric_max == n.numeric_max;
    }
};
struct Event { uint64_t target; int action; std::string value; size_t anchor = 0, focus = 0; };
using Nodes = std::unordered_map<uint64_t, std::shared_ptr<const Node>>;
struct vimgui_accessibility {
    std::atomic<unsigned> references{1};
    std::mutex mutex;
    Nodes nodes, staged;
    std::deque<Event> events;
    Event current{};
    uint64_t root = 0, focus = 0;
    bool visual_focus = false;
    double focus_x = 0, focus_y = 0, focus_width = 0, focus_height = 0;
    bool structure_changed = false;
    std::string error;
    void *adapter = nullptr;
    uint64_t revision = 0;
    bool window_focused = false;
    double window_x = 0, window_y = 0, window_width = 0, window_height = 0;
};
struct AccessibilitySnapshot {
    Nodes nodes;
    uint64_t root = 0, focus = 0, revision = 0;
    bool focused = false;
    double x = 0, y = 0, width = 0, height = 0;
};
inline AccessibilitySnapshot accessibility_snapshot(vimgui_accessibility *ctx) {
    std::lock_guard<std::mutex> lock(ctx->mutex);
    return {ctx->nodes,ctx->root,ctx->focus,ctx->revision,ctx->window_focused,
            ctx->window_x,ctx->window_y,ctx->window_width,ctx->window_height};
}
inline std::shared_ptr<const Node> accessibility_node(vimgui_accessibility *ctx,uint64_t id) {
    std::lock_guard<std::mutex> lock(ctx->mutex);
    auto found=ctx->nodes.find(id);return found==ctx->nodes.end()?nullptr:found->second;
}
inline uint64_t accessibility_parent(const AccessibilitySnapshot &tree,uint64_t id) {
    for(const auto &entry:tree.nodes)for(auto child:entry.second->children)if(child==id)return entry.first;
    return 0;
}
inline Node accessibility_bounds(const AccessibilitySnapshot &tree,const Node &source) {
    Node result=source;
    for(auto parent=accessibility_parent(tree,source.id);parent;parent=accessibility_parent(tree,parent)) {
        const auto &ancestor=*tree.nodes.at(parent);
        if(ancestor.role==VIMGUI_AX_LIST)result.y-=ancestor.scroll_y;
    }
    return result;
}
bool accessibility_enqueue(vimgui_accessibility *,Event);
void *accessibility_platform_attach(vimgui_accessibility *,void *,void *);
void accessibility_platform_detach(void *);
void accessibility_platform_update(void *);
void accessibility_platform_window(void *);
#endif
