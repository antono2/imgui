// Checks accessibility tree transactions, snapshots and action handling.
#include "vimgui_accessibility.h"
#include <cassert>
#include <chrono>
#include <cstdio>
#include <string>
#include <vector>

int main() {
    auto *ctx = vimgui_accessibility_create();
    std::vector<uint64_t> rows;
    const auto started = std::chrono::steady_clock::now();
    for (uint64_t id = 2; id < 100002; ++id) {
        rows.push_back(id);
        std::string label = "File " + std::to_string(id - 2);
        vimgui_accessibility_node n{};
        n.id = id; n.role = VIMGUI_AX_LIST_ITEM; n.label = label.c_str();
        n.actions = VIMGUI_AX_CLICK | VIMGUI_AX_FOCUS | VIMGUI_AX_SCROLL_INTO_VIEW;
        n.y = (id - 2) * 40; n.width = 500; n.height = 40;
        assert(vimgui_accessibility_set_node(ctx, &n));
    }
    vimgui_accessibility_node root{};
    root.id = 1; root.role = VIMGUI_AX_WINDOW; root.label = "File review";
    root.children = rows.data(); root.child_count = rows.size();
    assert(vimgui_accessibility_set_node(ctx, &root));
    assert(vimgui_accessibility_commit(ctx, 1, 2));
    assert(vimgui_accessibility_node_count(ctx) == 100001);
    // The final off-screen row remains available to assistive technology.
    assert(vimgui_accessibility_request(ctx, 100001, VIMGUI_AX_SCROLL_INTO_VIEW, nullptr));
    vimgui_accessibility_event event{};
    assert(vimgui_accessibility_poll(ctx, &event));
    assert(event.target == 100001 && event.action == VIMGUI_AX_SCROLL_INTO_VIEW);
    // Invalid updates do not corrupt the published snapshot.
    uint64_t invalid[] = {1}; root.children = invalid; root.child_count = 1;
    assert(vimgui_accessibility_set_node(ctx, &root));
    assert(!vimgui_accessibility_commit(ctx, 1, 2));
    assert(vimgui_accessibility_node_count(ctx) == 100001);
    vimgui_accessibility_abort(ctx);
    // Filtering removes unreachable rows, repairs focus explicitly, and rejects
    // stale queued actions rather than invoking an action on a recycled index.
    assert(vimgui_accessibility_request(ctx, 100001, VIMGUI_AX_CLICK, nullptr));
    uint64_t retained[] = {2}; root.children = retained; root.child_count = 1;
    assert(vimgui_accessibility_set_node(ctx, &root));
    assert(vimgui_accessibility_commit(ctx, 1, 2));
    assert(vimgui_accessibility_node_count(ctx) == 2);
    assert(!vimgui_accessibility_poll(ctx, &event));
    assert(!vimgui_accessibility_request(ctx, 100001, VIMGUI_AX_CLICK, nullptr));
    assert(!vimgui_accessibility_commit(ctx, 1, 100001));
    assert(vimgui_accessibility_focus(ctx) == 2);
    double x, y, width, height;
    assert(!vimgui_accessibility_visual_focus(ctx, &x, &y, &width, &height));
    vimgui_accessibility_set_visual_focus(ctx, true, 10, 20, 30, 40);
    assert(vimgui_accessibility_visual_focus(ctx, &x, &y, &width, &height));
    assert(x == 10 && y == 20 && width == 30 && height == 40);
    assert(vimgui_accessibility_focus(ctx) == 2); // Reading focus must not enter/edit a text field.
    vimgui_accessibility_set_visual_focus(ctx, false, 0, 0, 0, 0);
    assert(!vimgui_accessibility_visual_focus(ctx, &x, &y, &width, &height));
    vimgui_accessibility_retain(ctx);
    vimgui_accessibility_free(ctx);
    assert(vimgui_accessibility_node_count(ctx) == 2);
    vimgui_accessibility_detach(ctx);
    vimgui_accessibility_free(ctx);
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - started).count();
    std::printf("100,000 retained rows, off-screen action, invalid-tree rollback, and stale-action filtering passed (%lld ms).\n", static_cast<long long>(ms));
}
