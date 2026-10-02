#include "vimgui_accessibility.h"
#include "accesskit.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace {
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
accesskit_role role(int r) {
    static const accesskit_role roles[] = { ACCESSKIT_ROLE_WINDOW, ACCESSKIT_ROLE_GENERIC_CONTAINER,
        ACCESSKIT_ROLE_BUTTON, ACCESSKIT_ROLE_CHECK_BOX, ACCESSKIT_ROLE_RADIO_BUTTON,
        ACCESSKIT_ROLE_TEXT_INPUT, ACCESSKIT_ROLE_LABEL, ACCESSKIT_ROLE_LIST_BOX,
        ACCESSKIT_ROLE_LIST_BOX_OPTION, ACCESSKIT_ROLE_PROGRESS_INDICATOR, ACCESSKIT_ROLE_DIALOG };
    return roles[r];
}
accesskit_node *convert(const Node &n) {
    auto *node = accesskit_node_new(role(n.role));
    accesskit_node_set_label(node, n.label.c_str());
    if (n.role == VIMGUI_AX_PROGRESS && !(n.flags & VIMGUI_AX_INDETERMINATE)) {
        // A textual value suppresses Android's numeric RangeInfo. Keep phase
        // detail as a description while publishing the actual numeric range.
        if (!n.value.empty()) accesskit_node_set_description(node, n.value.c_str());
    } else if (!n.value.empty() || n.role == VIMGUI_AX_TEXT_INPUT) {
        accesskit_node_set_value(node, n.value.c_str());
    }
    accesskit_node_set_bounds(node, {n.x, n.y, n.x + n.width, n.y + n.height});
    accesskit_node_set_children(node, n.children.size(), n.children.data());
    if (n.role == VIMGUI_AX_TEXT_INPUT) {
        const uint64_t run = n.id | text_run_bit;
        accesskit_node_set_children(node, 1, &run);
        accesskit_node_set_text_selection(node, {{run, n.text_anchor}, {run, n.text_focus}});
    } else if (n.role == VIMGUI_AX_LIST) {
        const uint64_t content=n.id | text_run_bit;
        accesskit_node_set_children(node,1,&content);
        accesskit_node_set_clips_children(node);
        accesskit_node_set_scroll_y(node,n.scroll_y);
        accesskit_node_set_scroll_y_min(node,0);
        accesskit_node_set_scroll_y_max(node,n.scroll_y_max);
    }
    if (n.role!=VIMGUI_AX_LIST && n.scroll_y_max>0) {
        accesskit_node_set_scroll_y(node,n.scroll_y);
        accesskit_node_set_scroll_y_min(node,0);
        accesskit_node_set_scroll_y_max(node,n.scroll_y_max);
    }
    if (n.actions & VIMGUI_AX_FOCUS) accesskit_node_add_action(node, ACCESSKIT_ACTION_FOCUS);
    if (n.size_of_set) {
        accesskit_node_set_size_of_set(node,n.size_of_set);
        accesskit_node_set_position_in_set(node,n.position_in_set);
    }
    if (n.actions & VIMGUI_AX_CLICK) accesskit_node_add_action(node, ACCESSKIT_ACTION_CLICK);
    if (n.actions & VIMGUI_AX_SET_VALUE) accesskit_node_add_action(node, ACCESSKIT_ACTION_SET_VALUE);
    if (n.actions & VIMGUI_AX_SET_SELECTION) accesskit_node_add_action(node, ACCESSKIT_ACTION_SET_TEXT_SELECTION);
    if (n.actions & VIMGUI_AX_SCROLL_INTO_VIEW) accesskit_node_add_action(node, ACCESSKIT_ACTION_SCROLL_INTO_VIEW);
    if (n.actions & VIMGUI_AX_SCROLL_UP) accesskit_node_add_action(node, ACCESSKIT_ACTION_SCROLL_UP);
    if (n.actions & VIMGUI_AX_SCROLL_DOWN) accesskit_node_add_action(node, ACCESSKIT_ACTION_SCROLL_DOWN);
    if (n.flags & VIMGUI_AX_DISABLED) accesskit_node_set_disabled(node);
    if (n.flags & VIMGUI_AX_READ_ONLY) accesskit_node_set_read_only(node);
    if (n.role == VIMGUI_AX_LIST_ITEM) accesskit_node_set_selected(node, (n.flags & VIMGUI_AX_SELECTED) != 0);
    if (n.role == VIMGUI_AX_CHECKBOX || n.role == VIMGUI_AX_RADIO)
        accesskit_node_set_toggled(node, (n.flags & VIMGUI_AX_CHECKED) ? ACCESSKIT_TOGGLED_TRUE : ACCESSKIT_TOGGLED_FALSE);
    if (n.flags & VIMGUI_AX_LIVE) accesskit_node_set_live(node, ACCESSKIT_LIVE_POLITE);
    if (n.role == VIMGUI_AX_PROGRESS && !(n.flags & VIMGUI_AX_INDETERMINATE)) {
        accesskit_node_set_numeric_value(node, n.numeric_value);
        accesskit_node_set_min_numeric_value(node, n.numeric_min);
        accesskit_node_set_max_numeric_value(node, n.numeric_max);
    }
    return node;
}
}

