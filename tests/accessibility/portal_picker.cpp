// A private portal exercises the real NFD client without opening a chooser.
#include <gio/gio.h>
#include <dlfcn.h>
#include <cstdio>
#include <filesystem>
#include <stdexcept>
#include <string>
#include <thread>
static const char *xml=R"(<node><interface name="org.freedesktop.portal.FileChooser"><method name="OpenFile"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="a{sv}" direction="in"/><arg type="o" direction="out"/></method><property name="version" type="u" access="read"/></interface></node>)";
struct Portal {GMainLoop *loop;std::string directory,chosen;int requests=0;bool valid=true;};
struct Response {GDBusConnection *connection;std::string sender,path,uri;unsigned code;};
static gboolean respond(gpointer data){auto *r=static_cast<Response *>(data);GVariantBuilder results;g_variant_builder_init(&results,G_VARIANT_TYPE_VARDICT);
    if(r->code==0){const char *uris[]={r->uri.c_str(),nullptr};g_variant_builder_add(&results,"{sv}","uris",g_variant_new_strv(uris,-1));}
    g_dbus_connection_emit_signal(r->connection,r->sender.c_str(),r->path.c_str(),"org.freedesktop.portal.Request","Response",g_variant_new("(ua{sv})",r->code,&results),nullptr);
    g_object_unref(r->connection);delete r;return G_SOURCE_REMOVE;}
static void method(GDBusConnection *connection,const gchar *sender,const gchar *,const gchar *,const gchar *,GVariant *parameters,GDBusMethodInvocation *invocation,gpointer data){
    auto *p=static_cast<Portal *>(data);GVariant *options=g_variant_get_child_value(parameters,2);const char *token=nullptr;gboolean directory=false;
    if(!g_variant_lookup(options,"handle_token","&s",&token)){p->valid=false;g_dbus_method_invocation_return_dbus_error(invocation,"org.freedesktop.portal.Error.Failed","Missing token");g_variant_unref(options);return;}
    p->valid=p->valid&&g_variant_lookup(options,"directory","b",&directory)&&directory;
    GVariant *folder=g_variant_lookup_value(options,"current_folder",G_VARIANT_TYPE_BYTESTRING);
    p->valid=p->valid&&folder&&p->directory==g_variant_get_bytestring(folder);if(folder)g_variant_unref(folder);
    std::string unique=sender+1;for(char &c:unique)if(c=='.')c='_';std::string path="/org/freedesktop/portal/desktop/request/"+unique+"/"+token;
    auto *response=new Response{G_DBUS_CONNECTION(g_object_ref(connection)),sender,path,"",unsigned(p->requests++)};
    gchar *uri=g_filename_to_uri(p->chosen.c_str(),nullptr,nullptr);response->uri=uri;g_free(uri);
    g_variant_unref(options);g_dbus_method_invocation_return_value(invocation,g_variant_new("(o)",path.c_str()));g_timeout_add(25,respond,response);
}
static GVariant *property(GDBusConnection *,const gchar *,const gchar *,const gchar *,const gchar *,GError **,gpointer){return g_variant_new_uint32(4);}
int main(int argc,char **argv){if(argc!=2){std::fprintf(stderr,"Usage: portal-picker-check appui-library\n");return 2;}
    GError *error=nullptr;auto *bus=g_bus_get_sync(G_BUS_TYPE_SESSION,nullptr,&error);
    if(!bus){std::fprintf(stderr,"%s\n",error->message);g_error_free(error);return 1;}
    auto *reply=g_dbus_connection_call_sync(bus,"org.freedesktop.DBus","/org/freedesktop/DBus","org.freedesktop.DBus","RequestName",g_variant_new("(su)","org.freedesktop.portal.Desktop",0),G_VARIANT_TYPE("(u)"),G_DBUS_CALL_FLAGS_NONE,5000,nullptr,&error);
    if(!reply){std::fprintf(stderr,"%s\n",error->message);g_error_free(error);g_object_unref(bus);return 1;}g_variant_unref(reply);
    char *temporary=g_dir_make_tmp("imgui-picker-XXXXXX",&error);if(!temporary){g_object_unref(bus);return 1;}
    Portal portal{g_main_loop_new(nullptr,false),temporary,std::string(temporary)+"/photos café #1"};g_free(temporary);std::filesystem::create_directory(portal.chosen);
    auto *info=g_dbus_node_info_new_for_xml(xml,&error);GDBusInterfaceVTable table{method,property,nullptr,{nullptr}};
    guint registration=g_dbus_connection_register_object(bus,"/org/freedesktop/portal/desktop",info->interfaces[0],&table,&portal,nullptr,&error);
    if(!registration){std::fprintf(stderr,"%s\n",error->message);return 1;}
    int status=0;
    std::thread worker([&]{void *library=nullptr;try {
        library=dlopen(argv[1],RTLD_NOW);if(!library)throw std::runtime_error(dlerror());
        using Pick=const char *(*)(const char *,const char **);auto pick=reinterpret_cast<Pick>(dlsym(library,"vimgui_app_pick_folder"));if(!pick)throw std::runtime_error("Missing folder picker export");
        const char *failure=nullptr;const char *chosen=pick(portal.directory.c_str(),&failure);
        if(!chosen||portal.chosen!=chosen||failure)throw std::runtime_error("UTF-8 selection failed");
        if(pick(portal.directory.c_str(),&failure)||failure)throw std::runtime_error("Cancellation was reported as failure");
        if(pick(portal.directory.c_str(),&failure)||!failure)throw std::runtime_error("Portal failure was not reported");
    }catch(const std::exception &e){std::fprintf(stderr,"%s\n",e.what());status=1;}
        if(library)dlclose(library);g_main_loop_quit(portal.loop);
    });
    g_main_loop_run(portal.loop);worker.join();
    if(!portal.valid||portal.requests!=3){std::fprintf(stderr,"Directory/current-folder options incorrect\n");status=1;}
    g_dbus_connection_unregister_object(bus,registration);g_dbus_node_info_unref(info);g_object_unref(bus);g_main_loop_unref(portal.loop);std::filesystem::remove_all(portal.directory);
    if(!status)std::puts("PASS: native portal UTF-8 selection, initial folder, cancellation and errors");return status;
}
