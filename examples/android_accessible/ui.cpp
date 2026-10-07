// Supplies the accessible native UI used by the Android example host.
#include "../../native/application/vimgui_app.h"
#include "../../cimgui/imgui/imgui.h"
#include <cstdio>
#include <cstring>

extern "C" bool vimgui_android_accessible_draw(float *,int *count,char *search,int capacity,char *,int,float,float) {
    static uint64_t selected=0;
    static char previous_search[128]="";
    static bool contrast=false,large_text=false;
    static float base_scale=1;
    if (ImGui::GetFrameCount()==1) base_scale=ImGui::GetStyle().FontScaleMain;
    vimgui_app_frame_begin();
    vimgui_app_text(2,"Accessible file review");
    bool theme_changed=vimgui_app_checkbox(7,"High contrast",&contrast);
    vimgui_app_same_line();
    theme_changed=vimgui_app_checkbox(8,"200% text",&large_text)||theme_changed;
    if (theme_changed || ImGui::GetFrameCount()==1) vimgui_app_theme(true,contrast,base_scale*(large_text?2:1),true);
    vimgui_app_set_width(-1);
    vimgui_app_input(3,"Search files",search,static_cast<size_t>(capacity));
    if (vimgui_app_button(4,"Keep selected")) ++*count;
    vimgui_app_same_line();
    if (vimgui_app_button(9,"Last file")) vimgui_app_focus(1099);
    char status[128];
    std::snprintf(status,sizeof(status),"Keeper actions: %d",*count);
    vimgui_app_status(5,status);
    vimgui_app_progress(10,"Known progress",0.4f,"40% complete");
    vimgui_app_progress(11,"Unknown progress",-1,"Collecting files");
    if (ImGui::GetFrameCount()==1 || std::strcmp(previous_search,search)!=0) {
        vimgui_app_list_reset(6);
        for (int i=0;i<1000;++i) {
            char label[96]; std::snprintf(label,sizeof(label),"Photo %04d.jpg - 3 copies",i);
            if (!*search || std::strstr(label,search)) vimgui_app_list_add(6,100+i,label);
        }
        std::snprintf(previous_search,sizeof(previous_search),"%s",search);
    }
    uint64_t activated=vimgui_app_list(6,"Files",selected,0);
    if (activated) selected=activated;
    if (!vimgui_app_frame_end()) std::fprintf(stderr,"Accessibility frame: %s\n",vimgui_app_error());
    return false;
}