struct vimgui_accessibility {
    std::atomic<unsigned> references{1};
    std::mutex mutex;
    Nodes nodes, staged;
    std::unordered_set<uint64_t> dirty;
    std::deque<Event> events;
    Event current{};
    uint64_t root = 0, focus = 0;
    bool structure_changed = false, pending = false;
    std::string error;
#if defined(__ANDROID__)
    accesskit_android_injecting_adapter *adapter = nullptr;
#elif defined(ACCESSKIT_IOS)
    accesskit_ios_subclassing_adapter *adapter = nullptr;
#elif defined(ACCESSKIT_MACOS)
    accesskit_macos_subclassing_adapter *adapter = nullptr;
#elif defined(_WIN32)
    accesskit_windows_subclassing_adapter *adapter = nullptr;
#else
    accesskit_unix_adapter *adapter = nullptr;
#endif
};

namespace {
void push_node(accesskit_tree_update *update, const Node &n) {
    accesskit_tree_update_push_node(update, n.id, convert(n));
    if (n.role==VIMGUI_AX_LIST) {
        auto *content=accesskit_node_new(ACCESSKIT_ROLE_GENERIC_CONTAINER);
        accesskit_node_set_children(content,n.children.size(),n.children.data());
        accesskit_node_set_transform(content,accesskit_affine_translate({0,-n.scroll_y}));
        accesskit_tree_update_push_node(update,n.id | text_run_bit,content);
        return;
    }
    if (n.role != VIMGUI_AX_TEXT_INPUT) return;
    auto *run = accesskit_node_new(ACCESSKIT_ROLE_TEXT_RUN);
    accesskit_node_set_value(run, n.value.c_str());
    accesskit_node_set_bounds(run, {n.x, n.y, n.x+n.width, n.y+n.height});
    std::vector<uint8_t> lengths;
    for (size_t i=0; i<n.value.size();) {
        size_t end=i+1;
        while (end<n.value.size() && (static_cast<unsigned char>(n.value[end]) & 0xc0)==0x80) ++end;
        lengths.push_back(static_cast<uint8_t>(end-i)); i=end;
    }
    accesskit_node_set_character_lengths(run, lengths.size(), lengths.data());
    accesskit_tree_update_push_node(update, n.id | text_run_bit, run);
}
accesskit_tree_update *snapshot(vimgui_accessibility *ctx, bool complete) {
    std::lock_guard<std::mutex> lock(ctx->mutex);
    auto *update = accesskit_tree_update_with_capacity_and_focus(complete ? ctx->nodes.size() : ctx->dirty.size(), ctx->focus);
    if (complete) {
        auto *tree = accesskit_tree_info_new(ctx->root);
        accesskit_tree_info_set_toolkit_name(tree, "V ImGui application UI");
        accesskit_tree_update_set_tree_info(update, tree);
        for (const auto &entry : ctx->nodes) push_node(update, *entry.second);
    } else {
        for (auto id : ctx->dirty) {
            auto it = ctx->nodes.find(id);
            if (it != ctx->nodes.end()) push_node(update, *it->second);
        }
    }
    ctx->dirty.clear();
    ctx->pending = false;
    return update;
}
accesskit_tree_update *activate(void *data) { return snapshot(static_cast<vimgui_accessibility *>(data), true); }
accesskit_tree_update *update_tree(void *data) { return snapshot(static_cast<vimgui_accessibility *>(data), false); }
void deactivate(void *) {}
bool enqueue(vimgui_accessibility *ctx, Event event) {
    std::lock_guard<std::mutex> lock(ctx->mutex);
    auto it = ctx->nodes.find(event.target);
    if (it == ctx->nodes.end() || (it->second->flags & VIMGUI_AX_DISABLED) ||
        !(it->second->actions & event.action)) return false;
    ctx->events.push_back(std::move(event));
    return true;
}
void action(accesskit_action_request *request, void *data) {
    auto *ctx = static_cast<vimgui_accessibility *>(data);
    Event event{};
    event.target = request->target_node;
    switch (request->action) {
    case ACCESSKIT_ACTION_FOCUS: event.action = VIMGUI_AX_FOCUS; break;
    case ACCESSKIT_ACTION_CLICK: event.action = VIMGUI_AX_CLICK; break;
    case ACCESSKIT_ACTION_SCROLL_INTO_VIEW: event.action = VIMGUI_AX_SCROLL_INTO_VIEW; break;
    case ACCESSKIT_ACTION_SCROLL_UP: event.action = VIMGUI_AX_SCROLL_UP; break;
    case ACCESSKIT_ACTION_SCROLL_DOWN: event.action = VIMGUI_AX_SCROLL_DOWN; break;
    case ACCESSKIT_ACTION_SET_VALUE:
        if (request->data.has_value && request->data.value.tag == ACCESSKIT_ACTION_DATA_VALUE) {
            event.action = VIMGUI_AX_SET_VALUE;
            event.value = request->data.value.value;
        }
        break;
    case ACCESSKIT_ACTION_SET_TEXT_SELECTION:
        if (request->data.has_value && request->data.value.tag == ACCESSKIT_ACTION_DATA_SET_TEXT_SELECTION) {
            const auto selection = request->data.value.set_text_selection;
            if (selection.anchor.node == (event.target | text_run_bit) && selection.focus.node == (event.target | text_run_bit)) {
                event.action = VIMGUI_AX_SET_SELECTION;
                event.anchor = selection.anchor.character_index; event.focus = selection.focus.character_index;
            }
        }
        break;
    default: break;
    }
    if (event.action) enqueue(ctx, std::move(event));
    accesskit_action_request_free(request);
}
}

