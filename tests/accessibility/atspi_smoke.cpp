// Checks the Linux AT-SPI accessibility surface exposed by a running host.
#include <atspi/atspi.h>
#include <gio/gio.h>
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <deque>
#include <stdexcept>
#include <string>
#include <thread>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
static void settle(){while(g_main_context_pending(nullptr))g_main_context_iteration(nullptr,false);std::this_thread::sleep_for(std::chrono::milliseconds(100));}
static AtspiAccessible *find(const std::string &name){std::deque<AtspiAccessible *> queue;queue.push_back(atspi_get_desktop(0));
    while(!queue.empty()){auto *object=queue.front();queue.pop_front();if(!object)continue;gchar *label=atspi_accessible_get_name(object,nullptr);
        bool match=label && name==label;g_free(label);
        if(match){for(auto *remaining:queue)if(remaining)g_object_unref(remaining);return object;}
        for(int i=0;i<atspi_accessible_get_child_count(object,nullptr);i++)queue.push_back(atspi_accessible_get_child_at_index(object,i,nullptr));
        g_object_unref(object);}
    return nullptr;}
static AtspiAccessible *require(const std::string &name){auto end=std::chrono::steady_clock::now()+std::chrono::seconds(20);
    while(std::chrono::steady_clock::now()<end){settle();auto *node=find(name);if(node)return node;}throw std::runtime_error("Missing AT-SPI control: "+name);}
static void click(const std::string &name){auto *node=require(name);auto *action=atspi_accessible_get_action_iface(node);bool accepted=false;
    if(action)for(int i=0;i<atspi_action_get_n_actions(action,nullptr);i++){auto *label=atspi_action_get_action_name(action,i,nullptr);
        bool match=label && (std::string(label)=="click"||std::string(label)=="press"||std::string(label)=="toggle");g_free(label);
        if(match){accepted=atspi_action_do_action(action,i,nullptr);break;}}
    if(action)g_object_unref(action);g_object_unref(node);if(!accepted)throw std::runtime_error("Native action rejected: "+name);}
static void has_state(const std::string &name,AtspiStateType state){auto end=std::chrono::steady_clock::now()+std::chrono::seconds(10);
    while(std::chrono::steady_clock::now()<end){settle();auto *node=find(name);if(!node)continue;auto *states=atspi_accessible_get_state_set(node);
        bool found=atspi_state_set_contains(states,state);g_object_unref(states);g_object_unref(node);if(found)return;}
    throw std::runtime_error("Native state did not update: "+name);}
static void expect(const std::string &name){auto *node=require(name);g_object_unref(node);}
int main(int argc,char **argv) {
    if(argc!=2){std::fprintf(stderr,"Usage: atspi-smoke executable\n");return 2;}
    g_setenv("GSETTINGS_BACKEND","memory",true);
    GError *error=nullptr;auto *bus=g_bus_get_sync(G_BUS_TYPE_SESSION,nullptr,&error);
    if(!bus){std::fprintf(stderr,"%s\n",error->message);g_error_free(error);return 1;}
    for(auto property:{"IsEnabled","ScreenReaderEnabled"}) {
        auto *reply=g_dbus_connection_call_sync(bus,"org.a11y.Bus","/org/a11y/bus","org.freedesktop.DBus.Properties","Set",g_variant_new("(ssv)","org.a11y.Status",property,g_variant_new_boolean(true)),nullptr,G_DBUS_CALL_FLAGS_NONE,10000,nullptr,&error);
        if(!reply){std::fprintf(stderr,"%s\n",error->message);g_error_free(error);g_object_unref(bus);return 1;}g_variant_unref(reply);
    }
    g_object_unref(bus);atspi_init();pid_t child=fork();
    if(child==0){execl(argv[1],argv[1],nullptr);_exit(127);}
    if(child<0){std::perror("fork");atspi_exit();return 1;}
    int result=0;
    try {
        auto bounded=[] {auto *files=require("Files");int count=atspi_accessible_get_child_count(files,nullptr);g_object_unref(files);if(count<=0||count>=100)throw std::runtime_error("Native list must expose a bounded viewport");};
        bounded();click("Focus last file");expect("Photo 099999.jpg — Pictures / Archive");bounded();click("Photo 099999.jpg — Pictures / Archive");has_state("Photo 099999.jpg — Pictures / Archive",ATSPI_STATE_SELECTED);
        auto *last=require("Photo 099999.jpg — Pictures / Archive");auto *component=atspi_accessible_get_component_iface(last);
        if(!atspi_component_grab_focus(component,nullptr))throw std::runtime_error("Off-screen focus rejected");g_object_unref(component);g_object_unref(last);
        bool visible=false;
        for(int attempt=0;attempt<100&&!visible;attempt++) {settle();last=require("Photo 099999.jpg — Pictures / Archive");auto *files=require("Files");
            auto *row=atspi_accessible_get_component_iface(last);auto *list=atspi_accessible_get_component_iface(files);
            auto *a=atspi_component_get_extents(row,ATSPI_COORD_TYPE_SCREEN,nullptr);auto *b=atspi_component_get_extents(list,ATSPI_COORD_TYPE_SCREEN,nullptr);
            visible=a&&b&&a->height>0&&a->y>=b->y&&a->y+a->height<=b->y+b->height;
            g_free(a);g_free(b);g_object_unref(row);g_object_unref(list);g_object_unref(last);g_object_unref(files);
        }
        if(!visible)throw std::runtime_error("Focused row did not move into viewport");
        click("Keep selected");expect("Keeper saved: Photo 099999.jpg");
        auto *search=require("Search files");auto *edit=atspi_accessible_get_editable_text_iface(search);
        if(!atspi_editable_text_set_text_contents(edit,"099999",nullptr))throw std::runtime_error("Search edit rejected");g_object_unref(edit);g_object_unref(search);
        bool filtered=false;
        for(int attempt=0;attempt<100&&!filtered;attempt++){settle();auto *files=require("Files");filtered=atspi_accessible_get_child_count(files,nullptr)==1;g_object_unref(files);}
        if(!filtered)throw std::runtime_error("Native search did not filter the list");
        std::puts("PASS: 100,000 retained rows, virtual navigation, scrolled geometry, keeper action and editable search");
    }catch(const std::exception &error){std::fprintf(stderr,"%s\n",error.what());result=1;}
    kill(child,SIGTERM);waitpid(child,nullptr,0);atspi_exit();return result;
}
