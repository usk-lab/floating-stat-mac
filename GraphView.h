/* FloatStatView */

#import <Cocoa/Cocoa.h>

@interface GraphView : NSView
{
    NSString *graphTitle;
    NSImage *graphImage;
}

- (void)clearGraph;
- (float)topMargin;
- (void)setTitle:(NSString *)title;

@end
