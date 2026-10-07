// Declares the C application and widget API used by appui and native example hosts.
#ifndef VIMGUI_APP_H
#define VIMGUI_APP_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "vimgui_accessibility.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef void (*vimgui_app_frame)(void *userdata);
/* data is ImGuiInputTextCallbackData*. Called on the rendering thread for the
 * active input field; use the platform's selection-aware IME bridge here. */
typedef void (*vimgui_app_text_edit)(void *data, void *userdata);
// The desktop host owns renderer lifecycle; mobile hosts use frame_begin/end
// around the same application callback in their existing Vulkan/Metal loops.
int vimgui_app_run(const char *title, int width, int height,
                  vimgui_app_frame frame, void *userdata, int smoke_frames);
bool vimgui_app_initialize(const char *title);
void vimgui_app_shutdown(void);
void vimgui_app_frame_begin(void);
bool vimgui_app_frame_end(void);
vimgui_accessibility *vimgui_app_accessibility(void);
void vimgui_app_theme(bool dark, bool high_contrast, float text_scale, bool touch);
void vimgui_app_safe_area(float left, float top, float right, float bottom);
void vimgui_app_set_text_edit_handler(vimgui_app_text_edit handler, void *userdata);
float vimgui_app_width(void);
float vimgui_app_height(void);
/* Supply a contextual screen-reader name for the next button, checkbox, or radio. */
void vimgui_app_next_control_name(const char *name);
bool vimgui_app_button(uint64_t id, const char *label);
bool vimgui_app_checkbox(uint64_t id, const char *label, bool *value);
bool vimgui_app_radio(uint64_t id, const char *label, bool selected);
bool vimgui_app_input(uint64_t id, const char *label, char *buffer, size_t capacity);
void vimgui_app_text(uint64_t id, const char *text);
void vimgui_app_status(uint64_t id, const char *text);
// Fraction is clamped to 0..1. Negative or non-finite values mean unknown progress.
void vimgui_app_progress(uint64_t id, const char *label, float fraction, const char *detail);
void vimgui_app_same_line(void);
// Desktop host only. Borrowed result/error lasts until the next call; null
// result without an error means cancelled. Call on the desktop UI thread.
const char *vimgui_app_pick_folder(const char *initial, const char **error);
// Continue a row only when the next control fits within the content width.
void vimgui_app_same_line_width(float width);
float vimgui_app_control_width(const char *label, bool choice);
// Responsive two-column row, stacking below the required widths. A positive
// trailing width keeps an action compact; zero gives two equal field columns.
void vimgui_app_begin_columns(uint64_t id, float minimum, float trailing);
void vimgui_app_next_column(bool align_input);
void vimgui_app_end_columns(void);
void vimgui_app_separator(void);
void vimgui_app_set_width(float width);
void vimgui_app_begin_panel(uint64_t id, const char *label, float width, float height);
void vimgui_app_end_panel(void);
void vimgui_app_list_reset(uint64_t id);
bool vimgui_app_list_add(uint64_t list, uint64_t id, const char *label);
// Returns clicked/activated stable row ID, zero if none; selected is a stable ID.
uint64_t vimgui_app_list(uint64_t id, const char *label, uint64_t selected, float height);
void vimgui_app_focus(uint64_t id);
// Scroll the target into its parent viewport when it is next rendered.
// Call on screen navigation; does not activate or change keyboard focus.
void vimgui_app_reveal(uint64_t id);
// Browser Back / Alt+Left navigation request for application view history.
bool vimgui_app_back_requested(void);
// Cached scroll positions are readable between frames and survive list rebuilds.
float vimgui_app_scroll(uint64_t id);
void vimgui_app_restore_scroll(uint64_t id, float position);
const char *vimgui_app_error(void);
#ifdef __cplusplus
}
#endif
#endif
