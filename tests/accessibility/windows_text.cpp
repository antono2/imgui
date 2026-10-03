// Exercise text ranges across the real, separate-process UI Automation boundary.
#define NOMINMAX
#include "vimgui_accessibility.h"
#include <windows.h>
#include <UIAutomation.h>
#include <cstdio>
#include <string>
#include <stdexcept>
static void check(HRESULT result) {
    if(FAILED(result)) throw std::runtime_error("UIA HRESULT "+std::to_string(static_cast<unsigned long>(result)));
}
template<class T> struct Com {
    T *value=nullptr;
    ~Com(){if(value)value->Release();}
    T **out(){return &value;}
    T *operator->(){return value;}
};
static LRESULT CALLBACK window_proc(HWND window,UINT message,WPARAM wparam,LPARAM lparam) {
    if(message==WM_DESTROY){PostQuitMessage(0);return 0;}
    return DefWindowProcW(window,message,wparam,lparam);
}
static int provider(bool initialize_com) {
    if(initialize_com)check(CoInitializeEx(nullptr,COINIT_APARTMENTTHREADED));
    WNDCLASSW klass{};klass.lpfnWndProc=window_proc;klass.hInstance=GetModuleHandleW(nullptr);klass.lpszClassName=L"VImGuiTextTest";
    RegisterClassW(&klass);
    HWND window=CreateWindowW(klass.lpszClassName,L"Native text regression",WS_OVERLAPPEDWINDOW,0,0,400,300,nullptr,nullptr,klass.hInstance,nullptr);
    if(!window)return 1;
    auto *context=vimgui_accessibility_create();
    const uint64_t children[]={2};
    vimgui_accessibility_node root{};root.id=1;root.role=VIMGUI_AX_WINDOW;root.label="Text regression";root.children=children;root.child_count=1;root.width=400;root.height=300;
    vimgui_accessibility_node input{};input.id=2;input.role=VIMGUI_AX_TEXT_INPUT;input.label="Name";input.value="A\xf0\x9f\x93\xb7" "e\xcc\x81Z";input.width=300;input.height=30;input.actions=VIMGUI_AX_FOCUS|VIMGUI_AX_SET_VALUE|VIMGUI_AX_SET_SELECTION;input.text_anchor=1;input.text_focus=2;
    if(!vimgui_accessibility_set_node(context,&root)||!vimgui_accessibility_set_node(context,&input)||!vimgui_accessibility_commit(context,1,2))return 1;
    if(!vimgui_accessibility_attach(context,window,nullptr))return 1;
    ShowWindow(window,SW_SHOW);
    MSG message;while(GetMessageW(&message,nullptr,0,0)>0){TranslateMessage(&message);DispatchMessageW(&message);}
    vimgui_accessibility_free(context);if(initialize_com)CoUninitialize();return 0;
}
static void read_ranges(HWND window) {
    Com<IUIAutomation> automation;check(CoCreateInstance(__uuidof(CUIAutomation),nullptr,CLSCTX_INPROC_SERVER,IID_PPV_ARGS(automation.out())));
    Com<IUIAutomationElement> host;check(automation->ElementFromHandle(window,host.out()));
    VARIANT name;VariantInit(&name);name.vt=VT_BSTR;name.bstrVal=SysAllocString(L"Name");
    Com<IUIAutomationCondition> condition;check(automation->CreatePropertyCondition(UIA_NamePropertyId,name,condition.out()));VariantClear(&name);
    Com<IUIAutomationElement> field;check(host->FindFirst(TreeScope_Descendants,condition.value,field.out()));if(!field.value)throw std::runtime_error("No Name field");
    Com<IUIAutomationTextPattern> text;check(field->GetCurrentPatternAs(UIA_TextPatternId,IID_PPV_ARGS(text.out())));
    Com<IUIAutomationTextRange> document;check(text->get_DocumentRange(document.out()));
    BSTR content=nullptr;check(document->GetText(-1,&content));if(!content||std::wstring(content)!=L"A\xd83d\xdcf7" L"e\x0301Z")throw std::runtime_error("Document text mismatch");SysFreeString(content);
    std::puts("PASS: document range GetText");std::fflush(stdout);
    for(int attempt=0;attempt<50;++attempt) {
        Com<IUIAutomationTextRangeArray> selection;check(text->GetSelection(selection.out()));
        int count=0;check(selection->get_Length(&count));if(count!=1)throw std::runtime_error("Selection count mismatch");
        Com<IUIAutomationTextRange> range;check(selection->GetElement(0,range.out()));
        content=nullptr;check(range->GetText(-1,&content));if(!content||std::wstring(content)!=L"\xd83d\xdcf7")throw std::runtime_error("Selected text mismatch");SysFreeString(content);
    }
    std::puts("PASS: repeated selection range GetText across native UIA");
}
int main(int argc,char **argv) {
    if(argc>1&&std::string(argv[1])=="--provider")return provider(true);
    if(argc>1&&std::string(argv[1])=="--provider-no-com")return provider(false);
    check(CoInitializeEx(nullptr,COINIT_MULTITHREADED));
    wchar_t executable[MAX_PATH];if(!GetModuleFileNameW(nullptr,executable,MAX_PATH))return 1;
    std::wstring command=L"\""+std::wstring(executable)+L"\" ";
    command+=argc>1?L"--provider-no-com":L"--provider";
    STARTUPINFOW startup{};startup.cb=sizeof(startup);PROCESS_INFORMATION process{};
    if(!CreateProcessW(nullptr,command.data(),nullptr,nullptr,FALSE,0,nullptr,nullptr,&startup,&process))return 1;
    HWND window=nullptr;int result=0;
    try {
        for(int attempt=0;attempt<100&&!window;++attempt){window=FindWindowW(L"VImGuiTextTest",L"Native text regression");if(!window)Sleep(50);}
        if(!window)throw std::runtime_error("Provider window did not open");
        read_ranges(window);
    }catch(const std::exception &error){std::fprintf(stderr,"%s\n",error.what());result=1;}
    if(window)PostMessageW(window,WM_CLOSE,0,0);
    if(WaitForSingleObject(process.hProcess,5000)!=WAIT_OBJECT_0){TerminateProcess(process.hProcess,1);result=1;}
    DWORD status=1;GetExitCodeProcess(process.hProcess,&status);if(status!=0)result=1;
    CloseHandle(process.hThread);CloseHandle(process.hProcess);CoUninitialize();return result;
}
