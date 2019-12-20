/* FloatStatView */

#import <Cocoa/Cocoa.h>

@interface NetGraphView : GraphView
{
    NSTask *task;
    NSMutableArray *inBpsArray, *outBpsArray;
    //float inBpsPrev, outBpsPrev;
}
@end
