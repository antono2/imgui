#include "vimgui_app.h"
#include "imgui.h"
#include "imgui_internal.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace {
struct Action { uint64_t id; int action; std::string value; size_t anchor = 0, focus = 0; };
struct Group { uint64_t id; std::string label; std::vector<uint64_t> children; ImVec2 origin; };
struct Row { uint64_t id; std::string label; };
struct List {
    std::vector<Row> rows;
    std::unordered_map<uint64_t, int> indices;
    bool touch_tracking = false, touch_dragging = false;
    int last_frame = -2;
    float scroll_y = 0, scroll_max = 0;
};
struct State {
    vimgui_accessibility *ax = nullptr;
    std::string title, error, next_control_name;
    std::vector<Group> groups;
    std::vector<Action> actions;
    std::unordered_map<uint64_t, List> lists;
    std::unordered_set<uint64_t> frame_ids;
    std::unordered_map<uint64_t, std::pair<size_t, size_t>> pending_selections;
    vimgui_app_text_edit text_edit = nullptr;
    void *text_edit_userdata = nullptr;
    uint64_t focus = 1, request_focus = 0, reveal = 0;
    float row_height = 32, safe_left = 0, safe_top = 0, safe_right = 0, safe_bottom = 0;
    int frame = 0;
    bool touch = false, background_drag = false;
    ImGuiID touch_window = 0, touch_active = 0;
    ImVec2 touch_start;
    float input_y = 0;
    std::vector<int> columns;
    std::unordered_map<uint64_t, float> pending_scroll;
    float root_scroll = 0;
};
thread_local State *state = nullptr;
void push_id(uint64_t id) {
    char value[32]; std::snprintf(value, sizeof(value), "%llu", static_cast<unsigned long long>(id));
    ImGui::PushID(value);
    if (state->request_focus == id) { ImGui::SetKeyboardFocusHere(); state->request_focus = 0; }
}
bool requested(uint64_t id, int action) {
    for (auto it = state->actions.begin(); it != state->actions.end(); ++it) {
        if (it->id == id && it->action == action) { state->actions.erase(it); return true; }
    }
    return false;
}
void scroll_actions(uint64_t id) {
    const float step=std::max(1.0f,ImGui::GetWindowHeight()*0.85f);
    if (requested(id,VIMGUI_AX_SCROLL_UP)) ImGui::SetScrollY(ImGui::GetScrollY()-step);
    if (requested(id,VIMGUI_AX_SCROLL_DOWN)) ImGui::SetScrollY(ImGui::GetScrollY()+step);
    for (auto it=state->actions.begin();it!=state->actions.end();) {
        if (it->id==id && it->action==VIMGUI_AX_SET_SCROLL_PERCENT) {
            char *end=nullptr;
            const float percentage=std::strtof(it->value.c_str(),&end);
            if (end && *end=='\0' && std::isfinite(percentage) && percentage>=0 && percentage<=100)
                ImGui::SetScrollY(ImGui::GetScrollMaxY()*percentage/100);
            it=state->actions.erase(it);
        } else ++it;
    }
}
// Empty-space gestures belong to the hovered scroll container. Interactive
// controls and scrollbars keep their normal press/edit behavior.
void touch_scroll() {
    ImGuiIO &io=ImGui::GetIO();
    ImGuiWindow *window=ImGui::GetCurrentWindow();
    if (!state->touch && io.MouseSource!=ImGuiMouseSource_TouchScreen) return;
    if (ImGui::IsMouseClicked(0) && GImGui->HoveredWindow==window &&
        !GImGui->HoveredId && !GImGui->ActiveId && window->ScrollMax.y>0) {
        state->touch_window=window->ID; state->touch_start=io.MousePos;
        state->background_drag=false;
    }
    if (state->touch_window!=window->ID) return;
    if (ImGui::IsMouseDown(0)) {
        if (std::abs(io.MousePos.y-state->touch_start.y)>ImGui::GetFontSize()*0.3f) {
            state->background_drag=true;
            state->touch_active=window->GetID("##background-scroll");
            ImGui::SetActiveID(state->touch_active,window);
        }
        if (state->background_drag) {
            ImGui::KeepAliveID(state->touch_active);
            ImGui::SetScrollY(std::max(0.0f,std::min(window->ScrollMax.y,window->Scroll.y-io.MouseDelta.y)));
        }
    } else {
        if (GImGui->ActiveId==state->touch_active) ImGui::ClearActiveID();
        state->touch_window=state->touch_active=0; state->background_drag=false;
    }
}
void reveal_item(uint64_t id) {
    if (state->reveal == id || requested(id, VIMGUI_AX_SCROLL_INTO_VIEW)) {
        ImGui::SetScrollHereY(0.0f);
        state->reveal = 0;
    }
}
void append(uint64_t id) {
    if (id == 1 || !state->frame_ids.insert(id).second) { state->error = "Duplicate or reserved UI identity."; return; }
    state->groups.back().children.push_back(id);
}
void publish(uint64_t id, int role, const char *label, const char *value,
             ImVec2 origin, ImVec2 size, unsigned actions = 0, unsigned flags = 0,
             const std::vector<uint64_t> *children = nullptr, size_t anchor = 0, size_t focus = 0,
             double scroll_y=0, double scroll_max=0, size_t position=0, size_t total=0,
             double numeric_value=0, double numeric_min=0, double numeric_max=0) {
    const auto vp = ImGui::GetMainViewport()->Pos;
    vimgui_accessibility_node node{};
    node.id = id; node.role = role; node.label = label; node.value = value;
    node.x = origin.x - vp.x; node.y = origin.y - vp.y;
    node.width = std::max(0.0f, size.x); node.height = std::max(0.0f, size.y);
    node.actions = actions; node.flags = flags; node.text_anchor = anchor; node.text_focus = focus;
    node.scroll_y=scroll_y; node.scroll_y_max=scroll_max;
    node.position_in_set=position; node.size_of_set=total;
    node.numeric_value=numeric_value; node.numeric_min=numeric_min; node.numeric_max=numeric_max;
    if (children) { node.children = children->data(); node.child_count = children->size(); }
    if (!vimgui_accessibility_set_node(state->ax, &node)) state->error = vimgui_accessibility_error(state->ax);
}
void item(uint64_t id, int role, const char *label, const char *value, unsigned actions, unsigned flags = 0) {
    append(id);
    auto a = ImGui::GetItemRectMin(), b = ImGui::GetItemRectMax();
    publish(id, role, state->next_control_name.empty() ? label : state->next_control_name.c_str(), value, a, {b.x-a.x, b.y-a.y}, actions, flags);
    state->next_control_name.clear();
    reveal_item(id);
    if (ImGui::IsItemFocused() || ImGui::IsItemActive()) state->focus = id;
    ImGui::PopID();
}
}

