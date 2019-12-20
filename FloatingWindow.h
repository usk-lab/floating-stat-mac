/* AppSwitchWindow */

#import <Cocoa/Cocoa.h>

#define FloatingWindowFaderDuration 0.1f
#define FloatingWindowFaderRedrawInterval (NSTimeInterval)(1/30.0f)

@class AppSwitchView;
@class WindowFader;

@interface FloatingWindow : NSWindow
{
    NSTimeInterval faderStartTimestamp;
    NSTimer *fadeoutTimer;
}

- initWithContentRect:(NSRect)contentRect
        styleMask:(unsigned int)styleMask
        backing:(NSBackingStoreType)backingType
        defer:(BOOL)flag;
- setFrameCenteredAt:(NSPoint)center;

#if 0
- (BOOL)canBecomeKeyWindow;
- (void)becomeKeyWindow;
- (void)resignKeyWindow;
#endif
- orderOutWithFade:sender;
- orderFrontWithFade:sender;

@end
