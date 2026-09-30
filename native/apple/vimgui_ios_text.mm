#include "vimgui_ios.h"

#include "../../cimgui/imgui/imgui.h"
#include "../mobile/vimgui_text_offsets.h"
#import <UIKit/UIKit.h>

#include <algorithm>
#include <cstring>
#include <string>

// UITextView supplies UIKit's own UITextInput implementation. Keep it attached
// and visible (but transparent) so it can remain first responder and present
// the system keyboard/candidates. All state is confined to the UIKit thread.
@interface VImGuiTextView : UITextView <UITextViewDelegate>
{
@public
    bool pending;
    bool syncing;
    int32_t error;
    ImGuiID widget_id;
}
@end

@implementation VImGuiTextView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        pending = false;
        syncing = false;
        error = 0;
        widget_id = 0;
        self.delegate = self;
        self.backgroundColor = UIColor.clearColor;
        self.textColor = UIColor.clearColor;
        self.tintColor = UIColor.clearColor;
        self.scrollEnabled = NO;
        self.accessibilityElementsHidden = YES;
        self.textContainerInset = UIEdgeInsetsZero;
    }
    return self;
}
- (void)textViewDidChange:(UITextView*)textView
{
    (void)textView;
    if (!syncing)
        pending = true;
}
- (void)textViewDidChangeSelection:(UITextView*)textView
{
    (void)textView;
    if (!syncing)
        pending = true;
}
@end

static std::u16string utf16_text(NSString* text)
{
    std::u16string result(text.length, u'\0');
    if (!result.empty())
        [text getCharacters:reinterpret_cast<unichar*>(&result[0]) range:NSMakeRange(0, text.length)];
    return result;
}

static NSString* ns_text(const std::u16string& text)
{
    if (text.empty())
        return @"";
    return [NSString stringWithCharacters:reinterpret_cast<const unichar*>(text.data())
                                   length:text.size()];
}