vimgui_accessibility *vimgui_accessibility_create(void) { return new vimgui_accessibility; }
void vimgui_accessibility_retain(vimgui_accessibility *ctx) {
    if (ctx) ctx->references.fetch_add(1,std::memory_order_relaxed);
}
void vimgui_accessibility_detach(vimgui_accessibility *ctx) {
    if (!ctx) return;
    if (ctx->adapter) {
#if defined(__ANDROID__)
        accesskit_android_injecting_adapter_free(ctx->adapter);
#elif defined(ACCESSKIT_IOS)
        accesskit_ios_subclassing_adapter_free(ctx->adapter);
#elif defined(ACCESSKIT_MACOS)
        accesskit_macos_subclassing_adapter_free(ctx->adapter);
#elif defined(_WIN32)
        accesskit_windows_subclassing_adapter_free(ctx->adapter);
#else
        accesskit_unix_adapter_free(ctx->adapter);
#endif
        ctx->adapter = nullptr;
    }
}
void vimgui_accessibility_free(vimgui_accessibility *ctx) {
    if (!ctx || ctx->references.fetch_sub(1,std::memory_order_acq_rel)!=1) return;
    vimgui_accessibility_detach(ctx);
    delete ctx;
}
bool vimgui_accessibility_set_node(vimgui_accessibility *ctx, const vimgui_accessibility_node *n) {
    if (!ctx || !n) return false;
    if (!n->id || (n->id & text_run_bit) || n->role < VIMGUI_AX_WINDOW || n->role > VIMGUI_AX_DIALOG ||
        (n->child_count && !n->children) || !std::isfinite(n->x) || !std::isfinite(n->y) ||
        !std::isfinite(n->width) || !std::isfinite(n->height) || n->width < 0 || n->height < 0 ||
        !std::isfinite(n->numeric_value) || !std::isfinite(n->numeric_min) || !std::isfinite(n->numeric_max) ||
        !std::isfinite(n->scroll_y) || !std::isfinite(n->scroll_y_max) || n->scroll_y_max<0) {
        ctx->error = "Invalid accessibility node."; return false;
    }
    auto value = std::make_shared<Node>(*n);
    std::lock_guard<std::mutex> lock(ctx->mutex);
    auto staged = ctx->staged.find(n->id);
    auto previous = ctx->nodes.find(n->id);
    if (staged != ctx->staged.end() && *staged->second == *value) return true;
    if (staged == ctx->staged.end() && previous != ctx->nodes.end() && *previous->second == *value) return true;
    if (previous == ctx->nodes.end() || previous->second->children != value->children) ctx->structure_changed = true;
    ctx->staged[n->id] = std::move(value);
    return true;
}
bool vimgui_accessibility_commit(vimgui_accessibility *ctx, uint64_t root, uint64_t focus) {
    if (!ctx || !root || !focus) return false;
    std::lock_guard<std::mutex> lock(ctx->mutex);
    if (ctx->root && root != ctx->root) { ctx->error = "The root identity must remain stable for the adapter lifetime."; return false; }
    if (ctx->structure_changed || ctx->root == 0) {
        Nodes candidate = ctx->nodes;
        for (const auto &entry : ctx->staged) candidate[entry.first] = entry.second;
        std::unordered_set<uint64_t> reachable;
        std::vector<uint64_t> stack{root};
        while (!stack.empty()) {
            auto id = stack.back(); stack.pop_back();
            auto it = candidate.find(id);
            if (it == candidate.end() || !reachable.insert(id).second) {
                ctx->error = "Accessibility tree has a missing child, cycle, or multiple parents."; return false;
            }
            for (auto child : it->second->children) stack.push_back(child);
        }
        if (!reachable.count(focus)) { ctx->error = "Accessibility focus must belong to the published tree."; return false; }
        for (auto it = candidate.begin(); it != candidate.end();) {
            if (!reachable.count(it->first)) it = candidate.erase(it); else ++it;
        }
        ctx->nodes = std::move(candidate);
    } else {
        if (!ctx->nodes.count(focus)) { ctx->error = "Unknown accessibility focus."; return false; }
        for (const auto &entry : ctx->staged) ctx->nodes[entry.first] = entry.second;
    }
    for (const auto &entry : ctx->staged) if (ctx->nodes.count(entry.first)) ctx->dirty.insert(entry.first);
    ctx->pending = ctx->pending || !ctx->staged.empty() || ctx->focus != focus;
    ctx->root = root; ctx->focus = focus;
    ctx->staged.clear(); ctx->structure_changed = false; ctx->error.clear();
    return true;
}
void vimgui_accessibility_abort(vimgui_accessibility *ctx) {
    if (!ctx) return;
    std::lock_guard<std::mutex> lock(ctx->mutex);
    ctx->staged.clear(); ctx->structure_changed = false; ctx->error.clear();
}
const char *vimgui_accessibility_error(vimgui_accessibility *ctx) { return ctx ? ctx->error.c_str() : "No accessibility context."; }
size_t vimgui_accessibility_node_count(vimgui_accessibility *ctx) {
    if (!ctx) return 0;
    std::lock_guard<std::mutex> lock(ctx->mutex); return ctx->nodes.size();
}
uint64_t vimgui_accessibility_focus(vimgui_accessibility *ctx) {
    if (!ctx) return 0;
    std::lock_guard<std::mutex> lock(ctx->mutex); return ctx->focus;
}
bool vimgui_accessibility_request(vimgui_accessibility *ctx, uint64_t id, int requested, const char *value) {
    if (!ctx || (requested != VIMGUI_AX_FOCUS && requested != VIMGUI_AX_CLICK &&
        requested != VIMGUI_AX_SCROLL_INTO_VIEW && requested != VIMGUI_AX_SET_VALUE &&
        requested != VIMGUI_AX_SCROLL_UP && requested != VIMGUI_AX_SCROLL_DOWN)) return false;
    Event event{}; event.target = id; event.action = requested; event.value = value ? value : "";
    return enqueue(ctx, std::move(event));
}
bool vimgui_accessibility_poll(vimgui_accessibility *ctx, vimgui_accessibility_event *out) {
    if (!ctx || !out) return false;
    std::lock_guard<std::mutex> lock(ctx->mutex);
    while (!ctx->events.empty()) {
        ctx->current = std::move(ctx->events.front()); ctx->events.pop_front();
        auto it = ctx->nodes.find(ctx->current.target);
        if (it == ctx->nodes.end() || (it->second->flags & VIMGUI_AX_DISABLED) || !(it->second->actions & ctx->current.action)) continue;
        *out = {ctx->current.target, ctx->current.action, ctx->current.value.c_str(), ctx->current.anchor, ctx->current.focus};
        return true;
    }
    return false;
}
bool vimgui_accessibility_attach(vimgui_accessibility *ctx, void *handle, void *env) {
    if (!ctx || ctx->adapter) return false;
    {
        std::lock_guard<std::mutex> lock(ctx->mutex);
        if (!ctx->root) { ctx->error = "Commit an initial tree before attaching accessibility."; return false; }
    }
#if defined(__ANDROID__)
    if (!handle || !env) { ctx->error = "Android accessibility requires a View and JNIEnv on the UI thread."; return false; }
    ctx->adapter = accesskit_android_injecting_adapter_new(static_cast<JNIEnv *>(env), static_cast<jobject>(handle), activate, ctx, action, ctx);
#elif defined(ACCESSKIT_IOS)
    if (!handle) return false;
    ctx->adapter = accesskit_ios_subclassing_adapter_new(handle, activate, ctx, action, ctx, deactivate, ctx);
#elif defined(ACCESSKIT_MACOS)
    if (!handle) return false;
    ctx->adapter = accesskit_macos_subclassing_adapter_for_window(handle, activate, ctx, action, ctx);
#elif defined(_WIN32)
    if (!handle) return false;
    ctx->adapter = accesskit_windows_subclassing_adapter_new(static_cast<HWND>(handle), activate, ctx, action, ctx);
#else
    (void)handle; (void)env;
    ctx->adapter = accesskit_unix_adapter_new(activate, ctx, action, ctx, deactivate, ctx);
#endif
    return ctx->adapter != nullptr;
}
void vimgui_accessibility_update(vimgui_accessibility *ctx) {
    if (!ctx || !ctx->adapter) return;
    { std::lock_guard<std::mutex> lock(ctx->mutex); if (!ctx->pending) return; }
#if defined(__ANDROID__)
    accesskit_android_injecting_adapter_update_if_active(ctx->adapter, update_tree, ctx);
#elif defined(ACCESSKIT_IOS)
    auto *events = accesskit_ios_subclassing_adapter_update_if_active(ctx->adapter, update_tree, ctx);
    if (events) accesskit_ios_queued_events_raise(events);
#elif defined(ACCESSKIT_MACOS)
    auto *events = accesskit_macos_subclassing_adapter_update_if_active(ctx->adapter, update_tree, ctx);
    if (events) accesskit_macos_queued_events_raise(events);
#elif defined(_WIN32)
    auto *events = accesskit_windows_subclassing_adapter_update_if_active(ctx->adapter, update_tree, ctx);
    if (events) accesskit_windows_queued_events_raise(events);
#else
    accesskit_unix_adapter_update_if_active(ctx->adapter, update_tree, ctx);
#endif
}
void vimgui_accessibility_window_state(vimgui_accessibility *ctx, bool focused, double x, double y, double w, double h) {
    if (!ctx || !ctx->adapter) return;
#if defined(ACCESSKIT_MACOS)
    auto *events = accesskit_macos_subclassing_adapter_update_view_focus_state(ctx->adapter, focused);
    if (events) accesskit_macos_queued_events_raise(events);
#elif !defined(__ANDROID__) && !defined(__APPLE__) && !defined(_WIN32)
    accesskit_unix_adapter_set_root_window_bounds(ctx->adapter, {x, y, x+w, y+h}, {x, y, x+w, y+h});
    accesskit_unix_adapter_update_window_focus_state(ctx->adapter, focused);
#else
    (void)focused; (void)x; (void)y; (void)w; (void)h;
#endif
}
