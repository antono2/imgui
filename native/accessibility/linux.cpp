#include "platform.h"
#include <atk/atk.h>
#include <atk-bridge.h>
#include <algorithm>
#include <cstring>
struct LinuxState;
struct VimguiAccessible { AtkObject parent; std::shared_ptr<LinuxState> *state; uint64_t id; };
struct VimguiAccessibleClass { AtkObjectClass parent; };
struct LinuxState {vimgui_accessibility *context; AccessibilitySnapshot tree; std::unordered_map<uint64_t,AtkObject *> objects;bool bridge=false;};
static AtkObject *application_root=nullptr;
static void component_init(AtkComponentIface *);
static void action_init(AtkActionIface *);
static void text_init(AtkTextIface *);
static void editable_init(AtkEditableTextIface *);
static void value_init(AtkValueIface *);
static void selection_init(AtkSelectionIface *);
G_DEFINE_TYPE_WITH_CODE(VimguiAccessible,vimgui_accessible,ATK_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(ATK_TYPE_COMPONENT,component_init)
    G_IMPLEMENT_INTERFACE(ATK_TYPE_ACTION,action_init)
    G_IMPLEMENT_INTERFACE(ATK_TYPE_TEXT,text_init)
    G_IMPLEMENT_INTERFACE(ATK_TYPE_EDITABLE_TEXT,editable_init)
    G_IMPLEMENT_INTERFACE(ATK_TYPE_VALUE,value_init)
    G_IMPLEMENT_INTERFACE(ATK_TYPE_SELECTION,selection_init))
static VimguiAccessible *self(gpointer object){return reinterpret_cast<VimguiAccessible *>(object);}
static std::shared_ptr<const Node> node(gpointer object){auto *s=self(object);if(!s->state)return nullptr;auto &tree=(**s->state).tree;
    auto it=tree.nodes.find(s->id);return it==tree.nodes.end()?nullptr:it->second;}
static bool request(gpointer object,int action,std::string value={},size_t anchor=0,size_t focus=0){auto *s=self(object);
    if(!s->state || !(**s->state).context)return false;return accessibility_enqueue((**s->state).context,{s->id,action,std::move(value),anchor,focus});}
static const gchar *get_name(AtkObject *obj){auto n=node(obj);return n?n->label.c_str():self(obj)->id==0?"V ImGui application":"";}
static AtkRole get_role(AtkObject *obj){auto n=node(obj);if(!n)return self(obj)->id==0?ATK_ROLE_APPLICATION:ATK_ROLE_UNKNOWN;
    static const AtkRole roles[]={ATK_ROLE_FRAME,ATK_ROLE_PANEL,ATK_ROLE_PUSH_BUTTON,ATK_ROLE_CHECK_BOX,ATK_ROLE_RADIO_BUTTON,
        ATK_ROLE_ENTRY,ATK_ROLE_LABEL,ATK_ROLE_LIST_BOX,ATK_ROLE_LIST_ITEM,ATK_ROLE_PROGRESS_BAR,ATK_ROLE_DIALOG};return roles[n->role];}
static gint child_count(AtkObject *obj){auto *s=self(obj);if(!s->state)return 0;if(s->id==0)return (**s->state).tree.root?1:0;auto n=node(obj);return n?n->children.size():0;}
static AtkObject *ref_child(AtkObject *obj,gint index){auto *s=self(obj);if(!s->state || index<0 || index>=child_count(obj))return nullptr;
    uint64_t id=s->id==0?(**s->state).tree.root:node(obj)->children[index];auto &objects=(**s->state).objects;
    auto it=objects.find(id);return it==objects.end()?nullptr:ATK_OBJECT(g_object_ref(it->second));}
static AtkObject *get_parent(AtkObject *obj){auto *s=self(obj);if(!s->state || s->id==0)return nullptr;
    auto &state=**s->state;auto parent=accessibility_parent(state.tree,s->id);auto it=state.objects.find(parent);return it==state.objects.end()?nullptr:it->second;}
