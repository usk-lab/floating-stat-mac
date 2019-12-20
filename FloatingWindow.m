#import "FloatingWindow.h"

@implementation FloatingWindow

- initWithContentRect:(NSRect)contentRect
        styleMask:(unsigned int)styleMask
        backing:(NSBackingStoreType)backingType
        defer:(BOOL)flag
{
    [super initWithContentRect:contentRect
                     styleMask:NSWindowStyleMaskBorderless //styleMask
        backing:backingType
        defer:flag];
    return self;
}

- (void)awakeFromNib
{
    [self setBackgroundColor:[NSColor clearColor]];
    [self setOpaque:NO];
    [self setHasShadow:NO];
    [self setLevel:NSStatusWindowLevel];
    [self setCanHide:NO];
}

- setFrameCenteredAt:(NSPoint)center
{
    NSRect screen = [[NSScreen mainScreen] frame];
    NSRect myFrame = [self frame];
    myFrame.origin = NSMakePoint(
            center.x - myFrame.size.width/2,
            center.y - myFrame.size.height/2);

    if (myFrame.origin.x < screen.origin.x)
        myFrame.origin.x = screen.origin.x;
    if (myFrame.origin.y < screen.origin.y)
        myFrame.origin.y = screen.origin.y;
    if (NSMaxX(myFrame) > NSMaxX(screen))
        myFrame.origin.x = NSMaxX(screen) - myFrame.size.width;
    if (NSMaxY(myFrame) > NSMaxY(screen))
        myFrame.origin.y = NSMaxY(screen) - myFrame.size.height;

    [self setFrameOrigin:myFrame.origin];
    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

#if 0
- (void)becomeKeyWindow
{
    [super becomeKeyWindow];
    [self setIgnoresMouseEvents:NO];
}

- (void)resignKeyWindow
{
    [super resignKeyWindow];
    [self setIgnoresMouseEvents:YES];
    [self orderOutWithFade:self];
}
#endif

- (void)_windowFader:(NSTimer *)timer
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    id userInfo = [timer userInfo];
    
    float alpha = (now - faderStartTimestamp) / FloatingWindowFaderDuration;
    if ([userInfo boolValue] == NO) alpha = 1.0 - alpha;
    
    if (alpha <= 0.0) {
        [self orderOut:self];
        [self setAlphaValue:1.0];
        [timer invalidate];
        fadeoutTimer = nil;
    } else if (alpha >= 1.0) {
        [self setAlphaValue:1.0];
        [timer invalidate];
        fadeoutTimer = nil;
    } else {
        [self setAlphaValue:alpha];
    }
}

- _orderWithFade:sender toFront:(BOOL)toFront
{
    [fadeoutTimer invalidate];
    faderStartTimestamp = [NSDate timeIntervalSinceReferenceDate];
    fadeoutTimer = [NSTimer
            scheduledTimerWithTimeInterval:FloatingWindowFaderRedrawInterval
            target:self
            selector:@selector(_windowFader:)
            userInfo:[NSNumber numberWithBool:toFront]
            repeats:YES];
    return self;
}

- orderOutWithFade:sender
{
    return [self _orderWithFade:sender toFront:NO];
}

- orderFrontWithFade:sender
{
    [self setAlphaValue:0.0];
    [self orderFront:self];
    return [self _orderWithFade:sender toFront:YES];
}

@end
