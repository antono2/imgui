#include "ios_application.h"
#include "vimgui_app.h"
#include "../../cimgui/imgui/imgui.h"
#include "../apple/vimgui_ios.h"
#include "../apple/vimgui_metal.h"
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#include <algorithm>
#include <cmath>

@interface VImGuiApplicationView : MTKView
- (void)releaseTouches;
@end
@implementation VImGuiApplicationView {
    NSMutableDictionary<NSNumber *, NSValue *> *_contacts;
}
- (void)forwardTouches:(NSSet<UITouch *> *)touches down:(BOOL)down {
    if (!_contacts) _contacts=[NSMutableDictionary dictionary];
    for (UITouch *touch in touches) {
        CGPoint point=[touch locationInView:self];
        uint64_t identity=(uint64_t)(__bridge void *)touch;
        if (down) _contacts[@(identity)]=[NSValue valueWithCGPoint:point];
        else [_contacts removeObjectForKey:@(identity)];
        vimgui_ios_touch(identity,point.x,point.y,down);
    }
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self forwardTouches:touches down:YES]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self forwardTouches:touches down:YES]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self forwardTouches:touches down:NO]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self forwardTouches:touches down:NO]; }
- (void)releaseTouches {
    for (NSNumber *identity in _contacts) {
        CGPoint point=[_contacts[identity] CGPointValue];
        vimgui_ios_touch(identity.unsignedLongLongValue,point.x,point.y,false);
    }
    [_contacts removeAllObjects];
}
@end

