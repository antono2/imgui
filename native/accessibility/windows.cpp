#define NOMINMAX
#include "platform.h"
#include <windows.h>
#include <commctrl.h>
#include <UIAutomation.h>
#include <algorithm>
#include <cmath>
#include <cwctype>
struct WindowsState {std::mutex mutex;vimgui_accessibility *context;HWND window;AccessibilitySnapshot previous;};
static std::wstring wide(const std::string &value){int length=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,value.data(),int(value.size()),nullptr,0);
    std::wstring result(length,L'\0');if(length)MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,value.data(),int(value.size()),result.data(),length);return result;}
static std::string utf8(const std::wstring &value){int length=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,value.data(),int(value.size()),nullptr,0,nullptr,nullptr);
    std::string result(length,'\0');if(length)WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,value.data(),int(value.size()),result.data(),length,nullptr,nullptr);return result;}
static AccessibilitySnapshot snapshot(const std::shared_ptr<WindowsState> &state){std::lock_guard<std::mutex> lock(state->mutex);return state->context?accessibility_snapshot(state->context):AccessibilitySnapshot{};}
static bool enqueue(const std::shared_ptr<WindowsState> &state,Event event){std::lock_guard<std::mutex> lock(state->mutex);return state->context&&accessibility_enqueue(state->context,std::move(event));}
static std::shared_ptr<const Node> find_node(const std::shared_ptr<WindowsState> &state,uint64_t id){auto tree=snapshot(state);auto found=tree.nodes.find(id);return found==tree.nodes.end()?nullptr:found->second;}
static UiaRect rectangle(const AccessibilitySnapshot &tree,const Node &n){auto bounds=accessibility_bounds(tree,n);return {tree.x+bounds.x,tree.y+bounds.y,bounds.width,bounds.height};}
static bool visible(const AccessibilitySnapshot &tree,const Node &n){auto bounds=accessibility_bounds(tree,n);double left=std::max(0.0,bounds.x),top=std::max(0.0,bounds.y),right=std::min(tree.width,bounds.x+bounds.width),bottom=std::min(tree.height,bounds.y+bounds.height);
    for(auto parent=accessibility_parent(tree,n.id);parent;parent=accessibility_parent(tree,parent)){auto ancestor=tree.nodes.at(parent);if(ancestor->role!=VIMGUI_AX_LIST)continue;auto clip=accessibility_bounds(tree,*ancestor);left=std::max(left,clip.x);top=std::max(top,clip.y);right=std::min(right,clip.x+clip.width);bottom=std::min(bottom,clip.y+clip.height);}return right>left&&bottom>top;}
