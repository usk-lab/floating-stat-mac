#import <mach/mach.h>
#import <mach/mach_error.h>

#import "CPUGraphView.h"
#import "NSUserDefaults-FSExt.h"

@implementation CPUGraphView

+ (int)getCPUCount
{
    natural_t cpuCount;
    processor_info_array_t infoArray;
    mach_msg_type_number_t infoCount;

    kern_return_t error = host_processor_info(mach_host_self(),
        PROCESSOR_CPU_LOAD_INFO, &cpuCount, &infoArray, &infoCount);
    if (error) {
        mach_error("host_processor_info error:", error);
        return -1;
    }
    vm_deallocate(mach_task_self(), (vm_address_t)infoArray, infoCount);
    return cpuCount;
}

- (NSDictionary *)_getCPULoad
{
    static NSString* stateName[] = { @"User", @"System", @"Idle", @"Nice" };

    natural_t cpuCount;
    processor_info_array_t infoArray;
    mach_msg_type_number_t infoCount;

    kern_return_t error = host_processor_info(mach_host_self(),
        PROCESSOR_CPU_LOAD_INFO, &cpuCount, &infoArray, &infoCount);
    if (error) {
        mach_error("host_processor_info error:", error);
        return nil;
    }

    if (prevInfoArray == nil) {
        prevInfoArray = malloc(sizeof(processor_cpu_load_info_data_t));
        bzero(prevInfoArray, sizeof(processor_cpu_load_info_data_t));
    }

    processor_cpu_load_info_data_t *curLoadInfo, *prvLoadInfo;
    curLoadInfo = (processor_cpu_load_info_data_t *)infoArray + cpuNumber;
    prvLoadInfo = (processor_cpu_load_info_data_t *)prevInfoArray;

    unsigned long totalTicks = 0;
    int state;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for (state = 0; state < CPU_STATE_MAX; state++) {
        unsigned long ticks = curLoadInfo->cpu_ticks[state] - prvLoadInfo->cpu_ticks[state];
        totalTicks += ticks;
    }

    for (state = 0; state < CPU_STATE_MAX; state++) {
        unsigned long ticks = curLoadInfo->cpu_ticks[state] - prvLoadInfo->cpu_ticks[state];
        [dict setObject:[NSNumber numberWithFloat:(float)ticks / totalTicks] forKey:stateName[state]];
    }
    
    memcpy(prevInfoArray, curLoadInfo, sizeof(processor_cpu_load_info_data_t));
    vm_deallocate(mach_task_self(), (vm_address_t)infoArray, infoCount);
    return dict;
}

- (void)_drawGraph:(NSTimer *)timer
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSDictionary *cpuInfo = [self _getCPULoad];
    NSDictionary *dict;
    NSMutableArray *dataArray = nil;
    NSSize size = [graphImage size];
    int i, c, dataSize;
    
    size.width -= 2;
    size.height -= ([self topMargin] + 1);

    for (i = 0; i < [cpuGraphElements count]; i++) {
        dict = [cpuGraphElements objectAtIndex:i];
        dataArray = [dict objectForKey:@"DataArray"];
        [dataArray
				insertObject:[cpuInfo objectForKey:[dict objectForKey:@"CPUInfoKey"]]
				atIndex:0];
        if ([dataArray count] > size.width)
			[dataArray removeObjectAtIndex:size.width];
    }
    dataSize = [dataArray count];
    
    [self clearGraph];

    [graphImage lockFocus];

    for (c = 0; c < dataSize; c++) {
        NSPoint point = NSMakePoint(size.width - c + 1.5, 1);
        NSBezierPath *path;
        for (i = 0; i < [cpuGraphElements count]; i++) {
            dict = [cpuGraphElements objectAtIndex:i];
            dataArray = [dict objectForKey:@"DataArray"];
            float usage = [[dataArray objectAtIndex:c] floatValue];
            path = [NSBezierPath bezierPath];
            [path moveToPoint:point];
            point.y += usage * size.height;
            [path lineToPoint:point];
            [[def unarchivedObjectForKey:[dict objectForKey:@"FillColor"]] set];
            [path stroke];
        }
    }
    
    [graphImage unlockFocus];
    
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
    NSLog(@"CPUGraphView dealloc");
    [cpuGraphElements release];
    if (prevInfoArray) free(prevInfoArray);
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect cpuNumber:(int)cpuNum
{
    if ((self = [super initWithFrame:frameRect]) == nil) return nil;

    //NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict;
    cpuGraphElements = [[NSMutableArray alloc] init];

    dict = [NSMutableDictionary dictionary];
    [dict setObject:@"User" forKey:@"CPUInfoKey"];
    [dict setObject:@"CPUUserFillColor" forKey:@"FillColor"];
    [dict setObject:[NSMutableArray array] forKey:@"DataArray"];
    [cpuGraphElements addObject:dict];

    dict = [NSMutableDictionary dictionary];
    [dict setObject:@"System" forKey:@"CPUInfoKey"];
    [dict setObject:@"CPUSystemFillColor" forKey:@"FillColor"];
    [dict setObject:[NSMutableArray array] forKey:@"DataArray"];
    [cpuGraphElements addObject:dict];

    dict = [NSMutableDictionary dictionary];
    [dict setObject:@"Nice" forKey:@"CPUInfoKey"];
    [dict setObject:@"CPUNiceFillColor" forKey:@"FillColor"];
    [dict setObject:[NSMutableArray array] forKey:@"DataArray"];
    [cpuGraphElements addObject:dict];
    
    cpuNumber = cpuNum;
    [self setTitle:[NSString stringWithFormat:@"CPU #%d", cpuNumber + 1]];
    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)window
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    if (window) {
        redrawTimer = [NSTimer scheduledTimerWithTimeInterval:[def floatForKey:@"CPUInterval"] target:self selector:@selector(_drawGraph:) userInfo:nil repeats:YES];
    } else {
        [redrawTimer invalidate];
        redrawTimer = nil;
    }
    [super viewWillMoveToWindow:window];
}

@end