static gint index_in_parent(AtkObject *obj){auto *parent=get_parent(obj);if(!parent)return -1;for(int i=0;i<child_count(parent);++i){auto *child=ref_child(parent,i);bool match=child==obj;if(child)g_object_unref(child);if(match)return i;}return -1;}
static AtkStateSet *ref_states(AtkObject *obj){auto *states=atk_state_set_new();auto *s=self(obj);auto n=node(obj);
    if(!s->state || !(**s->state).context || (!n && s->id!=0)){atk_state_set_add_state(states,ATK_STATE_DEFUNCT);return states;}
    atk_state_set_add_state(states,ATK_STATE_VISIBLE);atk_state_set_add_state(states,ATK_STATE_SHOWING);
    if(!n || !(n->flags&VIMGUI_AX_DISABLED)){atk_state_set_add_state(states,ATK_STATE_ENABLED);atk_state_set_add_state(states,ATK_STATE_SENSITIVE);}
    if(n){if(n->actions&VIMGUI_AX_FOCUS)atk_state_set_add_state(states,ATK_STATE_FOCUSABLE);
        if((**s->state).tree.focus==n->id && (**s->state).tree.focused)atk_state_set_add_state(states,ATK_STATE_FOCUSED);
        if(n->flags&VIMGUI_AX_CHECKED)atk_state_set_add_state(states,ATK_STATE_CHECKED);
        if(n->flags&VIMGUI_AX_SELECTED)atk_state_set_add_state(states,ATK_STATE_SELECTED);
        if(n->flags&VIMGUI_AX_INDETERMINATE)atk_state_set_add_state(states,ATK_STATE_INDETERMINATE);
        if(n->role==VIMGUI_AX_LIST_ITEM)atk_state_set_add_state(states,ATK_STATE_SELECTABLE);
        if(n->role==VIMGUI_AX_TEXT_INPUT && !(n->flags&VIMGUI_AX_READ_ONLY))atk_state_set_add_state(states,ATK_STATE_EDITABLE);}
    return states;}
static AtkAttributeSet *attributes(AtkObject *obj){auto n=node(obj);AtkAttributeSet *list=nullptr;if(!n)return list;
    auto add=[&](const char *key,const std::string &value){auto *item=g_new0(AtkAttribute,1);item->name=g_strdup(key);item->value=g_strdup(value.c_str());list=g_slist_prepend(list,item);};
    if(n->flags&VIMGUI_AX_LIVE){add("live","polite");add("container-live","polite");}
    if(n->size_of_set){add("setsize",std::to_string(n->size_of_set));add("posinset",std::to_string(n->position_in_set));}return list;}
static void finalize(GObject *object){delete self(object)->state;G_OBJECT_CLASS(vimgui_accessible_parent_class)->finalize(object);}
static void vimgui_accessible_class_init(VimguiAccessibleClass *klass){auto *object=ATK_OBJECT_CLASS(klass);object->get_name=get_name;object->get_role=get_role;
    object->get_n_children=child_count;object->ref_child=ref_child;object->get_parent=get_parent;object->get_index_in_parent=index_in_parent;object->ref_state_set=ref_states;object->get_attributes=attributes;
    G_OBJECT_CLASS(klass)->finalize=finalize;}
static void vimgui_accessible_init(VimguiAccessible *object){object->state=nullptr;object->id=0;}
static void extents(AtkComponent *obj,gint *x,gint *y,gint *w,gint *h,AtkCoordType type){auto *s=self(obj);auto n=node(obj);*x=*y=*w=*h=0;if(!s->state || !n)return;
    auto bounds=accessibility_bounds((**s->state).tree,*n);*x=bounds.x;*y=bounds.y;*w=bounds.width;*h=bounds.height;
    if(type==ATK_XY_SCREEN){*x+=(**s->state).tree.x;*y+=(**s->state).tree.y;}}
static gboolean grab_focus(AtkComponent *obj){return request(obj,VIMGUI_AX_FOCUS);}
static gboolean scroll_to(AtkComponent *obj,AtkScrollType){return request(obj,VIMGUI_AX_SCROLL_INTO_VIEW);}
static gboolean contains(AtkComponent *obj,gint x,gint y,AtkCoordType type){int a,b,w,h;extents(obj,&a,&b,&w,&h,type);return x>=a && y>=b && x<a+w && y<b+h;}
static AtkObject *at_point(AtkComponent *obj,gint x,gint y,AtkCoordType type){if(!contains(obj,x,y,type))return nullptr;
    for(int i=child_count(ATK_OBJECT(obj))-1;i>=0;--i){AtkObject *child=ref_child(ATK_OBJECT(obj),i);
        if(child && contains(ATK_COMPONENT(child),x,y,type))return child;if(child)g_object_unref(child);}return nullptr;}