static SAFEARRAY *array_of(IUnknown *value){auto *array=SafeArrayCreateVectorEx(VT_UNKNOWN,0,value?1:0,const_cast<IID *>(&__uuidof(ITextRangeProvider)));if(value){LONG index=0;SafeArrayPutElement(array,&index,value);}return array;}
class Provider;
static IRawElementProviderSimple *simple(const std::shared_ptr<WindowsState> &,uint64_t);
static IRawElementProviderFragment *fragment(const std::shared_ptr<WindowsState> &,uint64_t);
static int utf16_offset(const std::wstring &text,size_t points){size_t offset=0;while(offset<text.size()&&points--){if(text[offset]>=0xd800&&text[offset]<=0xdbff&&offset+1<text.size()&&text[offset+1]>=0xdc00&&text[offset+1]<=0xdfff)++offset;++offset;}return int(offset);}
static size_t point_offset(const std::wstring &text,int units){size_t points=0;for(int i=0;i<std::min(units,int(text.size()));++i){if(text[i]>=0xd800&&text[i]<=0xdbff&&i+1<units&&text[i+1]>=0xdc00&&text[i+1]<=0xdfff)++i;++points;}return points;}
class TextRange final:public ITextRangeProvider {
    std::atomic<ULONG> references{1};std::shared_ptr<WindowsState> state;uint64_t id;int start,end;
    std::wstring text()const{auto n=find_node(state,id);return n?wide(n->value):L"";}
    void clamp(){auto value=text();start=std::clamp(start,0,int(value.size()));end=std::clamp(end,start,int(value.size()));}
    std::vector<int> boundaries(TextUnit unit)const{auto value=text();std::vector<int> result{0};if(unit==TextUnit_Document||unit==TextUnit_Page||unit==TextUnit_Paragraph||unit==TextUnit_Line){result.push_back(int(value.size()));return result;}
        for(int i=0;i<int(value.size());){int next=utf16_offset(value,point_offset(value,i)+1);if(unit==TextUnit_Character || next==int(value.size()) || !!std::iswspace(value[i])!=!!std::iswspace(value[next]))result.push_back(next);i=next;}
        return result;}
public:
    TextRange(std::shared_ptr<WindowsState> s,uint64_t node,int a,int b):state(std::move(s)),id(node),start(a),end(b){clamp();}
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid,void **out)override{if(!out)return E_POINTER;*out=nullptr;if(iid==__uuidof(IUnknown)||iid==__uuidof(ITextRangeProvider))*out=static_cast<ITextRangeProvider *>(this);else return E_NOINTERFACE;AddRef();return S_OK;}
    ULONG STDMETHODCALLTYPE AddRef()override{return ++references;}ULONG STDMETHODCALLTYPE Release()override{ULONG count=--references;if(!count)delete this;return count;}
    HRESULT STDMETHODCALLTYPE Clone(ITextRangeProvider **out)override{if(!out)return E_POINTER;*out=new TextRange(state,id,start,end);return S_OK;}
    HRESULT STDMETHODCALLTYPE Compare(ITextRangeProvider *other,BOOL *out)override{if(!out)return E_POINTER;auto *range=dynamic_cast<TextRange *>(other);*out=range&&range->state==state&&range->id==id&&range->start==start&&range->end==end;return S_OK;}
    HRESULT STDMETHODCALLTYPE CompareEndpoints(TextPatternRangeEndpoint endpoint,ITextRangeProvider *other,TextPatternRangeEndpoint target,int *out)override{if(!out)return E_POINTER;auto *range=dynamic_cast<TextRange *>(other);if(!range||range->state!=state||range->id!=id)return E_INVALIDARG;*out=(endpoint==TextPatternRangeEndpoint_Start?start:end)-(target==TextPatternRangeEndpoint_Start?range->start:range->end);return S_OK;}
    HRESULT STDMETHODCALLTYPE ExpandToEnclosingUnit(TextUnit unit)override{clamp();auto breaks=boundaries(unit);auto found=std::upper_bound(breaks.begin(),breaks.end(),start);if(found==breaks.begin())return S_OK;if(found==breaks.end()){start=breaks.size()>1?breaks[breaks.size()-2]:0;end=breaks.back();}else{end=*found;start=*(found-1);}return S_OK;}
    HRESULT STDMETHODCALLTYPE FindAttribute(TEXTATTRIBUTEID attribute,VARIANT value,BOOL,ITextRangeProvider **out)override{if(!out)return E_POINTER;*out=nullptr;VARIANT actual;VariantInit(&actual);HRESULT status=GetAttributeValue(attribute,&actual);
        if(SUCCEEDED(status)&&actual.vt==value.vt&&actual.vt==VT_BOOL&&actual.boolVal==value.boolVal)*out=new TextRange(state,id,start,end);VariantClear(&actual);return status;}
    HRESULT STDMETHODCALLTYPE FindText(BSTR requested,BOOL backward,BOOL ignoreCase,ITextRangeProvider **out)override{if(!out)return E_POINTER;*out=nullptr;if(!requested)return E_INVALIDARG;auto value=text().substr(start,end-start);std::wstring needle(requested,SysStringLen(requested));
        if(ignoreCase){std::transform(value.begin(),value.end(),value.begin(),std::towupper);std::transform(needle.begin(),needle.end(),needle.begin(),std::towupper);}auto position=backward?value.rfind(needle):value.find(needle);if(position!=std::wstring::npos)*out=new TextRange(state,id,start+int(position),start+int(position+needle.size()));return S_OK;}
    HRESULT STDMETHODCALLTYPE GetAttributeValue(TEXTATTRIBUTEID attribute,VARIANT *out)override{if(!out)return E_POINTER;VariantInit(out);auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;
        if(attribute==UIA_IsReadOnlyAttributeId){out->vt=VT_BOOL;out->boolVal=(n->flags&VIMGUI_AX_READ_ONLY)?VARIANT_TRUE:VARIANT_FALSE;return S_OK;}out->vt=VT_UNKNOWN;return UiaGetReservedNotSupportedValue(&out->punkVal);}
    HRESULT STDMETHODCALLTYPE GetBoundingRectangles(SAFEARRAY **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;
        auto bounds=rectangle(tree,*found->second);*out=SafeArrayCreateVector(VT_R8,0,visible(tree,*found->second)?4:0);double values[]={bounds.left,bounds.top,bounds.width,bounds.height};if(visible(tree,*found->second))for(LONG i=0;i<4;i++)SafeArrayPutElement(*out,&i,&values[i]);return S_OK;}
    HRESULT STDMETHODCALLTYPE GetEnclosingElement(IRawElementProviderSimple **out)override{if(!out)return E_POINTER;*out=simple(state,id);return *out?S_OK:UIA_E_ELEMENTNOTAVAILABLE;}
    HRESULT STDMETHODCALLTYPE GetText(int maximum,BSTR *out)override{if(!out)return E_POINTER;clamp();auto value=text().substr(start,end-start);if(maximum>=0&&value.size()>size_t(maximum)){value.resize(maximum);if(!value.empty()&&value.back()>=0xd800&&value.back()<=0xdbff)value.pop_back();}*out=SysAllocStringLen(value.data(),UINT(value.size()));return *out?S_OK:E_OUTOFMEMORY;}
    HRESULT STDMETHODCALLTYPE Move(TextUnit unit,int count,int *moved)override{if(!moved)return E_POINTER;clamp();auto breaks=boundaries(unit);auto found=std::upper_bound(breaks.begin(),breaks.end(),start);bool collapsed=start==end;int index=std::max(0,int(found-breaks.begin())-1),limit=std::max(0,int(breaks.size())-(collapsed?1:2));int next=std::clamp(index+count,0,limit);*moved=next-index;start=breaks[next];end=collapsed?start:breaks[next+1];return S_OK;}
    HRESULT STDMETHODCALLTYPE MoveEndpointByUnit(TextPatternRangeEndpoint endpoint,TextUnit unit,int count,int *moved)override{if(!moved)return E_POINTER;clamp();auto breaks=boundaries(unit);int value=endpoint==TextPatternRangeEndpoint_Start?start:end;
        int index=int(std::lower_bound(breaks.begin(),breaks.end(),value)-breaks.begin()),next=std::clamp(index+count,0,int(breaks.size())-1);*moved=next-index;if(endpoint==TextPatternRangeEndpoint_Start){start=breaks[next];if(start>end)end=start;}else{end=breaks[next];if(end<start)start=end;}return S_OK;}
    HRESULT STDMETHODCALLTYPE MoveEndpointByRange(TextPatternRangeEndpoint endpoint,ITextRangeProvider *other,TextPatternRangeEndpoint target)override{auto *range=dynamic_cast<TextRange *>(other);if(!range||range->state!=state||range->id!=id)return E_INVALIDARG;int value=target==TextPatternRangeEndpoint_Start?range->start:range->end;
        if(endpoint==TextPatternRangeEndpoint_Start){start=value;if(start>end)end=start;}else{end=value;if(end<start)start=end;}return S_OK;}
    HRESULT STDMETHODCALLTYPE Select()override{clamp();auto value=text();enqueue(state,{id,VIMGUI_AX_FOCUS});return enqueue(state,{id,VIMGUI_AX_SET_SELECTION,{},point_offset(value,start),point_offset(value,end)})?S_OK:UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE AddToSelection()override{return Select();}
    HRESULT STDMETHODCALLTYPE RemoveFromSelection()override{auto value=text();return enqueue(state,{id,VIMGUI_AX_SET_SELECTION,{},point_offset(value,end),point_offset(value,end)})?S_OK:UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE ScrollIntoView(BOOL)override{return enqueue(state,{id,VIMGUI_AX_SCROLL_INTO_VIEW})?S_OK:UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE GetChildren(SAFEARRAY **out)override{if(!out)return E_POINTER;*out=array_of(nullptr);return S_OK;}
};
class Provider final:public IRawElementProviderSimple,public IRawElementProviderFragment,public IRawElementProviderFragmentRoot,public IInvokeProvider,
    public IToggleProvider,public IValueProvider,public IRangeValueProvider,public ISelectionItemProvider,public ISelectionProvider,
    public IScrollItemProvider,public IScrollProvider,public ITextProvider {
    std::atomic<ULONG> references{1};std::shared_ptr<WindowsState> state;uint64_t id;
public:
    Provider(std::shared_ptr<WindowsState> s,uint64_t n):state(std::move(s)),id(n){}
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid,void **out)override{if(!out)return E_POINTER;*out=nullptr;
        if(iid==__uuidof(IUnknown)||iid==__uuidof(IRawElementProviderSimple))*out=static_cast<IRawElementProviderSimple *>(this);
        else if(iid==__uuidof(IRawElementProviderFragment))*out=static_cast<IRawElementProviderFragment *>(this);
        else if(iid==__uuidof(IRawElementProviderFragmentRoot))*out=static_cast<IRawElementProviderFragmentRoot *>(this);
        else if(iid==__uuidof(IInvokeProvider))*out=static_cast<IInvokeProvider *>(this);
        else if(iid==__uuidof(IToggleProvider))*out=static_cast<IToggleProvider *>(this);
        else if(iid==__uuidof(IValueProvider))*out=static_cast<IValueProvider *>(this);
        else if(iid==__uuidof(IRangeValueProvider))*out=static_cast<IRangeValueProvider *>(this);
        else if(iid==__uuidof(ISelectionItemProvider))*out=static_cast<ISelectionItemProvider *>(this);
        else if(iid==__uuidof(ISelectionProvider))*out=static_cast<ISelectionProvider *>(this);
        else if(iid==__uuidof(IScrollItemProvider))*out=static_cast<IScrollItemProvider *>(this);
        else if(iid==__uuidof(IScrollProvider))*out=static_cast<IScrollProvider *>(this);
        else if(iid==__uuidof(ITextProvider))*out=static_cast<ITextProvider *>(this);
        else return E_NOINTERFACE;AddRef();return S_OK;}
    ULONG STDMETHODCALLTYPE AddRef()override{return ++references;}ULONG STDMETHODCALLTYPE Release()override{ULONG count=--references;if(!count)delete this;return count;}
    HRESULT STDMETHODCALLTYPE get_ProviderOptions(ProviderOptions *out)override{if(!out)return E_POINTER;*out=ProviderOptions_ServerSideProvider;return S_OK;}
    HRESULT STDMETHODCALLTYPE GetPatternProvider(PATTERNID pattern,IUnknown **out)override{if(!out)return E_POINTER;*out=nullptr;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;
        if(pattern==UIA_InvokePatternId && (n->actions&VIMGUI_AX_CLICK) && n->role!=VIMGUI_AX_CHECKBOX&&n->role!=VIMGUI_AX_RADIO)*out=static_cast<IInvokeProvider *>(this);
        if(pattern==UIA_TogglePatternId && n->role==VIMGUI_AX_CHECKBOX)*out=static_cast<IToggleProvider *>(this);
        if(pattern==UIA_ValuePatternId && n->role==VIMGUI_AX_TEXT_INPUT)*out=static_cast<IValueProvider *>(this);
        if(pattern==UIA_TextPatternId && n->role==VIMGUI_AX_TEXT_INPUT)*out=static_cast<ITextProvider *>(this);
        if(pattern==UIA_RangeValuePatternId && n->role==VIMGUI_AX_PROGRESS && !(n->flags&VIMGUI_AX_INDETERMINATE))*out=static_cast<IRangeValueProvider *>(this);
        if(pattern==UIA_SelectionItemPatternId && (n->role==VIMGUI_AX_LIST_ITEM||n->role==VIMGUI_AX_RADIO))*out=static_cast<ISelectionItemProvider *>(this);
        if(pattern==UIA_SelectionPatternId && n->role==VIMGUI_AX_LIST)*out=static_cast<ISelectionProvider *>(this);
        if(pattern==UIA_ScrollItemPatternId && (n->actions&VIMGUI_AX_SCROLL_INTO_VIEW))*out=static_cast<IScrollItemProvider *>(this);
        if(pattern==UIA_ScrollPatternId && n->scroll_y_max>0)*out=static_cast<IScrollProvider *>(this);
        if(*out)(*out)->AddRef();return S_OK;}
    HRESULT STDMETHODCALLTYPE GetPropertyValue(PROPERTYID property,VARIANT *out)override{if(!out)return E_POINTER;VariantInit(out);auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;const auto &n=*found->second;
        if(property==UIA_NamePropertyId||property==UIA_AutomationIdPropertyId||property==UIA_FrameworkIdPropertyId){auto value=property==UIA_NamePropertyId?wide(n.label):property==UIA_AutomationIdPropertyId?std::to_wstring(id):L"V ImGui";out->vt=VT_BSTR;out->bstrVal=SysAllocString(value.c_str());}
        else if(property==UIA_ControlTypePropertyId){static const int types[]={UIA_WindowControlTypeId,UIA_GroupControlTypeId,UIA_ButtonControlTypeId,UIA_CheckBoxControlTypeId,UIA_RadioButtonControlTypeId,UIA_EditControlTypeId,UIA_TextControlTypeId,UIA_ListControlTypeId,UIA_ListItemControlTypeId,UIA_ProgressBarControlTypeId,UIA_WindowControlTypeId};out->vt=VT_I4;out->lVal=types[n.role];}
        else if(property==UIA_IsEnabledPropertyId||property==UIA_IsKeyboardFocusablePropertyId||property==UIA_HasKeyboardFocusPropertyId||property==UIA_IsOffscreenPropertyId||property==UIA_IsControlElementPropertyId||property==UIA_IsContentElementPropertyId){out->vt=VT_BOOL;bool value=property==UIA_IsEnabledPropertyId?!(n.flags&VIMGUI_AX_DISABLED):property==UIA_IsKeyboardFocusablePropertyId?bool(n.actions&VIMGUI_AX_FOCUS):property==UIA_HasKeyboardFocusPropertyId?tree.focused&&tree.focus==id:property==UIA_IsOffscreenPropertyId?!visible(tree,n):true;out->boolVal=value?VARIANT_TRUE:VARIANT_FALSE;}
        else if(property==UIA_LiveSettingPropertyId){out->vt=VT_I4;out->lVal=(n.flags&VIMGUI_AX_LIVE)?1:0;}
        else if(property==UIA_PositionInSetPropertyId||property==UIA_SizeOfSetPropertyId){out->vt=VT_I4;out->lVal=LONG(property==UIA_PositionInSetPropertyId?n.position_in_set:n.size_of_set);}
        else if(property==UIA_ScrollHorizontalScrollPercentPropertyId||property==UIA_ScrollVerticalScrollPercentPropertyId||property==UIA_ScrollHorizontalViewSizePropertyId||property==UIA_ScrollVerticalViewSizePropertyId){
            out->vt=VT_R8;
            if(property==UIA_ScrollHorizontalScrollPercentPropertyId)out->dblVal=UIA_ScrollPatternNoScroll;
            else if(property==UIA_ScrollVerticalScrollPercentPropertyId)out->dblVal=n.scroll_y_max>0?n.scroll_y/n.scroll_y_max*100:UIA_ScrollPatternNoScroll;
            else if(property==UIA_ScrollHorizontalViewSizePropertyId)out->dblVal=100;
            else out->dblVal=n.height+n.scroll_y_max>0?n.height/(n.height+n.scroll_y_max)*100:100;
        }
        else if(property==UIA_ScrollHorizontallyScrollablePropertyId||property==UIA_ScrollVerticallyScrollablePropertyId){out->vt=VT_BOOL;out->boolVal=property==UIA_ScrollVerticallyScrollablePropertyId&&n.scroll_y_max>0?VARIANT_TRUE:VARIANT_FALSE;}
        return S_OK;}
    HRESULT STDMETHODCALLTYPE get_HostRawElementProvider(IRawElementProviderSimple **out)override{if(!out)return E_POINTER;*out=nullptr;auto tree=snapshot(state);return id==tree.root?UiaHostProviderFromHwnd(state->window,out):S_OK;}
    HRESULT STDMETHODCALLTYPE Navigate(NavigateDirection direction,IRawElementProviderFragment **out)override{if(!out)return E_POINTER;*out=nullptr;auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;uint64_t target=0;
        if(direction==NavigateDirection_Parent)target=accessibility_parent(tree,id);
        else if(direction==NavigateDirection_FirstChild&&!found->second->children.empty())target=found->second->children.front();
        else if(direction==NavigateDirection_LastChild&&!found->second->children.empty())target=found->second->children.back();
        else if(direction==NavigateDirection_NextSibling||direction==NavigateDirection_PreviousSibling){auto parent=accessibility_parent(tree,id);if(parent){auto &siblings=tree.nodes.at(parent)->children;auto it=std::find(siblings.begin(),siblings.end(),id);if(it!=siblings.end()){if(direction==NavigateDirection_NextSibling&&it+1!=siblings.end())target=*(it+1);if(direction==NavigateDirection_PreviousSibling&&it!=siblings.begin())target=*(it-1);}}}
        if(target)*out=fragment(state,target);return S_OK;}
    HRESULT STDMETHODCALLTYPE GetRuntimeId(SAFEARRAY **out)override{if(!out)return E_POINTER;*out=SafeArrayCreateVector(VT_I4,0,3);LONG values[]={UiaAppendRuntimeId,LONG(id&0xffffffff),LONG(id>>32)};for(LONG i=0;i<3;i++)SafeArrayPutElement(*out,&i,&values[i]);return S_OK;}
    HRESULT STDMETHODCALLTYPE get_BoundingRectangle(UiaRect *out)override{if(!out)return E_POINTER;auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;*out=rectangle(tree,*found->second);return S_OK;}
    HRESULT STDMETHODCALLTYPE GetEmbeddedFragmentRoots(SAFEARRAY **out)override{if(!out)return E_POINTER;*out=nullptr;return S_OK;}
    HRESULT STDMETHODCALLTYPE SetFocus()override{auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;if(!(n->actions&VIMGUI_AX_FOCUS)){::SetFocus(state->window);return S_OK;}return enqueue(state,{id,VIMGUI_AX_FOCUS})?S_OK:UIA_E_ELEMENTNOTENABLED;}
    HRESULT STDMETHODCALLTYPE get_FragmentRoot(IRawElementProviderFragmentRoot **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);*out=tree.root?static_cast<IRawElementProviderFragmentRoot *>(new Provider(state,tree.root)):nullptr;return *out?S_OK:UIA_E_ELEMENTNOTAVAILABLE;}
    HRESULT STDMETHODCALLTYPE ElementProviderFromPoint(double x,double y,IRawElementProviderFragment **out)override{if(!out)return E_POINTER;*out=nullptr;auto tree=snapshot(state);uint64_t target=0;double area=1e300;for(auto &entry:tree.nodes){auto bounds=rectangle(tree,*entry.second);double size=bounds.width*bounds.height;
        if(visible(tree,*entry.second)&&size>0&&size<area&&x>=bounds.left&&y>=bounds.top&&x<bounds.left+bounds.width&&y<bounds.top+bounds.height){target=entry.first;area=size;}}if(target)*out=fragment(state,target);return S_OK;}
    HRESULT STDMETHODCALLTYPE GetFocus(IRawElementProviderFragment **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);*out=tree.focused?fragment(state,tree.focus):nullptr;return S_OK;}
    HRESULT STDMETHODCALLTYPE Invoke()override{return enqueue(state,{id,VIMGUI_AX_CLICK})?S_OK:UIA_E_ELEMENTNOTENABLED;}
    HRESULT STDMETHODCALLTYPE Toggle()override{return Invoke();}
    HRESULT STDMETHODCALLTYPE get_ToggleState(ToggleState *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=(n->flags&VIMGUI_AX_CHECKED)?ToggleState_On:ToggleState_Off;return S_OK;}
    HRESULT STDMETHODCALLTYPE SetValue(LPCWSTR value)override{if(!value)return E_INVALIDARG;return enqueue(state,{id,VIMGUI_AX_SET_VALUE,utf8(value)})?S_OK:UIA_E_ELEMENTNOTENABLED;}
    HRESULT STDMETHODCALLTYPE get_Value(BSTR *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;auto value=wide(n->value);*out=SysAllocStringLen(value.data(),UINT(value.size()));return S_OK;}
    HRESULT STDMETHODCALLTYPE get_IsReadOnly(BOOL *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->role==VIMGUI_AX_PROGRESS || (n->flags&VIMGUI_AX_READ_ONLY);return S_OK;}
    HRESULT STDMETHODCALLTYPE SetValue(double)override{return UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE get_Value(double *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->numeric_value;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_Maximum(double *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->numeric_max;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_Minimum(double *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->numeric_min;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_LargeChange(double *out)override{if(!out)return E_POINTER;*out=0;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_SmallChange(double *out)override{if(!out)return E_POINTER;*out=0;return S_OK;}
    HRESULT STDMETHODCALLTYPE Select()override{return Invoke();}
    HRESULT STDMETHODCALLTYPE AddToSelection()override{return Select();}
    HRESULT STDMETHODCALLTYPE RemoveFromSelection()override{return UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE get_IsSelected(BOOL *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=bool(n->flags&(n->role==VIMGUI_AX_RADIO?VIMGUI_AX_CHECKED:VIMGUI_AX_SELECTED));return S_OK;}
    HRESULT STDMETHODCALLTYPE get_SelectionContainer(IRawElementProviderSimple **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);auto parent=accessibility_parent(tree,id);*out=parent?simple(state,parent):nullptr;return S_OK;}
    HRESULT STDMETHODCALLTYPE GetSelection(SAFEARRAY **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;
        if(found->second->role==VIMGUI_AX_TEXT_INPUT){auto value=wide(found->second->value);auto *range=new TextRange(state,id,utf16_offset(value,std::min(found->second->text_anchor,found->second->text_focus)),utf16_offset(value,std::max(found->second->text_anchor,found->second->text_focus)));*out=array_of(range);range->Release();return S_OK;}
        std::vector<uint64_t> selected;for(auto child:found->second->children){auto item=tree.nodes.find(child);if(item!=tree.nodes.end()&&(item->second->flags&VIMGUI_AX_SELECTED))selected.push_back(child);}
        *out=SafeArrayCreateVector(VT_UNKNOWN,0,ULONG(selected.size()));for(LONG i=0;i<LONG(selected.size());i++){auto *provider=simple(state,selected[i]);SafeArrayPutElement(*out,&i,provider);provider->Release();}return S_OK;}
    HRESULT STDMETHODCALLTYPE get_CanSelectMultiple(BOOL *out)override{if(!out)return E_POINTER;*out=false;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_IsSelectionRequired(BOOL *out)override{if(!out)return E_POINTER;*out=false;return S_OK;}
    HRESULT STDMETHODCALLTYPE ScrollIntoView()override{return enqueue(state,{id,VIMGUI_AX_SCROLL_INTO_VIEW})?S_OK:UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE Scroll(ScrollAmount horizontal,ScrollAmount vertical)override{if(horizontal!=ScrollAmount_NoAmount)return UIA_E_INVALIDOPERATION;if(vertical==ScrollAmount_NoAmount)return S_OK;
        return enqueue(state,{id,(vertical==ScrollAmount_LargeDecrement||vertical==ScrollAmount_SmallDecrement)?VIMGUI_AX_SCROLL_UP:VIMGUI_AX_SCROLL_DOWN})?S_OK:UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE SetScrollPercent(double horizontal,double vertical)override{if(horizontal!=UIA_ScrollPatternNoScroll||!std::isfinite(vertical)||vertical<0||vertical>100)return E_INVALIDARG;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;
        double current=n->scroll_y_max>0?n->scroll_y/n->scroll_y_max*100:0;if(std::abs(current-vertical)<.01)return S_OK;return enqueue(state,{id,VIMGUI_AX_SET_SCROLL_PERCENT,std::to_string(vertical)})?S_OK:UIA_E_INVALIDOPERATION;}
    HRESULT STDMETHODCALLTYPE get_HorizontalScrollPercent(double *out)override{if(!out)return E_POINTER;*out=UIA_ScrollPatternNoScroll;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_VerticalScrollPercent(double *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->scroll_y_max>0?n->scroll_y/n->scroll_y_max*100:UIA_ScrollPatternNoScroll;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_HorizontalViewSize(double *out)override{if(!out)return E_POINTER;*out=100;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_VerticalViewSize(double *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->height+n->scroll_y_max>0?n->height/(n->height+n->scroll_y_max)*100:100;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_HorizontallyScrollable(BOOL *out)override{if(!out)return E_POINTER;*out=false;return S_OK;}
    HRESULT STDMETHODCALLTYPE get_VerticallyScrollable(BOOL *out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=n->scroll_y_max>0;return S_OK;}
    HRESULT STDMETHODCALLTYPE GetVisibleRanges(SAFEARRAY **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;auto *range=visible(tree,*found->second)?new TextRange(state,id,0,int(wide(found->second->value).size())):nullptr;*out=array_of(range);if(range)range->Release();return S_OK;}
    HRESULT STDMETHODCALLTYPE RangeFromChild(IRawElementProviderSimple *,ITextRangeProvider **out)override{if(!out)return E_POINTER;*out=nullptr;return E_INVALIDARG;}
    HRESULT STDMETHODCALLTYPE RangeFromPoint(UiaPoint point,ITextRangeProvider **out)override{if(!out)return E_POINTER;auto tree=snapshot(state);auto found=tree.nodes.find(id);if(found==tree.nodes.end())return UIA_E_ELEMENTNOTAVAILABLE;auto value=wide(found->second->value);auto bounds=rectangle(tree,*found->second);int offset=bounds.width>0?std::clamp(int((point.x-bounds.left)/bounds.width*value.size()),0,int(value.size())):0;offset=utf16_offset(value,point_offset(value,offset));*out=new TextRange(state,id,offset,offset);return S_OK;}
    HRESULT STDMETHODCALLTYPE get_DocumentRange(ITextRangeProvider **out)override{if(!out)return E_POINTER;auto n=find_node(state,id);if(!n)return UIA_E_ELEMENTNOTAVAILABLE;*out=new TextRange(state,id,0,int(wide(n->value).size()));return S_OK;}
    HRESULT STDMETHODCALLTYPE get_SupportedTextSelection(SupportedTextSelection *out)override{if(!out)return E_POINTER;*out=SupportedTextSelection_Single;return S_OK;}
};
static IRawElementProviderSimple *simple(const std::shared_ptr<WindowsState> &state,uint64_t id){return find_node(state,id)?static_cast<IRawElementProviderSimple *>(new Provider(state,id)):nullptr;}
static IRawElementProviderFragment *fragment(const std::shared_ptr<WindowsState> &state,uint64_t id){return find_node(state,id)?static_cast<IRawElementProviderFragment *>(new Provider(state,id)):nullptr;}
struct WindowsAdapter {std::shared_ptr<WindowsState> state;};
static LRESULT CALLBACK procedure(HWND window,UINT message,WPARAM wparam,LPARAM lparam,UINT_PTR,DWORD_PTR data){auto *adapter=reinterpret_cast<WindowsAdapter *>(data);
    if(message==WM_GETOBJECT && static_cast<LONG>(lparam)==UiaRootObjectId){auto tree=snapshot(adapter->state);auto *provider=simple(adapter->state,tree.root);if(provider){auto result=UiaReturnRawElementProvider(window,wparam,lparam,provider);provider->Release();return result;}}
    return DefSubclassProc(window,message,wparam,lparam);}
void *accessibility_platform_attach(vimgui_accessibility *ctx,void *handle,void *){if(!handle)return nullptr;auto state=std::make_shared<WindowsState>();state->context=ctx;state->window=static_cast<HWND>(handle);state->previous=accessibility_snapshot(ctx);auto *adapter=new WindowsAdapter{state};
    if(!SetWindowSubclass(state->window,procedure,reinterpret_cast<UINT_PTR>(adapter),reinterpret_cast<DWORD_PTR>(adapter))){delete adapter;return nullptr;}return adapter;}
void accessibility_platform_detach(void *handle){auto *adapter=static_cast<WindowsAdapter *>(handle);RemoveWindowSubclass(adapter->state->window,procedure,reinterpret_cast<UINT_PTR>(adapter));
    {std::lock_guard<std::mutex> lock(adapter->state->mutex);adapter->state->context=nullptr;}delete adapter;}
void accessibility_platform_update(void *handle){auto state=static_cast<WindowsAdapter *>(handle)->state;auto tree=snapshot(state);if(tree.revision==state->previous.revision)return;auto previous=state->previous;state->previous=tree;
    for(auto &entry:tree.nodes){auto *provider=simple(state,entry.first);if(!provider)continue;auto old=previous.nodes.find(entry.first);
        if(tree.focused && tree.focus==entry.first && tree.focus!=previous.focus)UiaRaiseAutomationEvent(provider,UIA_AutomationFocusChangedEventId);
        if(old!=previous.nodes.end()){
            if(old->second->children!=entry.second->children)UiaRaiseStructureChangedEvent(provider,StructureChangeType_ChildrenInvalidated,nullptr,0);
            if(old->second->value!=entry.second->value){VARIANT a,b;VariantInit(&a);VariantInit(&b);a.vt=b.vt=VT_BSTR;a.bstrVal=SysAllocString(wide(old->second->value).c_str());b.bstrVal=SysAllocString(wide(entry.second->value).c_str());UiaRaiseAutomationPropertyChangedEvent(provider,UIA_ValueValuePropertyId,a,b);VariantClear(&a);VariantClear(&b);UiaRaiseAutomationEvent(provider,UIA_Text_TextChangedEventId);}
            if(old->second->text_anchor!=entry.second->text_anchor||old->second->text_focus!=entry.second->text_focus)UiaRaiseAutomationEvent(provider,UIA_Text_TextSelectionChangedEventId);
            if((entry.second->flags&VIMGUI_AX_LIVE)&&old->second->label!=entry.second->label)UiaRaiseAutomationEvent(provider,UIA_LiveRegionChangedEventId);
            if((old->second->flags^entry.second->flags)&VIMGUI_AX_CHECKED){VARIANT a,b;VariantInit(&a);VariantInit(&b);a.vt=b.vt=VT_I4;a.lVal=(old->second->flags&VIMGUI_AX_CHECKED)?ToggleState_On:ToggleState_Off;b.lVal=(entry.second->flags&VIMGUI_AX_CHECKED)?ToggleState_On:ToggleState_Off;UiaRaiseAutomationPropertyChangedEvent(provider,UIA_ToggleToggleStatePropertyId,a,b);}}
        provider->Release();}}
void accessibility_platform_window(void *handle){auto state=static_cast<WindowsAdapter *>(handle)->state;auto tree=snapshot(state);if(tree.focused&&!state->previous.focused){auto *provider=simple(state,tree.focus);if(provider){UiaRaiseAutomationEvent(provider,UIA_AutomationFocusChangedEventId);provider->Release();}}state->previous.focused=tree.focused;}
