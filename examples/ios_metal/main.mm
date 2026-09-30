// Minimal UIKit/Metal lifecycle host for the iOS backend. The app can be
// installed in Simulator without an Xcode project or signing credentials.
#include "../../cimgui/imgui/imgui.h"
#include "../../native/apple/vimgui_ios.h"
#include "../../native/apple/vimgui_metal.h"

#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#include <cstdint>

static void write_status(NSString* status)
{
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"vimgui-metal-status.txt"];
    [status writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"vimgui-ios-demo: %@", status);
}

@interface VImGuiView : MTKView
@end

@implementation VImGuiView
- (void)forwardTouches:(NSSet<UITouch*>*)touches down:(BOOL)down
{
    for (UITouch* touch in touches)
    {
        CGPoint point = [touch locationInView:self];
        vimgui_ios_touch((uint64_t)(__bridge void*)touch, point.x, point.y, down);
    }
}
- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    [self forwardTouches:touches down:YES];
    [super touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    [self forwardTouches:touches down:YES];
    [super touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    [self forwardTouches:touches down:NO];
    [super touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    [self forwardTouches:touches down:NO];
    [super touchesCancelled:touches withEvent:event];
}
@end

@interface VImGuiViewController : UIViewController <MTKViewDelegate>
@end

@implementation VImGuiViewController
{
    id<MTLCommandQueue> _commandQueue;
    CFTimeInterval _lastFrameTime;
    BOOL _ready;
    BOOL _reportedFrame;
    int _tapCount;
    float _workspaceValue;
    void* _keyboard;
    char _text[256];
}

- (void)loadView
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    VImGuiView* view = [[VImGuiView alloc] initWithFrame:[UIScreen mainScreen].bounds device:device];
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    view.clearColor = MTLClearColorMake(0.08, 0.08, 0.08, 1.0);
    view.preferredFramesPerSecond = 60;
    view.delegate = self;
    self.view = view;
    if (device == nil)
    {
        write_status(@"metal_unavailable");
        return;
    }
    _commandQueue = [device newCommandQueue];
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::GetIO().IniFilename = nullptr;
    ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;
    // ImGui windows share this one MTKView; UIKit scenes/viewports are not used.
    ImGui::GetIO().ConfigFlags &= ~ImGuiConfigFlags_ViewportsEnable;
    ImGui::StyleColorsDark();
    _ready = _commandQueue != nil && vimgui_ios_init() && vimgui_metal_init((__bridge void*)device);
    if (!_ready)
        write_status(@"backend_init_failed");
    else
        _keyboard = vimgui_ios_keyboard_create((__bridge void*)view);
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    (void)view;
    (void)size;
}

- (void)drawInMTKView:(MTKView*)view
{
    if (!_ready)
        return;
    MTLRenderPassDescriptor* pass = view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (pass == nil || drawable == nil)
        return;

    const CFTimeInterval now = CACurrentMediaTime();
    const float delta = _lastFrameTime > 0 ? (float)(now - _lastFrameTime) : 1.0f / 60.0f;
    _lastFrameTime = now;
    const CGSize points = view.bounds.size;
    const float scale = points.width > 0 ? view.drawableSize.width / points.width : 1.0f;
    vimgui_metal_new_frame((__bridge void*)pass);
    vimgui_ios_new_frame(points.width, points.height, scale, delta);
    ImGui::NewFrame();
    const bool side_by_side = points.width > points.height;
    const float window_width = side_by_side ? (points.width - 48.0f) * 0.5f : points.width - 32.0f;
    const float window_height = side_by_side ? points.height - 80.0f : 180.0f;
    int visible_windows = 0;
    ImGui::SetNextWindowPos(ImVec2(16.0f, 60.0f), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(window_width, window_height), ImGuiCond_FirstUseEver);
    if (ImGui::Begin("Controls"))
    {
        ++visible_windows;
        ImGui::Text("UIKit points: %.0f x %.0f, scale %.1f", points.width, points.height, scale);
        if (ImGui::Button("Tap here"))
            ++_tapCount;
        ImGui::SameLine();
        ImGui::Text("count = %d", _tapCount);
        ImGui::InputText("Text", _text, sizeof(_text));
    }
    ImGui::End();

    ImGui::SetNextWindowPos(ImVec2(side_by_side ? window_width + 32.0f : 16.0f,
                                  side_by_side ? 60.0f : 256.0f), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(window_width, window_height), ImGuiCond_FirstUseEver);
    if (ImGui::Begin("Workspace"))
    {
        ++visible_windows;
        ImGui::TextWrapped("A second ImGui window in the same Metal view.");
        ImGui::SliderFloat("Value", &_workspaceValue, 0.0f, 1.0f);
        ImGui::TextWrapped("Drag either title bar to arrange the workspace.");
    }
    ImGui::End();
    ImGui::Render();
    if (_keyboard != nullptr)
        vimgui_ios_keyboard_set_visible(_keyboard, vimgui_ios_wants_text_input());

    id<MTLCommandBuffer> buffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
    if (encoder == nil)
        return;
    vimgui_metal_render_draw_data(ImGui::GetDrawData(), (__bridge void*)buffer, (__bridge void*)encoder);
    [encoder endEncoding];
    [buffer presentDrawable:drawable];
    if (!_reportedFrame)
    {
        _reportedFrame = YES;
        const BOOL two_windows_visible = visible_windows == 2;
        [buffer addCompletedHandler:^(id<MTLCommandBuffer> completed) {
            write_status(completed.status != MTLCommandBufferStatusCompleted
                             ? @"frame_failed"
                             : (two_windows_visible ? @"multi_window_frame_completed"
                                                    : @"multi_window_missing"));
        }];
    }
    [buffer commit];
}

- (void)dealloc
{
    vimgui_ios_keyboard_destroy(_keyboard);
    if (_ready)
    {
        vimgui_metal_shutdown();
        vimgui_ios_shutdown();
    }
    if (ImGui::GetCurrentContext() != nullptr)
        ImGui::DestroyContext();
}
@end

@interface VImGuiAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow* window;
@end

@implementation VImGuiAppDelegate
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)options
{
    (void)application;
    (void)options;
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[VImGuiViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char** argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([VImGuiAppDelegate class]));
    }
}
