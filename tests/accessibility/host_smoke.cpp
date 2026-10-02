#include "vimgui_app.h"
#include "imgui.h"
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <cstdio>
static int frames=0;
static bool edited=false;
static void text_edit(void *raw, void *) {
    auto *data=static_cast<ImGuiInputTextCallbackData *>(raw);
    if (!edited && data->EventFlag==ImGuiInputTextFlags_CallbackAlways) {
        data->DeleteChars(0,data->BufTextLen);
        data->InsertChars(0,"IME text");
        data->SetSelection(1,3);
        edited=true;
    }
}
static void frame(void *) {
    ++frames;
    static bool contrast=false;
    static char search[128]="";
    vimgui_app_set_text_edit_handler(text_edit,nullptr);
    if (frames==1) vimgui_app_focus(4);
    vimgui_app_text(2,"Accessible application host");
    vimgui_app_checkbox(3,"High contrast",&contrast);
    vimgui_app_input(4,"Search files",search,sizeof(search));
    vimgui_app_button(5,"Review selected file");
    vimgui_app_begin_panel(30,"Aligned form",680,160);
    vimgui_app_begin_columns(31,160,0);
    vimgui_app_set_width(-1); vimgui_app_input(32,"Minimum size",search,sizeof(search));
    const float minimum_right=ImGui::GetItemRectMax().x;
    vimgui_app_next_column(false);
    vimgui_app_set_width(-1); vimgui_app_input(33,"Sample size",search,sizeof(search));
    if (ImGui::GetItemRectMin().x<=minimum_right) { std::fprintf(stderr,"Field columns overlap\n"); std::abort(); }
    vimgui_app_end_columns();
    vimgui_app_begin_columns(34,160,vimgui_app_control_width("Add folder",false));
    vimgui_app_set_width(-1); vimgui_app_input(35,"Folder path",search,sizeof(search));
    const float input_right=ImGui::GetItemRectMax().x;
    vimgui_app_next_column(true); vimgui_app_button(36,"Add folder");
    if (ImGui::GetItemRectMin().x<=input_right) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    vimgui_app_end_columns(); vimgui_app_end_panel();
    if (frames==6 && ImGui::GetScrollY()<=0) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    if (frames==3) { vimgui_app_theme(true,false,1,true); ImGui::GetIO().AddMousePosEvent(700,450); ImGui::GetIO().AddMouseButtonEvent(0,true); }
    if (frames==4) ImGui::GetIO().AddMousePosEvent(700,250);
    if (frames==6) ImGui::GetIO().AddMouseButtonEvent(0,false);
    vimgui_app_progress(6,"Known progress",0.4f,"40% complete");
    vimgui_app_progress(7,"Unknown progress",-1,"Collecting files");
    vimgui_app_begin_panel(10,"Narrow layout",280,280);
    vimgui_app_button(11,"First");
    const ImVec2 first=ImGui::GetItemRectMin();
    vimgui_app_same_line_width(vimgui_app_control_width("Second",false));
    vimgui_app_button(12,"Second");
    if (ImGui::GetItemRectMin().y!=first.y) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    const float right=ImGui::GetCursorScreenPos().x+ImGui::GetContentRegionAvail().x;
    vimgui_app_same_line_width(vimgui_app_control_width("A long action label that must wrap onto multiple lines",false));
    vimgui_app_button(13,"A long action label that must wrap onto multiple lines");
    if (ImGui::GetItemRectMin().y<=first.y || ImGui::GetItemRectMax().x>right+1 ||
        ImGui::GetItemRectSize().y<=ImGui::GetFrameHeight()) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    vimgui_app_begin_columns(40,160,0);
    vimgui_app_set_width(-1); vimgui_app_input(41,"First field",search,sizeof(search));
    const float first_bottom=ImGui::GetItemRectMax().y;
    vimgui_app_next_column(false);
    vimgui_app_set_width(-1); vimgui_app_input(42,"Second field",search,sizeof(search));
    if (ImGui::GetItemRectMin().y<first_bottom) { std::fprintf(stderr,"Narrow fields did not stack\n"); std::abort(); }
    vimgui_app_end_columns();
    vimgui_app_end_panel();
    vimgui_app_begin_panel(20,"Crowded parent",220,160);
    vimgui_app_text(21,"One\nTwo\nThree\nFour\nFive\nSix\nSeven\nEight\nNine\nTen");
    if (frames==1) {
        vimgui_app_list_reset(22);
        for (uint64_t id=23;id<28;++id) vimgui_app_list_add(22,id,"Retained row");
        vimgui_app_reveal(22);
    }
    if (frames==2 && ImGui::GetScrollY()<=0) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    if (frames==6) {
        vimgui_app_restore_scroll(22,30);
        vimgui_app_list_reset(22);
        for (uint64_t id=23;id<28;++id) vimgui_app_list_add(22,id,"Retained row");
    }
    vimgui_app_list(22,"Crowded list",0,0);
    if (frames==7 && std::fabs(vimgui_app_scroll(22)-30)>1) { std::fprintf(stderr,"List scroll was lost during rebuild\n"); std::abort(); }
    if (ImGui::GetItemRectSize().y < 3*32) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    vimgui_app_end_panel();
    ImGui::Dummy({0,600});
    if (frames==8) vimgui_app_restore_scroll(1,40);
    if (frames==9 && std::fabs(ImGui::GetScrollY()-40)>1) { std::fprintf(stderr,"Root scroll was not restored\n"); std::abort(); }
    if (frames==5 && (!edited || std::strcmp(search,"IME text")!=0)) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
    if (frames==5) {
        vimgui_app_theme(true,true,4,true);
        if (ImGui::GetStyle().FontScaleMain!=4 || ImGui::GetStyle().ScrollbarSize<192 ||
            ImGui::GetStyle().GrabMinSize<192) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
        vimgui_app_theme(true,true,8,true);
        if (ImGui::GetStyle().FontScaleMain!=8) { std::fprintf(stderr,"Host smoke failed at line %d, frame %d\n",__LINE__,frames); std::abort(); }
        vimgui_app_theme(true,false,1,true);
    }
}
// Exercise the same table ID through wide, stacked, and rotated layouts. A
// stacked first field must not seed a larger stretch weight when columns return.
static void column_scaling_regression() {
    ImGui::CreateContext();
    ImGuiIO &io=ImGui::GetIO(); io.IniFilename=nullptr;
    io.BackendFlags|=ImGuiBackendFlags_RendererHasTextures;
    io.Fonts->AddFontDefault();
    if (!vimgui_app_initialize("Column scaling regression")) std::abort();
    char minimum[32]="1MiB",sample[32]="64KiB";
    for (int cycle=0;cycle<3;++cycle) {
        for (int frame=0;frame<15;++frame) {
            const float scale=frame>=4 && frame<8?2.0f:1.0f;
            io.DisplaySize={frame>=11?900.0f:700.0f,600}; io.DeltaTime=1.0f/60;
            vimgui_app_theme(true,false,scale,false);
            ImGui::NewFrame(); vimgui_app_frame_begin();
            vimgui_app_begin_columns(900,200*scale,0);
            vimgui_app_set_width(-1); vimgui_app_input(901,"Minimum size",minimum,sizeof(minimum));
            const ImVec2 first_min=ImGui::GetItemRectMin(),first_max=ImGui::GetItemRectMax();
            vimgui_app_next_column(false);
            vimgui_app_set_width(-1); vimgui_app_input(902,"Sample size",sample,sizeof(sample));
            const ImVec2 second_min=ImGui::GetItemRectMin(),second_max=ImGui::GetItemRectMax();
            if (scale==1 && (std::fabs((first_max.x-first_min.x)-(second_max.x-second_min.x))>2
                || second_min.x<=first_max.x || std::fabs(first_min.y-second_min.y)>1)) {
                std::fprintf(stderr,"Unequal columns after scaling: cycle %d frame %d, widths %.1f/%.1f\n",cycle,frame,first_max.x-first_min.x,second_max.x-second_min.x);
                std::abort();
            }
            if (scale==2 && second_min.y<first_max.y) { std::fprintf(stderr,"Scaled fields did not stack\n"); std::abort(); }
            vimgui_app_end_columns();
            if (!vimgui_app_frame_end()) std::abort();
            ImGui::Render();
        }
    }
    vimgui_app_shutdown(); ImGui::DestroyContext();
}
int main() { column_scaling_regression(); return vimgui_app_run("Application host smoke test",800,900,frame,nullptr,10); }
