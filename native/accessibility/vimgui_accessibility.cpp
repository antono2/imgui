#include "platform.h"
#include <cmath>
#include <utility>
bool accessibility_enqueue(vimgui_accessibility *ctx,Event event) {
    std::lock_guard<std::mutex> lock(ctx->mutex);
    auto it=ctx->nodes.find(event.target);
    if(it==ctx->nodes.end() || (it->second->flags&VIMGUI_AX_DISABLED) || !(it->second->actions&event.action))return false;
    ctx->events.push_back(std::move(event));return true;
}
vimgui_accessibility *vimgui_accessibility_create(void) { return new vimgui_accessibility; }
void vimgui_accessibility_retain(vimgui_accessibility *ctx) {
    if(ctx)ctx->references.fetch_add(1,std::memory_order_relaxed);
}
void vimgui_accessibility_detach(vimgui_accessibility *ctx) {
    if(ctx && ctx->adapter) {accessibility_platform_detach(ctx->adapter);ctx->adapter=nullptr;}
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
    if(!ctx->staged.empty() || ctx->focus != focus || ctx->root != root)++ctx->revision; ctx->root = root; ctx->focus = focus;
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
void vimgui_accessibility_set_visual_focus(vimgui_accessibility *ctx, bool visible,
                                         double x, double y, double width, double height) {
    if (!ctx) return;
    std::lock_guard<std::mutex> lock(ctx->mutex);
    ctx->visual_focus = visible && width > 0 && height > 0;
    ctx->focus_x = x; ctx->focus_y = y; ctx->focus_width = width; ctx->focus_height = height;
}
bool vimgui_accessibility_visual_focus(vimgui_accessibility *ctx, double *x, double *y,
                                     double *width, double *height) {
    if (!ctx || !x || !y || !width || !height) return false;
    std::lock_guard<std::mutex> lock(ctx->mutex);
    if (!ctx->visual_focus) return false;
    *x = ctx->focus_x; *y = ctx->focus_y; *width = ctx->focus_width; *height = ctx->focus_height;
    return true;
}
bool vimgui_accessibility_request(vimgui_accessibility *ctx, uint64_t id, int requested, const char *value) {
    if (!ctx || (requested != VIMGUI_AX_FOCUS && requested != VIMGUI_AX_CLICK &&
        requested != VIMGUI_AX_SCROLL_INTO_VIEW && requested != VIMGUI_AX_SET_VALUE &&
        requested != VIMGUI_AX_SCROLL_UP && requested != VIMGUI_AX_SCROLL_DOWN &&
        requested != VIMGUI_AX_SET_SCROLL_PERCENT)) return false;
    Event event{}; event.target = id; event.action = requested; event.value = value ? value : "";
    return accessibility_enqueue(ctx, std::move(event));
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
bool vimgui_accessibility_attach(vimgui_accessibility *ctx,void *handle,void *env) {
    if(!ctx || ctx->adapter)return false;
    {std::lock_guard<std::mutex> lock(ctx->mutex);if(!ctx->root){ctx->error="Commit an initial tree before attaching accessibility.";return false;}}
    ctx->adapter=accessibility_platform_attach(ctx,handle,env);
    return ctx->adapter!=nullptr;
}
void vimgui_accessibility_update(vimgui_accessibility *ctx) {
    if(ctx && ctx->adapter)accessibility_platform_update(ctx->adapter);
}
void vimgui_accessibility_window_state(vimgui_accessibility *ctx,bool focused,double x,double y,double w,double h) {
    if(!ctx)return;
    {std::lock_guard<std::mutex> lock(ctx->mutex);ctx->window_focused=focused;ctx->window_x=x;ctx->window_y=y;ctx->window_width=w;ctx->window_height=h;}
    if(ctx->adapter)accessibility_platform_window(ctx->adapter);
}