extern "C" void* vimgui_ios_text_view_create(void* parent_view)
{
    if (parent_view == nullptr || ![NSThread isMainThread])
        return nullptr;
    UIView* parent = (__bridge UIView*)parent_view;
    VImGuiTextView* view = [[VImGuiTextView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [parent addSubview:view];
    return (__bridge_retained void*)view;
}

extern "C" bool vimgui_ios_text_view_set_visible(void* handle, bool visible)
{
    if (handle == nullptr || ![NSThread isMainThread])
        return false;
    VImGuiTextView* view = (__bridge VImGuiTextView*)handle;
    if (visible && !view.isFirstResponder)
        [view becomeFirstResponder];
    else if (!visible && view.isFirstResponder)
    {
        [view unmarkText];
        [view resignFirstResponder];
    }
    if (!visible)
        view->widget_id = 0;
    const bool result = view.isFirstResponder == visible;
    if (!result)
        view->error = 1;
    return result;
}

extern "C" bool vimgui_ios_text_view_apply_edit(void* handle, void* callback_data)
{
    if (handle == nullptr || callback_data == nullptr || ![NSThread isMainThread])
        return false;
    VImGuiTextView* view = (__bridge VImGuiTextView*)handle;
    ImGuiInputTextCallbackData* data = static_cast<ImGuiInputTextCallbackData*>(callback_data);
    if (data->EventFlag != ImGuiInputTextFlags_CallbackAlways ||
        (data->Flags & ImGuiInputTextFlags_ReadOnly) != 0)
    {
        view->error = 3;
        return false;
    }
    if (data->EventActivated || view->widget_id != data->ID)
    {
        // An old widget's pending edit must never flow into a new widget.
        view->pending = false;
        view->widget_id = data->ID;
        view->syncing = true;
        const std::u16string text = vimgui::utf8_to_utf16(data->Buf, data->BufTextLen);
        view.text = ns_text(text);
        const int selection_start = vimgui::utf8_offset_to_utf16_index(data->Buf, data->SelectionStart);
        const int selection_end = vimgui::utf8_offset_to_utf16_index(data->Buf, data->SelectionEnd);
        view.selectedRange = NSMakeRange(std::min(selection_start, selection_end),
                                         std::max(selection_start, selection_end) - std::min(selection_start, selection_end));
        view->syncing = false;
    }
    if (view->pending)
    {
        const std::u16string text = utf16_text(view.text ?: @"");
        const std::string utf8 = vimgui::utf16_to_utf8(text);
        if (utf8.size() >= static_cast<size_t>(data->BufSize))
        {
            view->error = 2;
            view->pending = false;
            return false;
        }
        const NSRange selection = view.selectedRange;
        if (selection.location == NSNotFound || selection.location > text.size() ||
            selection.length > text.size() - selection.location)
        {
            view->error = 3;
            view->pending = false;
            return false;
        }
        if (data->BufTextLen != static_cast<int>(utf8.size()) ||
            std::memcmp(data->Buf, utf8.data(), utf8.size()) != 0)
        {
            data->DeleteChars(0, data->BufTextLen);
            data->InsertChars(0, utf8.data(), utf8.data() + utf8.size());
        }
        const int start = vimgui::utf16_index_to_utf8_offset(text, static_cast<int>(selection.location));
        const int end = vimgui::utf16_index_to_utf8_offset(text, static_cast<int>(selection.location + selection.length));
        data->SetSelection(std::min(start, data->BufTextLen), std::min(end, data->BufTextLen));
        view->pending = false;
    }
    else if (view.markedTextRange == nil)
    {
        // ImGui may change text or cursor via hardware keys and touch. Do not
        // overwrite UIKit while it owns a provisional marked-text segment.
        const std::u16string text = vimgui::utf8_to_utf16(data->Buf, data->BufTextLen);
        const int selection_start = vimgui::utf8_offset_to_utf16_index(data->Buf, data->SelectionStart);
        const int selection_end = vimgui::utf8_offset_to_utf16_index(data->Buf, data->SelectionEnd);
        const int start = std::min(selection_start, selection_end);
        const int length = std::max(selection_start, selection_end) - start;
        if (utf16_text(view.text ?: @"") != text || view.selectedRange.location != static_cast<NSUInteger>(start) ||
            view.selectedRange.length != static_cast<NSUInteger>(length))
        {
            view->syncing = true;
            view.text = ns_text(text);
            view.selectedRange = NSMakeRange(start, length);
            view->syncing = false;
        }
    }
    return true;
}

extern "C" bool vimgui_ios_text_view_marked_range(void* handle, int32_t* start, int32_t* end)
{
    if (handle == nullptr || start == nullptr || end == nullptr || ![NSThread isMainThread])
        return false;
    VImGuiTextView* view = (__bridge VImGuiTextView*)handle;
    UITextRange* range = view.markedTextRange;
    if (range == nil)
        return false;
    *start = static_cast<int32_t>([view offsetFromPosition:view.beginningOfDocument toPosition:range.start]);
    *end = static_cast<int32_t>([view offsetFromPosition:view.beginningOfDocument toPosition:range.end]);
    return *start >= 0 && *end >= *start;
}

extern "C" void vimgui_ios_text_view_set_anchor(void* handle, float x, float y)
{
    if (handle == nullptr || ![NSThread isMainThread])
        return;
    VImGuiTextView* view = (__bridge VImGuiTextView*)handle;
    view.frame = CGRectMake(x, y, 1, 1);
}

extern "C" int32_t vimgui_ios_text_view_error(void* handle)
{
    if (handle == nullptr || ![NSThread isMainThread])
        return 1;
    return ((__bridge VImGuiTextView*)handle)->error;
}

extern "C" void vimgui_ios_text_view_destroy(void* handle)
{
    if (handle == nullptr || ![NSThread isMainThread])
        return;
    VImGuiTextView* view = CFBridgingRelease(handle);
    [view resignFirstResponder];
    [view removeFromSuperview];
}