static void component_init(AtkComponentIface *iface){iface->get_extents=extents;iface->grab_focus=grab_focus;iface->scroll_to=scroll_to;iface->contains=contains;iface->ref_accessible_at_point=at_point;}
static std::vector<int> actions(gpointer obj){auto n=node(obj);std::vector<int> result;if(n)for(int action:{VIMGUI_AX_CLICK,VIMGUI_AX_FOCUS,VIMGUI_AX_SCROLL_INTO_VIEW,VIMGUI_AX_SCROLL_UP,VIMGUI_AX_SCROLL_DOWN})if(n->actions&action)result.push_back(action);return result;}
static const gchar *action_name(AtkAction *obj,gint index){auto list=actions(obj);if(index<0||index>=int(list.size()))return "";
    switch(list[index]){case VIMGUI_AX_CLICK:return "click";case VIMGUI_AX_FOCUS:return "focus";case VIMGUI_AX_SCROLL_INTO_VIEW:return "show";case VIMGUI_AX_SCROLL_UP:return "scroll-up";default:return "scroll-down";}}
static gboolean do_action(AtkAction *obj,gint index){auto list=actions(obj);return index>=0&&index<int(list.size())&&request(obj,list[index]);}
static gint action_count(AtkAction *obj){return actions(obj).size();}
static const gchar *empty_action(AtkAction *,gint){return "";}
static void action_init(AtkActionIface *iface){iface->get_n_actions=action_count;iface->get_name=action_name;iface->get_localized_name=action_name;iface->do_action=do_action;iface->get_description=empty_action;iface->get_keybinding=empty_action;}
static std::string text_value(gpointer obj){auto n=node(obj);return !n?"":n->role==VIMGUI_AX_LABEL?n->label:n->value;}
static gint text_count(AtkText *obj){auto text=text_value(obj);return g_utf8_strlen(text.c_str(),text.size());}
static gchar *get_text(AtkText *obj,gint start,gint end){auto text=text_value(obj);int count=text_count(obj);start=std::clamp(start,0,count);end=end<0?count:std::clamp(end,start,count);return g_utf8_substring(text.c_str(),start,end);}
static gunichar character(AtkText *obj,gint offset){auto text=text_value(obj);return offset>=0&&offset<text_count(obj)?g_utf8_get_char(g_utf8_offset_to_pointer(text.c_str(),offset)):0;}
static gint caret(AtkText *obj){auto n=node(obj);return n?n->text_focus:0;}
static gboolean set_caret(AtkText *obj,gint offset){return offset>=0&&offset<=text_count(obj)&&request(obj,VIMGUI_AX_SET_SELECTION,{},offset,offset);}
static gint selections(AtkText *obj){auto n=node(obj);return n&&n->text_anchor!=n->text_focus?1:0;}
static gchar *get_selection(AtkText *obj,gint index,gint *start,gint *end){auto n=node(obj);if(!n||index!=0||!selections(obj))return nullptr;*start=std::min(n->text_anchor,n->text_focus);*end=std::max(n->text_anchor,n->text_focus);return get_text(obj,*start,*end);}
static gboolean set_selection(AtkText *obj,gint index,gint start,gint end){return index==0&&start>=0&&end>=0&&start<=text_count(obj)&&end<=text_count(obj)&&request(obj,VIMGUI_AX_SET_SELECTION,{},start,end);}
static gboolean add_selection(AtkText *obj,gint start,gint end){return set_selection(obj,0,start,end);}
static gboolean remove_selection(AtkText *obj,gint index){return index==0&&set_caret(obj,caret(obj));}
static gchar *segment(AtkText *obj,gint offset,AtkTextGranularity granularity,gint *start,gint *end){
    const int count=text_count(obj);if(offset<0||offset>count){*start=*end=-1;return nullptr;}
    *start=offset;*end=std::min(offset+1,count);
    if(granularity==ATK_TEXT_GRANULARITY_WORD){
        auto word=[](gunichar c){return g_unichar_isalnum(c)||g_unichar_ismark(c)||c=='_';};
        bool kind=offset<count&&word(character(obj,offset));
        while(*start>0&&word(character(obj,*start-1))==kind)--*start;
        while(*end<count&&word(character(obj,*end))==kind)++*end;
    }else if(granularity==ATK_TEXT_GRANULARITY_LINE||granularity==ATK_TEXT_GRANULARITY_PARAGRAPH){
        while(*start>0&&character(obj,*start-1)!='\n')--*start;
        while(*end<count&&character(obj,*end-1)!='\n')++*end;
    }else if(granularity==ATK_TEXT_GRANULARITY_SENTENCE){
        auto stop=[](gunichar c){return c=='.'||c=='!'||c=='?'||c=='\n';};
        while(*start>0&&!stop(character(obj,*start-1)))--*start;
        while(*end<count&&!stop(character(obj,*end-1)))++*end;
    }
    return get_text(obj,*start,*end);
}
static gchar *boundary_segment(AtkText *obj,gint offset,AtkTextBoundary boundary,gint *start,gint *end){
    AtkTextGranularity granularity=boundary==ATK_TEXT_BOUNDARY_CHAR?ATK_TEXT_GRANULARITY_CHAR:
        boundary==ATK_TEXT_BOUNDARY_WORD_START||boundary==ATK_TEXT_BOUNDARY_WORD_END?ATK_TEXT_GRANULARITY_WORD:
        boundary==ATK_TEXT_BOUNDARY_SENTENCE_START||boundary==ATK_TEXT_BOUNDARY_SENTENCE_END?ATK_TEXT_GRANULARITY_SENTENCE:ATK_TEXT_GRANULARITY_LINE;
    return segment(obj,offset,granularity,start,end);
}
static gchar *before_segment(AtkText *obj,gint offset,AtkTextBoundary boundary,gint *start,gint *end){auto *value=boundary_segment(obj,offset,boundary,start,end);g_free(value);return boundary_segment(obj,*start-1,boundary,start,end);}
static gchar *after_segment(AtkText *obj,gint offset,AtkTextBoundary boundary,gint *start,gint *end){auto *value=boundary_segment(obj,offset,boundary,start,end);g_free(value);return boundary_segment(obj,*end,boundary,start,end);}
static void text_init(AtkTextIface *iface){iface->get_text=get_text;iface->get_character_at_offset=character;iface->get_character_count=text_count;iface->get_caret_offset=caret;iface->set_caret_offset=set_caret;
    iface->get_string_at_offset=segment;iface->get_text_at_offset=boundary_segment;iface->get_text_before_offset=before_segment;iface->get_text_after_offset=after_segment;
    iface->get_n_selections=selections;iface->get_selection=get_selection;iface->add_selection=add_selection;iface->set_selection=set_selection;iface->remove_selection=remove_selection;}
