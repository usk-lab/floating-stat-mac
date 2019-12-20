/* FloatStatView */

#import <Cocoa/Cocoa.h>
#import "GraphView.h"

@interface CPUGraphView : GraphView
{
    int cpuNumber;
    NSTimer *redrawTimer;
    processor_info_array_t prevInfoArray;
    
    NSMutableArray *cpuGraphElements;
}

+ (int)getCPUCount;

- (id)initWithFrame:(NSRect)frameRect cpuNumber:(int)cpuNum;

@end
