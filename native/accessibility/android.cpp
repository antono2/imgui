#include "platform.h"
// Android's Java AccessibilityNodeProvider owns the native View delegate.
// JNI reads immutable committed nodes and enqueues actions on the retained core.
void *accessibility_platform_attach(vimgui_accessibility *ctx,void *view,void *env) {
    return view && env ? ctx : nullptr;
}
void accessibility_platform_detach(void *) {}
void accessibility_platform_update(void *) {}
void accessibility_platform_window(void *) {}