bool vimgui_app_initialize(const char *title) {
    if (state || !ImGui::GetCurrentContext()) return false;
    state = new State; state->title = title ? title : "Application";
    state->ax = vimgui_accessibility_create();
    vimgui_accessibility_node root{}; root.id = 1; root.role = VIMGUI_AX_WINDOW; root.label = state->title.c_str();
    return vimgui_accessibility_set_node(state->ax, &root) && vimgui_accessibility_commit(state->ax, 1, 1);
}
void vimgui_app_shutdown() {
    if (!state) return;
    vimgui_accessibility_free(state->ax); delete state; state = nullptr;
}
vimgui_accessibility *vimgui_app_accessibility() { return state ? state->ax : nullptr; }
const char *vimgui_app_error() { return state ? state->error.c_str() : "No application UI context."; }
void vimgui_app_frame_begin() {
    ++state->frame; state->error.clear(); state->next_control_name.clear(); state->groups.clear(); state->frame_ids.clear(); state->actions.clear();
    vimgui_accessibility_event event{};
    while (vimgui_accessibility_poll(state->ax, &event)) {
        if (event.action == VIMGUI_AX_FOCUS) state->request_focus = event.target;
        state->actions.push_back({event.target, event.action, event.value ? event.value : "", event.anchor, event.focus});
    }
    auto *vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos({vp->Pos.x + state->safe_left, vp->Pos.y + state->safe_top});
    ImGui::SetNextWindowSize({std::max(1.0f, vp->Size.x-state->safe_left-state->safe_right),
                            std::max(1.0f, vp->Size.y-state->safe_top-state->safe_bottom)});
    if (auto found = state->pending_scroll.find(1); found != state->pending_scroll.end()) {
        ImGui::SetNextWindowScroll({-1, found->second}); state->pending_scroll.erase(found);
    }
    ImGui::Begin(state->title.c_str(), nullptr, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
                 ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoMove |
                 ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoBringToFrontOnFocus);
    state->root_scroll = ImGui::GetScrollY();
    scroll_actions(1);
    state->groups.push_back({1, state->title, {}, ImGui::GetWindowPos()});
}
bool vimgui_app_frame_end() {
    if (state->groups.size() != 1) {
        while (state->groups.size()>1) {
            state->groups.pop_back(); ImGui::EndChild(); ImGui::PopID();
        }
        ImGui::End();
        vimgui_accessibility_abort(state->ax);
        state->error = "Unbalanced application panels."; return false;
    }
    touch_scroll();
    double focus_x, focus_y, focus_width, focus_height;
    if (vimgui_accessibility_visual_focus(state->ax, &focus_x, &focus_y, &focus_width, &focus_height)) {
        const auto origin = ImGui::GetMainViewport()->Pos;
        ImVec2 a(origin.x + float(focus_x), origin.y + float(focus_y));
        ImVec2 b(a.x + float(focus_width), a.y + float(focus_height));
        auto *draw = ImGui::GetForegroundDrawList();
        const float stroke = std::max(2.0f, ImGui::GetFontSize() / 8.0f);
        draw->AddRect(a, b, IM_COL32(0,0,0,255), 0.0f, stroke * 3);
        draw->AddRect(a, b, IM_COL32(255,255,0,255), 0.0f, stroke);
    }
    state->root_scroll = ImGui::GetScrollY();
    auto root = state->groups.back();
    publish(1, VIMGUI_AX_WINDOW, state->title.c_str(), "", root.origin, ImGui::GetWindowSize(),
            VIMGUI_AX_SCROLL_UP|VIMGUI_AX_SCROLL_DOWN|VIMGUI_AX_SET_SCROLL_PERCENT, 0, &root.children,0,0,ImGui::GetScrollY(),ImGui::GetScrollMaxY());
    ImGui::End();
    for (auto it=state->pending_selections.begin(); it!=state->pending_selections.end();) {
        if (!state->frame_ids.count(it->first)) it=state->pending_selections.erase(it);
        else ++it;
    }
    if (!state->frame_ids.count(state->focus)) {
        bool retained = false;
        for (const auto &entry : state->lists) {
            if (entry.second.last_frame == state->frame && entry.second.indices.count(state->focus)) retained = true;
        }
        if (!retained) state->focus = 1;
    }
    if (!state->error.empty()) { vimgui_accessibility_abort(state->ax); return false; }
    if (!vimgui_accessibility_commit(state->ax, 1, state->focus)) { state->error = vimgui_accessibility_error(state->ax); return false; }
    return true;
}
void vimgui_app_theme(bool dark, bool contrast, float scale, bool touch) {
    if (!state) return;
    scale = std::max(0.5f, std::min(16.0f, scale));
    ImGuiStyle style{};
    if (dark) ImGui::StyleColorsDark(&style); else ImGui::StyleColorsLight(&style);
    const ImVec4 text = dark ? ImVec4(0.95f,0.97f,0.95f,1) : ImVec4(0.06f,0.10f,0.07f,1);
    const ImVec4 panel = dark ? ImVec4(0.08f,0.12f,0.09f,1) : ImVec4(0.98f,0.99f,0.98f,1);
    style.Colors[ImGuiCol_Text] = text;
    style.Colors[ImGuiCol_WindowBg] = panel;
    style.Colors[ImGuiCol_ChildBg] = panel;
    style.Colors[ImGuiCol_Border] = dark ? ImVec4(0.55f,0.65f,0.57f,1) : ImVec4(0.3f,0.4f,0.32f,1);
    style.Colors[ImGuiCol_TextDisabled] = dark ? ImVec4(0.7f,0.76f,0.7f,1) : ImVec4(0.35f,0.4f,0.35f,1);
    const ImVec4 control = dark ? ImVec4(0.17f,0.29f,0.20f,1) : ImVec4(0.78f,0.87f,0.80f,1);
    const ImVec4 hover = dark ? ImVec4(0.23f,0.36f,0.27f,1) : ImVec4(0.68f,0.79f,0.70f,1);
    for (int c : {ImGuiCol_Button, ImGuiCol_FrameBg, ImGuiCol_Header}) style.Colors[c] = control;
    for (int c : {ImGuiCol_ButtonHovered, ImGuiCol_ButtonActive, ImGuiCol_FrameBgHovered, ImGuiCol_FrameBgActive, ImGuiCol_HeaderHovered, ImGuiCol_HeaderActive}) style.Colors[c] = hover;
    style.Colors[ImGuiCol_CheckMark] = text;
    style.Colors[ImGuiCol_NavCursor] = dark ? ImVec4(1,0.85f,0.3f,1) : ImVec4(0.15f,0.24f,0.7f,1);
    if (contrast) {
        const ImVec4 fg = dark ? ImVec4(1,1,1,1) : ImVec4(0,0,0,1);
        const ImVec4 bg = dark ? ImVec4(0,0,0,1) : ImVec4(1,1,1,1);
        style.Colors[ImGuiCol_Text] = style.Colors[ImGuiCol_TextDisabled] = fg;
        style.Colors[ImGuiCol_WindowBg] = style.Colors[ImGuiCol_ChildBg] = style.Colors[ImGuiCol_PopupBg] = bg;
        for (int c : {ImGuiCol_Button, ImGuiCol_FrameBg, ImGuiCol_Header, ImGuiCol_ButtonHovered, ImGuiCol_ButtonActive,
                      ImGuiCol_FrameBgHovered, ImGuiCol_FrameBgActive, ImGuiCol_HeaderHovered, ImGuiCol_HeaderActive})
            style.Colors[c] = dark ? ImVec4(0.12f,0.12f,0.12f,1) : ImVec4(0.88f,0.88f,0.88f,1);
        style.Colors[ImGuiCol_Border] = style.Colors[ImGuiCol_CheckMark] = style.Colors[ImGuiCol_NavCursor] = fg;
        style.FrameBorderSize = 2;
    }
    // Keep the thumb usable even when a long list makes its proportional size tiny.
    state->touch = touch;
    style.ScrollbarSize = touch ? 48.0f : 20.0f;
    style.GrabMinSize = touch ? 48.0f : 24.0f;
    style.Colors[ImGuiCol_ScrollbarGrab] = style.Colors[ImGuiCol_Border];
    style.Colors[ImGuiCol_ScrollbarGrabHovered] = text;
    style.Colors[ImGuiCol_ScrollbarGrabActive] = text;
    if (contrast) style.Colors[ImGuiCol_PlotHistogram] = style.Colors[ImGuiCol_Text];
    style.WindowPadding = {14,14}; style.ItemSpacing = {10,10};
    style.FramePadding = {10,touch ? 16.0f : 7.0f};
    style.ScaleAllSizes(scale); style.FontSizeBase = 16; style.FontScaleMain = scale;
    ImGui::GetStyle() = style;
    state->row_height = std::max(touch ? 48.0f : 32.0f, 32.0f) * scale;
}
void vimgui_app_safe_area(float l, float t, float r, float b) { state->safe_left=std::max(0.0f,l); state->safe_top=std::max(0.0f,t); state->safe_right=std::max(0.0f,r); state->safe_bottom=std::max(0.0f,b); }
float vimgui_app_width() { return ImGui::GetContentRegionAvail().x; }
float vimgui_app_height() { return ImGui::GetContentRegionAvail().y; }
void vimgui_app_set_text_edit_handler(vimgui_app_text_edit handler, void *userdata) {
    state->text_edit=handler; state->text_edit_userdata=userdata;
}
void vimgui_app_next_control_name(const char *name) { state->next_control_name = name ? name : ""; }
bool vimgui_app_button(uint64_t id, const char *label) {
    push_id(id);
    const float available=ImGui::GetContentRegionAvail().x;
    const ImGuiStyle &style=ImGui::GetStyle();
    const bool back=std::strncmp(label,"Back",4)==0 || std::strncmp(label,"Hide scan setup",15)==0;
    const float arrow_width=back?ImGui::GetFontSize()+style.ItemInnerSpacing.x:0;
    const float text_width=std::max(1.0f,available-2*style.FramePadding.x-arrow_width);
    bool value;
    if (back || (available>0 && ImGui::CalcTextSize(label,nullptr,true).x>text_width)) {
        const char *end=ImGui::FindRenderedTextEnd(label);
        const ImVec2 size=ImGui::CalcTextSize(label,end,false,text_width);
        value=ImGui::Button("##wrapped-button",{std::min(available,size.x+arrow_width+2*style.FramePadding.x),size.y+2*style.FramePadding.y});
        ImVec2 origin=ImGui::GetItemRectMin();
        origin.x+=style.FramePadding.x+arrow_width; origin.y+=style.FramePadding.y;
        ImGui::GetWindowDrawList()->AddText(nullptr,0,origin,ImGui::GetColorU32(ImGuiCol_Text),label,end,text_width);
    } else value=ImGui::Button(label);
    value = requested(id, VIMGUI_AX_CLICK) || value;
    if (back) {
        ImVec2 origin=ImGui::GetItemRectMin();
        ImGui::RenderArrow(ImGui::GetWindowDrawList(),{origin.x+style.FramePadding.x,origin.y+style.FramePadding.y},ImGui::GetColorU32(ImGuiCol_Text),ImGuiDir_Left,1.0f);
    }
    item(id,VIMGUI_AX_BUTTON,label,"",VIMGUI_AX_CLICK|VIMGUI_AX_FOCUS); return value;
}
bool vimgui_app_checkbox(uint64_t id, const char *label, bool *value) {
    push_id(id); bool changed = ImGui::Checkbox(label,value);
    if (requested(id,VIMGUI_AX_CLICK)) { *value=!*value; changed=true; }
    item(id,VIMGUI_AX_CHECKBOX,label,"",VIMGUI_AX_CLICK|VIMGUI_AX_FOCUS,*value?VIMGUI_AX_CHECKED:0); return changed;
}
bool vimgui_app_radio(uint64_t id, const char *label, bool selected) {
    push_id(id); bool value = ImGui::RadioButton(label,selected);
    value = requested(id,VIMGUI_AX_CLICK)||value;
    item(id,VIMGUI_AX_RADIO,label,"",VIMGUI_AX_CLICK|VIMGUI_AX_FOCUS,selected?VIMGUI_AX_CHECKED:0); return value;
}
bool vimgui_app_input(uint64_t id, const char *label, char *buffer, size_t capacity) {
    if (!buffer || !capacity) return false;
    const float field_width=ImGui::CalcItemWidth();
    ImGui::BeginGroup();
    // Table cells can inherit the preceding input's padded text baseline.
    // A label above a field starts at the cell top, rather than that baseline.
    ImGui::GetCurrentWindow()->DC.CurrLineTextBaseOffset=0;
    ImGui::TextWrapped("%s",label);
    ImGui::SetNextItemWidth(std::min(field_width,ImGui::GetContentRegionAvail().x));
    bool changed=false;
    for (auto it=state->actions.begin();it!=state->actions.end();++it) {
        if (it->id==id && it->action==VIMGUI_AX_SET_VALUE) {
            if (it->value.size()<capacity) { std::memcpy(buffer,it->value.c_str(),it->value.size()+1); changed=true; }
            else state->error="The entered text exceeds this field's capacity.";
            state->actions.erase(it); break;
        }
    }
    for (auto it=state->actions.begin();it!=state->actions.end();) {
        if (it->id==id && it->action==VIMGUI_AX_SET_SELECTION) {
            state->pending_selections[id]={it->anchor,it->focus};
            state->request_focus=id;
            it=state->actions.erase(it);
        } else ++it;
    }
    push_id(id);
    auto *input = ImGui::GetInputTextState(ImGui::GetID("##input"));
    if (changed && input) input->ReloadUserBufAndMoveToEnd();
    const auto callback=[](ImGuiInputTextCallbackData *data) -> int {
        if (state->text_edit) state->text_edit(data,state->text_edit_userdata);
        return 0;
    };
    changed=ImGui::InputText("##input",buffer,capacity,state->text_edit?ImGuiInputTextFlags_CallbackAlways:0,
                            state->text_edit?+callback:nullptr)||changed;
    input = ImGui::GetInputTextState(ImGui::GetItemID());
    auto byte_offset = [buffer](size_t index) { size_t pos=0; while (buffer[pos] && index) { ++pos; while (buffer[pos] && (static_cast<unsigned char>(buffer[pos])&0xc0)==0x80) ++pos; --index; } return static_cast<int>(pos); };
    auto selection=state->pending_selections.find(id);
    if (selection!=state->pending_selections.end() && input) {
        input->SetSelection(byte_offset(selection->second.first),byte_offset(selection->second.second));
        state->pending_selections.erase(selection);
    }
    auto char_offset = [buffer](int bytes) { size_t count=0; for (int i=0;i<bytes && buffer[i];++i) if ((static_cast<unsigned char>(buffer[i])&0xc0)!=0x80) ++count; return count; };
    const size_t anchor = input ? char_offset(input->GetSelectionStart()) : 0;
    const size_t focus = input ? char_offset(input->GetSelectionEnd()) : 0;
    append(id); auto a=ImGui::GetItemRectMin(),b=ImGui::GetItemRectMax();
    state->input_y=a.y;
    publish(id,VIMGUI_AX_TEXT_INPUT,label,buffer,a,{b.x-a.x,b.y-a.y},VIMGUI_AX_FOCUS|VIMGUI_AX_SET_VALUE|VIMGUI_AX_SET_SELECTION,0,nullptr,anchor,focus);
    if (ImGui::IsItemFocused() || ImGui::IsItemActive()) state->focus=id;
    ImGui::PopID();
    ImGui::EndGroup();
    reveal_item(id);
    return changed;
}
void vimgui_app_text(uint64_t id, const char *text) { push_id(id); ImGui::TextWrapped("%s",text); item(id,VIMGUI_AX_LABEL,text,text,0); }
void vimgui_app_status(uint64_t id,const char *text) { push_id(id); ImGui::TextWrapped("%s",text); item(id,VIMGUI_AX_LABEL,text,text,0,VIMGUI_AX_LIVE); }
void vimgui_app_progress(uint64_t id,const char *label,float fraction,const char *detail) {
    const bool unknown=!std::isfinite(fraction) || fraction<0;
    const float value=unknown ? 0 : std::min(1.0f,std::max(0.0f,fraction));
    push_id(id);
    ImGui::BeginGroup();
    ImGui::TextWrapped("%s%s%s",label ? label : "",detail && *detail ? ": " : "",detail ? detail : "");
    ImGui::ProgressBar(unknown ? -static_cast<float>(ImGui::GetTime()) : value,
                      {ImGui::GetContentRegionAvail().x,ImGui::GetFontSize()*0.625f},"");
    append(id);
    auto a=ImGui::GetItemRectMin(),b=ImGui::GetItemRectMax();
    publish(id,VIMGUI_AX_PROGRESS,label ? label : "",detail ? detail : "",a,{b.x-a.x,b.y-a.y},0,
            VIMGUI_AX_READ_ONLY | (unknown ? VIMGUI_AX_INDETERMINATE : 0),nullptr,0,0,0,0,0,0,value,0,1);
    ImGui::EndGroup();
    ImGui::PopID();
}
void vimgui_app_same_line() { ImGui::SameLine(); }
void vimgui_app_same_line_width(float width) {
    const float right=ImGui::GetCursorScreenPos().x+ImGui::GetContentRegionAvail().x;
    if (width>0 && ImGui::GetItemRectMax().x+ImGui::GetStyle().ItemSpacing.x+width<=right)
        ImGui::SameLine();
}
float vimgui_app_control_width(const char *label,bool choice) {
    const ImGuiStyle &style=ImGui::GetStyle();
    const bool back=label && (std::strncmp(label,"Back",4)==0 || std::strncmp(label,"Hide scan setup",15)==0);
    return (back?ImGui::GetFontSize()+style.ItemInnerSpacing.x:0)+ImGui::CalcTextSize(label?label:"",nullptr,true).x+
        (choice?ImGui::GetFrameHeight()+style.ItemInnerSpacing.x:style.FramePadding.x*2);
}
void vimgui_app_begin_columns(uint64_t id,float minimum,float trailing) {
    push_id(id);
    const float available=ImGui::GetContentRegionAvail().x;
    const float second=trailing>0?trailing:minimum;
    const int count=available>=minimum+second+ImGui::GetStyle().ItemSpacing.x?2:1;
    bool active=ImGui::BeginTable("##columns",count,ImGuiTableFlags_SizingStretchSame|ImGuiTableFlags_NoSavedSettings|ImGuiTableFlags_NoPadOuterX);
    state->columns.push_back(active?count:0);
    if (active) {
        // Equal stretch weights must not inherit content widths from stacked frames.
        ImGui::TableSetupColumn("first",ImGuiTableColumnFlags_WidthStretch,1.0f);
        if (count==2) ImGui::TableSetupColumn("second",trailing>0?ImGuiTableColumnFlags_WidthFixed:ImGuiTableColumnFlags_WidthStretch,trailing>0?trailing:1.0f);
        ImGui::TableNextColumn();
    }
}
void vimgui_app_next_column(bool align_input) {
    if (state->columns.empty() || !state->columns.back()) return;
    ImGui::TableNextColumn();
    if (align_input && state->columns.back()==2) {
        ImVec2 cursor=ImGui::GetCursorScreenPos(); cursor.y=state->input_y;
        ImGui::SetCursorScreenPos(cursor);
    }
}
void vimgui_app_end_columns() {
    if (state->columns.empty()) { state->error="Unbalanced columns."; return; }
    if (state->columns.back()) ImGui::EndTable();
    state->columns.pop_back(); ImGui::PopID();
}
void vimgui_app_separator() { ImGui::Separator(); }
void vimgui_app_set_width(float width) { ImGui::SetNextItemWidth(width); }
void vimgui_app_begin_panel(uint64_t id,const char *label,float width,float height) {
    append(id); push_id(id); ImGui::BeginChild("panel",{width,height},ImGuiChildFlags_Borders);
    scroll_actions(id);
    state->groups.push_back({id,label,{},ImGui::GetWindowPos()});
}
void vimgui_app_end_panel() {
    if (state->groups.size()<2) { state->error="Unbalanced panel end."; return; }
    touch_scroll();
    auto group=state->groups.back(); state->groups.pop_back();
    publish(group.id,VIMGUI_AX_GROUP,group.label.c_str(),"",group.origin,ImGui::GetWindowSize(),
            VIMGUI_AX_SCROLL_UP|VIMGUI_AX_SCROLL_DOWN|VIMGUI_AX_SET_SCROLL_PERCENT,0,&group.children,0,0,ImGui::GetScrollY(),ImGui::GetScrollMaxY());
    ImGui::EndChild(); reveal_item(group.id); ImGui::PopID();
}
void vimgui_app_list_reset(uint64_t id) { state->lists[id]=List{}; }
bool vimgui_app_list_add(uint64_t list_id,uint64_t id,const char *label) {
    auto &list=state->lists[list_id];
    if (!id || (id & (uint64_t(1)<<63)) || id==list_id || id==1 || list.indices.count(id)) { state->error="Duplicate or reserved list row ID."; return false; }
    list.indices[id]=static_cast<int>(list.rows.size());list.rows.push_back({id,label});return true;
}
uint64_t vimgui_app_list(uint64_t id,const char *label,uint64_t selected,float height) {
    append(id);push_id(id);
    auto &list=state->lists[id];
    const float row_height=std::max(state->row_height,ImGui::GetTextLineHeight()+16);
    // A crowded parent must scroll rather than collapse a list into an
    // inaccessible sliver. Zero retains the usual fill-remaining-space behavior.
    const float minimum_height=row_height*std::min<size_t>(3,std::max<size_t>(1,list.rows.size()))+
        ImGui::GetStyle().WindowPadding.y*2;
    const float requested_height=height==0?ImGui::GetContentRegionAvail().y:height;
    if (auto found = state->pending_scroll.find(id); found != state->pending_scroll.end()) {
        ImGui::SetNextWindowScroll({-1, found->second}); state->pending_scroll.erase(found);
    }
    ImGui::BeginChild("list",{0,std::max(minimum_height,requested_height)},ImGuiChildFlags_Borders,ImGuiWindowFlags_AlwaysVerticalScrollbar);
    const auto &io=ImGui::GetIO();
    if (io.MouseSource==ImGuiMouseSource_TouchScreen && ImGui::IsMouseClicked(0) &&
        ImGui::IsWindowHovered(ImGuiHoveredFlags_AllowWhenBlockedByActiveItem) &&
        ImGui::GetCurrentWindow()->InnerRect.Contains(io.MousePos)) list.touch_tracking=true;
    if (list.touch_tracking && ImGui::IsMouseDown(0)) {
        if (std::abs(ImGui::GetMouseDragDelta(0,0).y)>state->row_height*0.2f) list.touch_dragging=true;
        if (list.touch_dragging) ImGui::SetScrollY(ImGui::GetScrollY()-io.MouseDelta.y);
    }
    const auto origin=ImGui::GetWindowPos(),size=ImGui::GetWindowSize();
    const float scroll_y=ImGui::GetScrollY(),scroll_max=ImGui::GetScrollMaxY();
    auto content_origin=ImGui::GetCursorScreenPos(); content_origin.y+=scroll_y;
    const float content_width=ImGui::GetContentRegionAvail().x;
    // Retain every row in the application, but keep the OS tree bounded.
    // Publishing all off-screen rows makes native adapter filtering expensive
    // even when the renderer itself is clipped. Neighbor rows remain available
    // for assistive-technology scroll-into-view actions.
    const int first=std::max(0,static_cast<int>(scroll_y/row_height)-1);
    const int end=std::min(static_cast<int>(list.rows.size()),
        static_cast<int>((scroll_y+size.y)/row_height)+2);
    std::vector<uint64_t> exposed;
    auto expose=[&](int index) {
        const auto &row=list.rows[index];
        exposed.push_back(row.id);
        publish(row.id,VIMGUI_AX_LIST_ITEM,row.label.c_str(),"",{content_origin.x,content_origin.y+index*row_height},
            {content_width,row_height},VIMGUI_AX_CLICK|VIMGUI_AX_FOCUS|VIMGUI_AX_SCROLL_INTO_VIEW,row.id==selected?VIMGUI_AX_SELECTED:0,nullptr,0,0,0,0,index+1,list.rows.size());
    };
    for(int index=first;index<end;++index) expose(index);
    // Keep the focused row alive until the requested scroll takes effect.
    auto focused=list.indices.find(state->focus);
    if(focused!=list.indices.end() && (focused->second<first||focused->second>=end)) expose(focused->second);
    publish(id,VIMGUI_AX_LIST,label,"",origin,size,VIMGUI_AX_SCROLL_UP|VIMGUI_AX_SCROLL_DOWN|VIMGUI_AX_SET_SCROLL_PERCENT|VIMGUI_AX_SCROLL_INTO_VIEW,0,&exposed,0,0,scroll_y,scroll_max);
    scroll_actions(id);
    uint64_t activated=0;
    for (auto it=state->actions.begin();it!=state->actions.end();) {
        if (it->id==id && (it->action==VIMGUI_AX_SCROLL_UP || it->action==VIMGUI_AX_SCROLL_DOWN)) {
            ImGui::SetScrollY(scroll_y+(it->action==VIMGUI_AX_SCROLL_DOWN?1:-1)*size.y*0.85f);
            it=state->actions.erase(it); continue;
        }
        auto found=list.indices.find(it->id);
        if(found==list.indices.end()) { ++it; continue; }
        if(it->action==VIMGUI_AX_FOCUS||it->action==VIMGUI_AX_SCROLL_INTO_VIEW) {
            ImGui::SetScrollY(found->second*row_height); state->request_focus=it->id;
        } else if(it->action==VIMGUI_AX_CLICK) activated=it->id;
        it=state->actions.erase(it);
    }
    if(list.indices.count(state->request_focus)) ImGui::SetScrollY(list.indices[state->request_focus]*row_height);
    ImGuiListClipper clipper;clipper.Begin(static_cast<int>(list.rows.size()),row_height);
    while(clipper.Step()) for(int i=clipper.DisplayStart;i<clipper.DisplayEnd;++i) {
        const auto &row=list.rows[i];push_id(row.id);
        const auto text_pos=ImGui::GetCursorScreenPos();
        if(ImGui::Selectable("##row",row.id==selected,ImGuiSelectableFlags_None,{0,row_height-ImGui::GetStyle().ItemSpacing.y}) && !list.touch_dragging) activated=row.id;
        ImGui::GetWindowDrawList()->AddText(text_pos,ImGui::GetColorU32(ImGuiCol_Text),row.label.data(),row.label.data()+row.label.size());
        auto a=ImGui::GetItemRectMin(),b=ImGui::GetItemRectMax();
        a.y+=scroll_y; b.y+=scroll_y;
        publish(row.id,VIMGUI_AX_LIST_ITEM,row.label.c_str(),"",a,{b.x-a.x,b.y-a.y},VIMGUI_AX_CLICK|VIMGUI_AX_FOCUS|VIMGUI_AX_SCROLL_INTO_VIEW,row.id==selected?VIMGUI_AX_SELECTED:0,nullptr,0,0,0,0,i+1,list.rows.size());
        if(ImGui::IsItemFocused()) state->focus=row.id;
        ImGui::PopID();
    }
    list.last_frame=state->frame;
    if (!ImGui::IsMouseDown(0)) { list.touch_tracking=false; list.touch_dragging=false; }
    list.scroll_y=scroll_y; list.scroll_max=scroll_max;
    ImGui::EndChild();reveal_item(id);ImGui::PopID();return activated;
}
void vimgui_app_focus(uint64_t id) { state->request_focus=id; }

void vimgui_app_reveal(uint64_t id) { state->reveal=id; }

bool vimgui_app_back_requested() {
    if (!state || !ImGui::GetCurrentContext()) return false;
    return ImGui::IsKeyPressed(ImGuiKey_AppBack, false) ||
        (ImGui::GetIO().KeyAlt && ImGui::IsKeyPressed(ImGuiKey_LeftArrow, false));
}

float vimgui_app_scroll(uint64_t id) {
    if (!state) return 0;
    if (id == 1) return state->root_scroll;
    auto found = state->lists.find(id);
    return found == state->lists.end() ? 0 : found->second.scroll_y;
}
void vimgui_app_restore_scroll(uint64_t id, float position) {
    if (state && id && std::isfinite(position) && position >= 0) state->pending_scroll[id] = position;
}
