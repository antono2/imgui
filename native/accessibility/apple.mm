#include "platform.h"
#include <algorithm>
#if defined(VIMGUI_IOS)
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
struct AppleState;
#if defined(VIMGUI_IOS)
@class VimguiTextField;
@interface VimguiElement : UIAccessibilityElement {
#else
@interface VimguiElement : NSAccessibilityElement {
#endif
@public
    std::shared_ptr<AppleState> state;
    uint64_t identity;
#if defined(VIMGUI_IOS)
    __strong VimguiTextField *editor;
#endif
}
@end
struct AppleState {
    vimgui_accessibility *context;
    AccessibilitySnapshot tree;
#if defined(VIMGUI_IOS)
    __strong UIView *host;
#else
    __strong NSView *host;
#endif
    __strong NSMutableDictionary<NSNumber *,VimguiElement *> *elements;
    __strong id originalChildren;
};
static NSString *string(const std::string &value){return [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding]?:@"";}
static std::shared_ptr<const Node> node(VimguiElement *element){if(!element || !element->state || !element->state->context)return nullptr;auto found=element->state->tree.nodes.find(element->identity);return found==element->state->tree.nodes.end()?nullptr:found->second;}
static bool request(VimguiElement *element,int action,std::string value={},size_t anchor=0,size_t focus=0){return element && element->state && element->state->context && accessibility_enqueue(element->state->context,{element->identity,action,std::move(value),anchor,focus});}
static NSArray *children(VimguiElement *element){auto n=node(element);NSMutableArray *result=[NSMutableArray array];if(n)for(auto childId:n->children){id child=element->state->elements[@(childId)];if(child)[result addObject:child];}return result;}
static CGRect bounds(VimguiElement *element){auto n=node(element);if(!n)return CGRectZero;auto rect=accessibility_bounds(element->state->tree,*n);return CGRectMake(rect.x,rect.y,rect.width,rect.height);}
static NSUInteger utf16Offset(NSString *text,size_t points){NSUInteger offset=0;while(offset<text.length && points--){unichar first=[text characterAtIndex:offset++];if(first>=0xd800&&first<=0xdbff&&offset<text.length){unichar second=[text characterAtIndex:offset];if(second>=0xdc00&&second<=0xdfff)++offset;}}return offset;}
static size_t codepointOffset(NSString *text,NSUInteger limit){size_t points=0;limit=std::min(limit,text.length);for(NSUInteger offset=0;offset<limit;++offset){unichar first=[text characterAtIndex:offset];if(first>=0xd800&&first<=0xdbff&&offset+1<limit){unichar second=[text characterAtIndex:offset+1];if(second>=0xdc00&&second<=0xdfff)++offset;}++points;}return points;}
#if defined(VIMGUI_IOS)
// UIKit supplies text editing, selection rotors and IME composition. The
// transparent editor forwards committed changes to the retained action queue.
@interface VimguiTextField : UITextField <UITextFieldDelegate> {
@public
    __weak VimguiElement *owner;
    BOOL syncing;
}
- (void)changed;
@end
@implementation VimguiTextField
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if(self){self.delegate=self;self.textColor=UIColor.clearColor;self.tintColor=UIColor.clearColor;
        self.backgroundColor=UIColor.clearColor;self.borderStyle=UITextBorderStyleNone;
        self.accessibilityIdentifier=@"vimgui-native-accessible-editor";
        [self addTarget:self action:@selector(changed) forControlEvents:UIControlEventEditingChanged];}
    return self;
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {return NO;}
- (BOOL)accessibilityActivate {if(!request(owner,VIMGUI_AX_FOCUS))return NO;return [self becomeFirstResponder];}
- (void)textFieldDidBeginEditing:(UITextField *)field {request(owner,VIMGUI_AX_FOCUS);}
- (void)changed {
    if(syncing || self.markedTextRange || !owner)return;
    request(owner,VIMGUI_AX_SET_VALUE,self.text.UTF8String?:"");
    [self textFieldDidChangeSelection:self];
}
- (void)textFieldDidChangeSelection:(UITextField *)field {
    if(syncing || self.markedTextRange || !owner)return;
    UITextRange *range=self.selectedTextRange;if(!range)return;
    NSInteger start=[self offsetFromPosition:self.beginningOfDocument toPosition:range.start];
    NSInteger end=[self offsetFromPosition:self.beginningOfDocument toPosition:range.end];
    if(start>=0 && end>=0)request(owner,VIMGUI_AX_SET_SELECTION,{},codepointOffset(self.text,start),codepointOffset(self.text,end));
}
- (void)accessibilityElementDidBecomeFocused {[owner accessibilityElementDidBecomeFocused];}
- (void)accessibilityElementDidLoseFocus {[owner accessibilityElementDidLoseFocus];}
@end
static void syncEditor(VimguiElement *element) {
    auto n=node(element);if(!n || n->role!=VIMGUI_AX_TEXT_INPUT)return;
    if(!element->editor){element->editor=[[VimguiTextField alloc] initWithFrame:bounds(element)];
        element->editor->owner=element;[element->state->host addSubview:element->editor];}
    VimguiTextField *field=element->editor;
    field.frame=bounds(element);field.accessibilityLabel=string(n->label);
    field.enabled=!(n->flags&(VIMGUI_AX_DISABLED|VIMGUI_AX_READ_ONLY));
    if(!field.markedTextRange){field->syncing=YES;NSString *value=string(n->value);
        if(![field.text isEqualToString:value])field.text=value;
        UITextPosition *start=[field positionFromPosition:field.beginningOfDocument offset:utf16Offset(value,std::min(n->text_anchor,n->text_focus))];
        UITextPosition *end=[field positionFromPosition:field.beginningOfDocument offset:utf16Offset(value,std::max(n->text_anchor,n->text_focus))];
        if(start && end)field.selectedTextRange=[field textRangeFromPosition:start toPosition:end];
        field->syncing=NO;}
    if(field.isFirstResponder && element->state->tree.focus!=element->identity)[field resignFirstResponder];
}
#endif
@implementation VimguiElement
#if defined(VIMGUI_IOS)
- (BOOL)isAccessibilityElement {auto n=node(self);return n && n->role!=VIMGUI_AX_TEXT_INPUT && n->role!=VIMGUI_AX_GROUP && n->role!=VIMGUI_AX_LIST && n->role!=VIMGUI_AX_WINDOW;}
- (NSString *)accessibilityLabel {auto n=node(self);return n?string(n->label):@"";}
- (NSString *)accessibilityValue {auto n=node(self);if(!n)return nil;if(n->role==VIMGUI_AX_PROGRESS){if(n->flags&VIMGUI_AX_INDETERMINATE)return string(n->value);return [NSString stringWithFormat:@"%.0f%%, %@",n->numeric_max>n->numeric_min?(n->numeric_value-n->numeric_min)/(n->numeric_max-n->numeric_min)*100:0,string(n->value)];}return string(n->value);}
- (void)setAccessibilityValue:(NSString *)value {request(self,VIMGUI_AX_SET_VALUE,value.UTF8String?:"");}
- (UIAccessibilityTraits)accessibilityTraits {auto n=node(self);if(!n)return UIAccessibilityTraitNone;UIAccessibilityTraits traits=UIAccessibilityTraitNone;
    if(n->role==VIMGUI_AX_BUTTON||n->role==VIMGUI_AX_CHECKBOX||n->role==VIMGUI_AX_RADIO)traits|=UIAccessibilityTraitButton;
    if(n->role==VIMGUI_AX_LABEL)traits|=UIAccessibilityTraitStaticText;
    if(n->flags&(VIMGUI_AX_SELECTED|VIMGUI_AX_CHECKED))traits|=UIAccessibilityTraitSelected;
    if(n->flags&VIMGUI_AX_DISABLED)traits|=UIAccessibilityTraitNotEnabled;
    if(n->flags&VIMGUI_AX_LIVE)traits|=UIAccessibilityTraitUpdatesFrequently;
    return traits;}
- (CGRect)accessibilityFrame {return UIAccessibilityConvertFrameToScreenCoordinates(bounds(self),state->host);}
- (id)accessibilityContainer {if(!state)return nil;auto parent=accessibility_parent(state->tree,identity);return parent?state->elements[@(parent)]:state->host;}
- (NSInteger)accessibilityElementCount {return editor?1:children(self).count;}
- (id)accessibilityElementAtIndex:(NSInteger)index {if(editor)return index==0?editor:nil;NSArray *list=children(self);return index>=0&&index<(NSInteger)list.count?list[index]:nil;}
- (NSInteger)indexOfAccessibilityElement:(id)element {return editor?(element==editor?0:NSNotFound):[children(self) indexOfObjectIdenticalTo:element];}
- (BOOL)accessibilityActivate {auto n=node(self);if(!n)return NO;return request(self,n->role==VIMGUI_AX_TEXT_INPUT?VIMGUI_AX_FOCUS:VIMGUI_AX_CLICK);}
- (void)accessibilityElementDidBecomeFocused {if(!state)return;CGRect rectangle=bounds(self);vimgui_accessibility_set_visual_focus(state->context,true,rectangle.origin.x,rectangle.origin.y,rectangle.size.width,rectangle.size.height);request(self,VIMGUI_AX_SCROLL_INTO_VIEW);}
- (void)accessibilityElementDidLoseFocus {if(state&&state->context)vimgui_accessibility_set_visual_focus(state->context,false,0,0,0,0);}
- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {int action=direction==UIAccessibilityScrollDirectionUp?VIMGUI_AX_SCROLL_UP:direction==UIAccessibilityScrollDirectionDown?VIMGUI_AX_SCROLL_DOWN:0;if(!action)return NO;
    if(request(self,action))return YES;for(auto parent=accessibility_parent(state->tree,identity);parent;parent=accessibility_parent(state->tree,parent)){auto element=state->elements[@(parent)];if(request(element,action))return YES;}return NO;}
#else
- (BOOL)isAccessibilityElement {return node(self)!=nullptr;}
- (NSString *)accessibilityRole {auto n=node(self);if(!n)return NSAccessibilityUnknownRole;static NSString *roles[]={NSAccessibilityWindowRole,NSAccessibilityGroupRole,NSAccessibilityButtonRole,NSAccessibilityCheckBoxRole,NSAccessibilityRadioButtonRole,NSAccessibilityTextFieldRole,NSAccessibilityStaticTextRole,NSAccessibilityListRole,NSAccessibilityRowRole,NSAccessibilityProgressIndicatorRole,NSAccessibilityWindowRole};return roles[n->role];}
- (NSString *)accessibilityLabel {auto n=node(self);return n?string(n->label):@"";}
- (id)accessibilityValue {auto n=node(self);if(!n)return nil;if(n->role==VIMGUI_AX_CHECKBOX||n->role==VIMGUI_AX_RADIO)return @((n->flags&VIMGUI_AX_CHECKED)!=0);if(n->role==VIMGUI_AX_PROGRESS)return n->flags&VIMGUI_AX_INDETERMINATE?nil:@(n->numeric_value);return n->role==VIMGUI_AX_LABEL?string(n->label):string(n->value);}
- (void)setAccessibilityValue:(id)value {if([value isKindOfClass:NSString.class])request(self,VIMGUI_AX_SET_VALUE,[value UTF8String]?:"");}
- (BOOL)isAccessibilityEnabled {auto n=node(self);return n && !(n->flags&VIMGUI_AX_DISABLED);}
- (BOOL)isAccessibilityFocused {return state && state->tree.focused && state->tree.focus==identity;}
- (void)setAccessibilityFocused:(BOOL)focused {if(focused)request(self,VIMGUI_AX_FOCUS);}
- (BOOL)isAccessibilitySelected {auto n=node(self);return n && (n->flags&VIMGUI_AX_SELECTED);}
- (void)setAccessibilitySelected:(BOOL)selected {if(selected)request(self,VIMGUI_AX_CLICK);}
- (id)accessibilityParent {if(!state)return nil;auto parent=accessibility_parent(state->tree,identity);return parent?state->elements[@(parent)]:state->host;}
- (NSArray *)accessibilityChildren {return children(self);}
- (NSArray *)accessibilitySelectedChildren {NSMutableArray *result=[NSMutableArray array];for(VimguiElement *child in children(self))if(child.accessibilitySelected)[result addObject:child];return result;}
- (NSRect)accessibilityFrame {if(!state)return NSZeroRect;CGRect rectangle=bounds(self);if(!state->host.isFlipped)rectangle.origin.y=state->host.bounds.size.height-CGRectGetMaxY(rectangle);return [state->host.window convertRectToScreen:[state->host convertRect:rectangle toView:nil]];}
- (BOOL)accessibilityPerformPress {return request(self,VIMGUI_AX_CLICK);}
- (BOOL)accessibilityPerformScrollToVisible {return request(self,VIMGUI_AX_SCROLL_INTO_VIEW);}
- (BOOL)accessibilityPerformScrollUp {return request(self,VIMGUI_AX_SCROLL_UP);}
- (BOOL)accessibilityPerformScrollDown {return request(self,VIMGUI_AX_SCROLL_DOWN);}
- (NSString *)accessibilityStringValue {auto n=node(self);return n?string(n->value):@"";}
- (NSInteger)accessibilityNumberOfCharacters {return self.accessibilityStringValue.length;}
- (NSRange)accessibilitySelectedTextRange {auto n=node(self);if(!n)return NSMakeRange(0,0);NSString *value=string(n->value);NSUInteger anchor=utf16Offset(value,n->text_anchor),focus=utf16Offset(value,n->text_focus);return NSMakeRange(std::min(anchor,focus),anchor>focus?anchor-focus:focus-anchor);}
- (void)setAccessibilitySelectedTextRange:(NSRange)range {NSString *value=self.accessibilityStringValue;if(range.location>value.length||range.length>value.length-range.location)return;request(self,VIMGUI_AX_SET_SELECTION,{},codepointOffset(value,range.location),codepointOffset(value,NSMaxRange(range)));}
- (NSString *)accessibilitySelectedText {NSString *value=self.accessibilityStringValue;return [value substringWithRange:self.accessibilitySelectedTextRange];}
- (NSRange)accessibilityVisibleCharacterRange {return NSMakeRange(0,self.accessibilityNumberOfCharacters);}
- (NSString *)accessibilityStringForRange:(NSRange)range {NSString *value=self.accessibilityStringValue;return range.location<=value.length&&range.length<=value.length-range.location?[value substringWithRange:range]:nil;}
- (NSRect)accessibilityFrameForRange:(NSRange)range {return NSMaxRange(range)<=NSUInteger(self.accessibilityNumberOfCharacters)?self.accessibilityFrame:NSZeroRect;}
- (NSRange)accessibilityRangeForLine:(NSInteger)line {return line==0?NSMakeRange(0,self.accessibilityNumberOfCharacters):NSMakeRange(NSNotFound,0);}
- (NSInteger)accessibilityLineForIndex:(NSInteger)index {return index>=0&&index<=self.accessibilityNumberOfCharacters?0:NSNotFound;}
- (id)accessibilityMinValue {auto n=node(self);return n?@(n->numeric_min):nil;}
- (id)accessibilityMaxValue {auto n=node(self);return n?@(n->numeric_max):nil;}
- (BOOL)isAccessibilitySelectorAllowed:(SEL)selector {auto n=node(self);if(!n)return NO;
    if(selector==@selector(accessibilityPerformPress))return (n->actions&VIMGUI_AX_CLICK)!=0;
    if(selector==@selector(setAccessibilityValue:))return (n->actions&VIMGUI_AX_SET_VALUE)!=0;
    if(selector==@selector(setAccessibilitySelectedTextRange:))return (n->actions&VIMGUI_AX_SET_SELECTION)!=0;
    return [super isAccessibilitySelectorAllowed:selector];}
#endif
@end
struct AppleAdapter {std::shared_ptr<AppleState> state;};
void *accessibility_platform_attach(vimgui_accessibility *ctx,void *handle,void *) {
    if(!handle || !NSThread.isMainThread)return nullptr;auto state=std::make_shared<AppleState>();state->context=ctx;state->tree=accessibility_snapshot(ctx);
#if defined(VIMGUI_IOS)
    state->host=(__bridge UIView *)handle;state->originalChildren=state->host.accessibilityElements;
#else
    state->host=[(__bridge NSWindow *)handle contentView];state->originalChildren=state->host.accessibilityChildren;
#endif
    state->elements=[NSMutableDictionary dictionary];
    for(const auto &entry:state->tree.nodes){
#if defined(VIMGUI_IOS)
        VimguiElement *element=[[VimguiElement alloc] initWithAccessibilityContainer:state->host];
#else
        VimguiElement *element=[[VimguiElement alloc] init];
#endif
        element->state=state;element->identity=entry.first;state->elements[@(entry.first)]=element;
#if defined(VIMGUI_IOS)
        syncEditor(element);
#endif
    }
#if defined(VIMGUI_IOS)
    state->host.accessibilityElements=@[state->elements[@(state->tree.root)]];
#else
    state->host.accessibilityChildren=@[state->elements[@(state->tree.root)]];
#endif
    return new AppleAdapter{state};
}
void accessibility_platform_detach(void *handle){auto *adapter=static_cast<AppleAdapter *>(handle);auto state=adapter->state;state->context=nullptr;
#if defined(VIMGUI_IOS)
    for(VimguiElement *element in state->elements.allValues){[element->editor resignFirstResponder];[element->editor removeFromSuperview];}
    state->host.accessibilityElements=state->originalChildren;
#else
    state->host.accessibilityChildren=state->originalChildren;
#endif
    // Break native element ownership while surviving OS references read defunct.
    [state->elements removeAllObjects];delete adapter;
}
void accessibility_platform_update(void *handle){auto state=static_cast<AppleAdapter *>(handle)->state;auto tree=accessibility_snapshot(state->context);if(tree.revision==state->tree.revision)return;auto previous=state->tree;state->tree=tree;
    for(const auto &entry:tree.nodes){VimguiElement *element=state->elements[@(entry.first)];if(!element){
#if defined(VIMGUI_IOS)
        element=[[VimguiElement alloc] initWithAccessibilityContainer:state->host];
#else
        element=[[VimguiElement alloc] init];
#endif
        element->state=state;element->identity=entry.first;state->elements[@(entry.first)]=element;}
        auto old=previous.nodes.find(entry.first);
#if defined(VIMGUI_IOS)
        syncEditor(element);
        if(old!=previous.nodes.end() && (entry.second->flags&VIMGUI_AX_LIVE) && old->second->label!=entry.second->label)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,string(entry.second->label));
#else
        if(tree.focused&&tree.focus==entry.first&&tree.focus!=previous.focus)NSAccessibilityPostNotification(element,NSAccessibilityFocusedUIElementChangedNotification);
        if(old!=previous.nodes.end()){if(old->second->value!=entry.second->value || old->second->flags!=entry.second->flags)NSAccessibilityPostNotification(element,NSAccessibilityValueChangedNotification);
            if(old->second->text_anchor!=entry.second->text_anchor||old->second->text_focus!=entry.second->text_focus)NSAccessibilityPostNotification(element,NSAccessibilitySelectedTextChangedNotification);
            if((entry.second->flags&VIMGUI_AX_LIVE)&&old->second->label!=entry.second->label)NSAccessibilityPostNotificationWithUserInfo(state->host,NSAccessibilityAnnouncementRequestedNotification,@{NSAccessibilityAnnouncementKey:string(entry.second->label),NSAccessibilityPriorityKey:@(NSAccessibilityPriorityMedium)});}
#endif
    }
    for(NSNumber *key in [state->elements.allKeys copy])if(!tree.nodes.count(key.unsignedLongLongValue)){
#if defined(VIMGUI_IOS)
        VimguiElement *element=state->elements[key];[element->editor resignFirstResponder];[element->editor removeFromSuperview];
#endif
        [state->elements removeObjectForKey:key];}
#if defined(VIMGUI_IOS)
    if(tree.nodes.size()!=previous.nodes.size())UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,nil);
#else
    if(tree.nodes.size()!=previous.nodes.size())NSAccessibilityPostNotification(state->host,NSAccessibilityLayoutChangedNotification);
#endif
}
void accessibility_platform_window(void *handle){auto state=static_cast<AppleAdapter *>(handle)->state;auto tree=accessibility_snapshot(state->context);state->tree.focused=tree.focused;state->tree.x=tree.x;state->tree.y=tree.y;state->tree.width=tree.width;state->tree.height=tree.height;}
