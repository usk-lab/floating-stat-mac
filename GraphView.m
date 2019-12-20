#import <mach/mach.h>
#import <mach/mach_error.h>

#import "NSUserDefaults-FSExt.h"
#import "GraphView.h"
#import "FloatingWindow.h"

@implementation GraphView

- (void)clearGraph
{
    [graphImage lockFocus];
    
    NSRect rect;
    rect.origin = NSMakePoint(0, 0);
    rect.size = [graphImage size];
    rect.size.height -= [self topMargin];
    [[NSColor clearColor] set];
    NSRectFill(rect);
    
    [graphImage unlockFocus];
}

- (float)topMargin
{
    return 12.0;
}

- (void)dealloc
{
    NSLog(@"GraphView dealloc");
    [graphImage release];
    [graphTitle release];
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) == nil) return nil;

    graphImage = [[NSImage alloc] initWithSize:[self bounds].size];
    
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSRect bounds = [self bounds];

    [[def unarchivedObjectForKey:@"BackgroundFillColor"] set];
    NSRectFill(bounds);
    [graphImage compositeToPoint:bounds.origin operation:NSCompositingOperationSourceOver];
}

- (void)setTitle:(NSString *)title
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

    [graphImage lockFocus];
    graphTitle = [title retain];
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];
    [attr setObject:[NSFont fontWithName:@"Helvetica Bold" size:12] forKey:NSFontAttributeName];
    [attr setObject:[def unarchivedObjectForKey:@"TextColor"] forKey:NSForegroundColorAttributeName];
    [graphTitle drawAtPoint:NSMakePoint(1, [graphImage size].height - [self topMargin] - 1) withAttributes:attr];
    [graphImage unlockFocus];
}

- (BOOL)isOpaque
{
    return YES;
}

@end