static void set_contents(AtkEditableText *obj,const gchar *value){request(obj,VIMGUI_AX_SET_VALUE,value?value:"");}
static void insert_text(AtkEditableText *obj,const gchar *input,gint length,gint *position){auto text=text_value(obj);int offset=std::clamp(*position,0,int(g_utf8_strlen(text.c_str(),text.size())));
    size_t byte=g_utf8_offset_to_pointer(text.c_str(),offset)-text.c_str();text.insert(byte,input,length<0?std::strlen(input):size_t(length));request(obj,VIMGUI_AX_SET_VALUE,text);*position=offset+g_utf8_strlen(input,length);}
static void delete_text(AtkEditableText *obj,gint start,gint end){auto text=text_value(obj);int count=g_utf8_strlen(text.c_str(),text.size());start=std::clamp(start,0,count);end=std::clamp(end,start,count);
    size_t first=g_utf8_offset_to_pointer(text.c_str(),start)-text.c_str(),last=g_utf8_offset_to_pointer(text.c_str(),end)-text.c_str();text.erase(first,last-first);request(obj,VIMGUI_AX_SET_VALUE,text);}
static void editable_init(AtkEditableTextIface *iface){iface->set_text_contents=set_contents;iface->insert_text=insert_text;iface->delete_text=delete_text;}
static void current_value(AtkValue *obj,GValue *out){auto n=node(obj);g_value_init(out,G_TYPE_DOUBLE);g_value_set_double(out,n?n->numeric_value:0);}
static void min_value(AtkValue *obj,GValue *out){auto n=node(obj);g_value_init(out,G_TYPE_DOUBLE);g_value_set_double(out,n?n->numeric_min:0);}
static void max_value(AtkValue *obj,GValue *out){auto n=node(obj);g_value_init(out,G_TYPE_DOUBLE);g_value_set_double(out,n?n->numeric_max:0);}
static void value_text(AtkValue *obj,gdouble *value,gchar **text){auto n=node(obj);*value=n?n->numeric_value:0;*text=g_strdup(n?n->value.c_str():"");}
static AtkRange *get_range(AtkValue *obj){auto n=node(obj);return n&&n->role==VIMGUI_AX_PROGRESS&&!(n->flags&VIMGUI_AX_INDETERMINATE)?atk_range_new(n->numeric_min,n->numeric_max,n->label.c_str()):nullptr;}
static void value_init(AtkValueIface *iface){iface->get_current_value=current_value;iface->get_minimum_value=min_value;iface->get_maximum_value=max_value;iface->get_value_and_text=value_text;iface->get_range=get_range;}
static gint selected_count(AtkSelection *obj){auto *s=self(obj);auto n=node(obj);int count=0;if(n)for(auto id:n->children){auto it=(**s->state).tree.nodes.find(id);if(it!=(**s->state).tree.nodes.end()&&(it->second->flags&VIMGUI_AX_SELECTED))++count;}return count;}
static gboolean is_selected(AtkSelection *obj,gint index){auto *child=ref_child(ATK_OBJECT(obj),index);if(!child)return false;auto n=node(child);bool selected=n&&(n->flags&VIMGUI_AX_SELECTED);g_object_unref(child);return selected;}
static AtkObject *ref_selected(AtkSelection *obj,gint index){for(int i=0;i<child_count(ATK_OBJECT(obj));++i)if(is_selected(obj,i)&&index--==0)return ref_child(ATK_OBJECT(obj),i);return nullptr;}
static gboolean select_child(AtkSelection *obj,gint index){auto *child=ref_child(ATK_OBJECT(obj),index);if(!child)return false;bool accepted=request(child,VIMGUI_AX_CLICK);g_object_unref(child);return accepted;}
static void selection_init(AtkSelectionIface *iface){iface->get_selection_count=selected_count;iface->is_child_selected=is_selected;iface->ref_selection=ref_selected;iface->add_selection=select_child;}
static AtkObject *get_root(){return application_root;}
static const gchar *toolkit_name(){return "V ImGui";}
static const gchar *toolkit_version(){return "1.0";}
static AtkObject *make_object(const std::shared_ptr<LinuxState> &state,uint64_t id){auto *object=self(g_object_new(vimgui_accessible_get_type(),nullptr));object->state=new std::shared_ptr<LinuxState>(state);object->id=id;return ATK_OBJECT(object);}
void *accessibility_platform_attach(vimgui_accessibility *ctx,void *,void *){
    if(application_root)return nullptr;
    auto state=std::make_shared<LinuxState>();state->context=ctx;state->tree=accessibility_snapshot(ctx);
    state->objects[0]=make_object(state,0);for(const auto &entry:state->tree.nodes)state->objects[entry.first]=make_object(state,entry.first);
    application_root=state->objects.at(0);auto *util=ATK_UTIL_CLASS(g_type_class_ref(ATK_TYPE_UTIL));util->get_root=get_root;util->get_toolkit_name=toolkit_name;util->get_toolkit_version=toolkit_version;
    // Desktops without the OS accessibility bus can still render the UI.
    state->bridge=atk_bridge_adaptor_init(nullptr,nullptr)==0;
    return new std::shared_ptr<LinuxState>(state);
}
void accessibility_platform_detach(void *adapter){auto &state=*static_cast<std::shared_ptr<LinuxState> *>(adapter);state->context=nullptr;if(state->bridge)atk_bridge_adaptor_cleanup();application_root=nullptr;
    for(auto &entry:state->objects)g_object_unref(entry.second);state->objects.clear();delete static_cast<std::shared_ptr<LinuxState> *>(adapter);}
