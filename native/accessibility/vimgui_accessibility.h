#ifndef VIMGUI_ACCESSIBILITY_H
#define VIMGUI_ACCESSIBILITY_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

typedef struct vimgui_accessibility vimgui_accessibility;
enum vimgui_accessibility_role {
    VIMGUI_AX_WINDOW, VIMGUI_AX_GROUP, VIMGUI_AX_BUTTON, VIMGUI_AX_CHECKBOX,
    VIMGUI_AX_RADIO, VIMGUI_AX_TEXT_INPUT, VIMGUI_AX_LABEL, VIMGUI_AX_LIST,
    VIMGUI_AX_LIST_ITEM, VIMGUI_AX_PROGRESS, VIMGUI_AX_DIALOG
};
enum vimgui_accessibility_action {
    VIMGUI_AX_FOCUS = 1, VIMGUI_AX_CLICK = 2, VIMGUI_AX_SET_VALUE = 4,
    VIMGUI_AX_SCROLL_INTO_VIEW = 8, VIMGUI_AX_SET_SELECTION = 16,
    VIMGUI_AX_SCROLL_UP = 32, VIMGUI_AX_SCROLL_DOWN = 64
};
enum vimgui_accessibility_flags {
    VIMGUI_AX_DISABLED = 1, VIMGUI_AX_SELECTED = 2, VIMGUI_AX_CHECKED = 4,
    VIMGUI_AX_LIVE = 8, VIMGUI_AX_READ_ONLY = 16, VIMGUI_AX_INDETERMINATE = 32
};
typedef struct vimgui_accessibility_node {
    uint64_t id;
    int role;
    const char *label;
    const char *value;
    double x, y, width, height;
    unsigned actions, flags;
    const uint64_t *children;
    size_t child_count;
    double numeric_value, numeric_min, numeric_max;
    size_t text_anchor, text_focus;
    double scroll_y, scroll_y_max;
    size_t position_in_set, size_of_set;
} vimgui_accessibility_node;
typedef struct vimgui_accessibility_event {
    uint64_t target;
    int action;
    const char *value;
    size_t anchor, focus;
} vimgui_accessibility_event;

// UI/render thread owns staging and commits. Platform callbacks only read the
// last committed snapshot and enqueue owned actions; they never enter V/ImGui.
vimgui_accessibility *vimgui_accessibility_create(void);
// Retain before handing the context to another thread. Each owner frees once.
void vimgui_accessibility_retain(vimgui_accessibility *context);
void vimgui_accessibility_free(vimgui_accessibility *context);
bool vimgui_accessibility_set_node(vimgui_accessibility *context,
                                 const vimgui_accessibility_node *node);
bool vimgui_accessibility_commit(vimgui_accessibility *context, uint64_t root,
                               uint64_t focus);
void vimgui_accessibility_abort(vimgui_accessibility *context);
const char *vimgui_accessibility_error(vimgui_accessibility *context);
size_t vimgui_accessibility_node_count(vimgui_accessibility *context);
uint64_t vimgui_accessibility_focus(vimgui_accessibility *context);
bool vimgui_accessibility_poll(vimgui_accessibility *context,
                             vimgui_accessibility_event *event);
// Native handle: HWND, NSWindow*, UIView*, or Android View. Linux uses NULL.
// Android environment is JNIEnv*. Attach/update/free on the OS UI thread.
bool vimgui_accessibility_attach(vimgui_accessibility *context,
                               void *native_handle, void *environment);
// Detach on the OS UI thread before releasing that thread's reference. A render
// owner may then release the remaining detached context on its own thread.
void vimgui_accessibility_detach(vimgui_accessibility *context);
void vimgui_accessibility_update(vimgui_accessibility *context);
void vimgui_accessibility_window_state(vimgui_accessibility *context,
                                     bool focused, double x, double y,
                                     double width, double height);
// Test/host action ingress follows the same queue and capability validation.
bool vimgui_accessibility_request(vimgui_accessibility *context, uint64_t target,
                                int action, const char *value);
#ifdef __cplusplus
}
#endif
#endif