@interface VImGuiApplicationController : UIViewController <MTKViewDelegate>
- (void)applyTextEdit:(void *)data;
@end
static void apply_text_edit(void *data,void *owner) {
    [(__bridge VImGuiApplicationController *)owner applyTextEdit:data];
}
@implementation VImGuiApplicationController {
    id<MTLCommandQueue> _queue;
    ImGuiContext *_context;
    void *_textView;
    void *_keyboard;
    bool _begun, _widgets, _platform, _renderer, _ready;
    CGFloat _keyboardInset;
    float _textScale;
    CFTimeInterval _lastFrame;
}
- (float)currentTextScale {
    float scale=[[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledValueForValue:16]/16;
    return std::isfinite(scale)?std::max(0.5f,std::min(8.0f,scale)):1;
}
- (void)fail:(NSString *)message {
    _ready=false;
    ((MTKView *)self.view).paused=YES;
    UILabel *label=[[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds,24,24)];
    label.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    label.numberOfLines=0; label.text=message;
    label.textColor=UIColor.labelColor; label.backgroundColor=UIColor.systemBackgroundColor;
    label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.adjustsFontForContentSizeCategory=YES;
    [self.view addSubview:label];
    NSLog(@"vimgui-ios-application: %@",message);
}
- (void)loadView {
    NSAssert(NSThread.isMainThread,@"Application UI must run on the UIKit thread");
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    VImGuiApplicationView *view=[[VImGuiApplicationView alloc] initWithFrame:UIScreen.mainScreen.bounds device:device];
    view.colorPixelFormat=MTLPixelFormatBGRA8Unorm;
    view.clearColor=MTLClearColorMake(0.08,0.08,0.08,1);
    view.preferredFramesPerSecond=60; view.delegate=self; self.view=view;
    if (!device) { [self fail:@"Metal rendering is unavailable."]; return; }
    NSError *error=nil;
    NSURL *root=[NSFileManager.defaultManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask
        appropriateForURL:nil create:YES error:&error];
    root=[root URLByAppendingPathComponent:@"native-state" isDirectory:YES];
    if (!root || ![NSFileManager.defaultManager createDirectoryAtURL:root withIntermediateDirectories:YES attributes:nil error:&error]) {
        [self fail:@"The application state directory could not be opened."]; return;
    }
    _textScale=[self currentTextScale];
    _begun=vimgui_ios_application_begin(root.path.UTF8String,_textScale,(__bridge void *)self);
    if (!_begun) { [self fail:@"The application could not restore its state."]; return; }
    IMGUI_CHECKVERSION(); _context=ImGui::CreateContext();
    ImGui::GetIO().IniFilename=nullptr;
    ImGui::GetIO().ConfigFlags|=ImGuiConfigFlags_NavEnableKeyboard|ImGuiConfigFlags_NavEnableGamepad;
#ifdef IMGUI_HAS_DOCK
#ifdef IMGUI_HAS_VIEWPORT
    ImGui::GetIO().ConfigFlags&=~ImGuiConfigFlags_ViewportsEnable;
#endif
#endif
    _queue=[device newCommandQueue];
    _platform=vimgui_ios_init(); _renderer=vimgui_metal_init((__bridge void *)device);
    _widgets=vimgui_app_initialize(vimgui_ios_application_title());
    if (!_queue || !_platform || !_renderer || !_widgets) { [self fail:@"The application renderer could not start."]; return; }
    vimgui_ios_application_mount(_textScale);
    _textView=vimgui_ios_text_view_create((__bridge void *)view);
    _keyboard=vimgui_ios_keyboard_create((__bridge void *)view);
    vimgui_app_set_text_edit_handler(apply_text_edit,(__bridge void *)self);
    if (!vimgui_accessibility_attach(vimgui_app_accessibility(),(__bridge void *)view,nullptr)) {
        [self fail:@"The accessibility adapter could not start."]; return;
    }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardChanged:)
        name:UIKeyboardWillChangeFrameNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(background:)
        name:UIApplicationWillResignActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(foreground:)
        name:UIApplicationDidBecomeActiveNotification object:nil];
    _ready=true;
}
- (void)keyboardChanged:(NSNotification *)notification {
    CGRect screen=[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect window=[self.view.window convertRect:screen fromWindow:nil];
    CGRect local=[self.view convertRect:window fromView:self.view.window];
    CGRect intersection=CGRectIntersection(self.view.bounds,local);
    _keyboardInset=!CGRectIsNull(intersection) && CGRectGetMaxY(local)>=CGRectGetMaxY(self.view.bounds)-1
        ?CGRectGetHeight(intersection):0;
}
- (void)background:(NSNotification *)notification {
    [(VImGuiApplicationView *)self.view releaseTouches];
    ((MTKView *)self.view).paused=YES;
    if (_widgets) vimgui_accessibility_window_state(vimgui_app_accessibility(),false,0,0,self.view.bounds.size.width,self.view.bounds.size.height);
}
- (void)foreground:(NSNotification *)notification {
    _lastFrame=0; ((MTKView *)self.view).paused=!_ready;
}
- (void)applyTextEdit:(void *)data {
    if (_textView && !vimgui_ios_text_view_apply_edit(_textView,data)) {
        NSLog(@"vimgui-ios-application: rich text bridge failed (%d); using committed-text input",vimgui_ios_text_view_error(_textView));
        vimgui_ios_text_view_destroy(_textView); _textView=nullptr;
    }
    if (_textView) {
        ImVec2 anchor=ImGui::GetCursorScreenPos();
        vimgui_ios_text_view_set_anchor(_textView,anchor.x,anchor.y);
    }
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}
- (void)drawInMTKView:(MTKView *)view {
    if (!_ready) return;
    NSAssert(NSThread.isMainThread,@"Draw callbacks must run on the UIKit thread");
    MTLRenderPassDescriptor *pass=view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable=view.currentDrawable;
    if (!pass || !drawable) return;
    ImGui::SetCurrentContext(_context);
    CFTimeInterval now=CACurrentMediaTime();
    float delta=_lastFrame>0?std::min(0.1f,float(now-_lastFrame)):1.0f/60; _lastFrame=now;
    float scale=[self currentTextScale];
    if (std::abs(scale-_textScale)>0.001f) { _textScale=scale; vimgui_ios_application_mount(scale); }
    CGSize points=view.bounds.size;
    float pixels=points.width>0?view.drawableSize.width/points.width:1;
    vimgui_metal_new_frame((__bridge void *)pass);
    vimgui_ios_new_frame(points.width,points.height,pixels,delta);
    UIEdgeInsets safe=view.safeAreaInsets;
    vimgui_app_safe_area(safe.left,safe.top,safe.right,std::max(safe.bottom,_keyboardInset));
    ImGui::NewFrame();
    if (!vimgui_ios_application_draw()) { ImGui::EndFrame(); [self fail:@"The application UI could not be updated."]; return; }
    ImGui::Render();
    bool editing=vimgui_ios_wants_text_input();
    if (_textView && !vimgui_ios_text_view_set_visible(_textView,editing)) {
        vimgui_ios_text_view_destroy(_textView); _textView=nullptr;
    }
    if (!_textView && _keyboard) vimgui_ios_keyboard_set_visible(_keyboard,editing);
    vimgui_accessibility_window_state(vimgui_app_accessibility(),true,0,0,points.width,points.height);
    vimgui_accessibility_update(vimgui_app_accessibility());
    id<MTLCommandBuffer> buffer=[_queue commandBuffer];
    id<MTLRenderCommandEncoder> encoder=[buffer renderCommandEncoderWithDescriptor:pass];
    if (!buffer || !encoder) { [self fail:@"Metal could not prepare the next frame."]; return; }
    vimgui_metal_render_draw_data(ImGui::GetDrawData(),(__bridge void *)buffer,(__bridge void *)encoder);
    [encoder endEncoding]; [buffer presentDrawable:drawable]; [buffer commit];
}
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (_context) ImGui::SetCurrentContext(_context);
    if (_widgets) vimgui_accessibility_detach(vimgui_app_accessibility());
    vimgui_ios_text_view_destroy(_textView); vimgui_ios_keyboard_destroy(_keyboard);
    if (_widgets) vimgui_app_shutdown();
    if (_renderer) vimgui_metal_shutdown();
    if (_platform) vimgui_ios_shutdown();
    if (_context) ImGui::DestroyContext(_context);
    if (_begun) vimgui_ios_application_end();
}
@end

@interface VImGuiApplicationDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation VImGuiApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController=[VImGuiApplicationController new];
    [self.window makeKeyAndVisible]; return YES;
}
@end
int main(int argc,char **argv) {
    @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(VImGuiApplicationDelegate.class)); }
}