void accessibility_platform_update(void *adapter){auto state=*static_cast<std::shared_ptr<LinuxState> *>(adapter);auto tree=accessibility_snapshot(state->context);
    if(tree.revision!=state->tree.revision){auto previous=state->tree;state->tree=tree;
        // Materialize every object before publishing changed child arrays.
        for(const auto &entry:tree.nodes)if(!state->objects.count(entry.first))state->objects[entry.first]=make_object(state,entry.first);
        for(const auto &entry:tree.nodes){AtkObject *object=state->objects.at(entry.first);
            auto old=previous.nodes.find(entry.first);if(old!=previous.nodes.end()){
                if(old->second->label!=entry.second->label)g_object_notify(G_OBJECT(object),"accessible-name");
                if((old->second->flags^entry.second->flags)&VIMGUI_AX_CHECKED)atk_object_notify_state_change(object,ATK_STATE_CHECKED,(entry.second->flags&VIMGUI_AX_CHECKED)!=0);
                if((old->second->flags^entry.second->flags)&VIMGUI_AX_SELECTED)atk_object_notify_state_change(object,ATK_STATE_SELECTED,(entry.second->flags&VIMGUI_AX_SELECTED)!=0);
                if(old->second->text_anchor!=entry.second->text_anchor || old->second->text_focus!=entry.second->text_focus){g_signal_emit_by_name(object,"text-selection-changed");g_signal_emit_by_name(object,"text-caret-moved",int(entry.second->text_focus));}
                if(old->second->value!=entry.second->value){g_signal_emit_by_name(object,"text-changed::delete",0,int(g_utf8_strlen(old->second->value.c_str(),-1)));g_signal_emit_by_name(object,"text-changed::insert",0,int(g_utf8_strlen(entry.second->value.c_str(),-1)));g_signal_emit_by_name(object,"visible-data-changed");}}
            if(tree.focus!=previous.focus && tree.focus==entry.first)atk_object_notify_state_change(object,ATK_STATE_FOCUSED,tree.focused);
            const std::vector<uint64_t> empty;
            const auto &oldChildren=old==previous.nodes.end()?empty:old->second->children;
            const auto &newChildren=entry.second->children;
            for(size_t i=0;i<oldChildren.size();++i)if(std::find(newChildren.begin(),newChildren.end(),oldChildren[i])==newChildren.end()) {
                auto child=state->objects.find(oldChildren[i]);
                if(child!=state->objects.end())g_signal_emit_by_name(object,"children-changed::remove",int(i),child->second,nullptr);
            }
            for(size_t i=0;i<newChildren.size();++i)if(std::find(oldChildren.begin(),oldChildren.end(),newChildren[i])==oldChildren.end())
                g_signal_emit_by_name(object,"children-changed::add",int(i),state->objects.at(newChildren[i]),nullptr);
        }
        // Keep removed objects alive while native clients hold references, but
        // they read as defunct and cannot enqueue actions against a new node.
        for(auto it=state->objects.begin();it!=state->objects.end();){if(it->first && !tree.nodes.count(it->first)){g_object_unref(it->second);it=state->objects.erase(it);}else ++it;}
    }
    while(g_main_context_pending(nullptr))g_main_context_iteration(nullptr,false);
}
void accessibility_platform_window(void *adapter){auto state=*static_cast<std::shared_ptr<LinuxState> *>(adapter);auto tree=accessibility_snapshot(state->context);bool changed=tree.focused!=state->tree.focused;
    state->tree.focused=tree.focused;state->tree.x=tree.x;state->tree.y=tree.y;state->tree.width=tree.width;state->tree.height=tree.height;
    if(changed){auto found=state->objects.find(tree.focus);if(found!=state->objects.end())atk_object_notify_state_change(found->second,ATK_STATE_FOCUSED,tree.focused);}}
