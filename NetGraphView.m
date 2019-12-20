#import <mach/mach.h>
#import <mach/mach_error.h>

#import "NSUserDefaults-FSExt.h"
#import "GraphView.h"
#import "NetGraphView.h"

const float logMin = 1.0e-4;

@implementation NetGraphView

- (void)_drawGraph
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSSize size = [graphImage size];
    float scale = [def integerForKey:@"NetScale"];
    int graphColumn = size.width - 2;
    int c;
    float v, px;
    size.height -= ([self topMargin] + 1);
    
    [self clearGraph];
    
    if ([inBpsArray count] > graphColumn)
			[inBpsArray removeObjectAtIndex:graphColumn];
    if ([outBpsArray count] > graphColumn)
			[outBpsArray removeObjectAtIndex:graphColumn];

    [graphImage lockFocus];

    [[def unarchivedObjectForKey:@"NetIncomingFillColor"] set];
    for (c = 0; c < [inBpsArray count]; c++) {
        v = [[inBpsArray objectAtIndex:c] floatValue];
		//NSLog(@"2) v = %.2f", v);
		px = graphColumn - c + 1.5;
        [NSBezierPath
				strokeLineFromPoint:NSMakePoint(px, size.height)
				toPoint:NSMakePoint(px, size.height - log10(v + 1) / scale * size.height / 2)];
    }

    [[def unarchivedObjectForKey:@"NetOutgoingFillColor"] set];
    for (c = 0; c < [inBpsArray count]; c++) {
        v = [[outBpsArray objectAtIndex:c] floatValue];
		//NSLog(@"2) v = %.2f", v);
		px = graphColumn - c + 1.5;
        [NSBezierPath
				strokeLineFromPoint:NSMakePoint(px, 1)
				toPoint:NSMakePoint(px, 1 + log10(v + 1) / scale * size.height / 2)];
    }

    [graphImage unlockFocus];
    [self setNeedsDisplay:YES];
}

- (void)_readFromNetstat:(NSNotification *)notif
{
    NSFileHandle *fh = (NSFileHandle *)[notif object];
    NSData *theData = [[notif userInfo] objectForKey:NSFileHandleNotificationDataItem];
    char *data;
    unsigned int ip, ib, ie, op, oe, ob, oc;
    if ([theData length] == 0) 
	return ;

    // obtain the statistics for a certain interface(s)
    data = (char *)[theData bytes];
    if (sscanf( data, "%d %d %d %d %d %d %d", &ip, &ie, &ib, &op, &oe, &ob, &oc ) > 0) {
	//NSLog( @"%d %d %d %d %d %d %d", ip, ib, ie, op, oe, ob, oc );
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        float interval = [def integerForKey:@"NetInterval"];
        [inBpsArray
				insertObject:[NSNumber numberWithFloat:(ib / interval)]
				atIndex:0];
        [outBpsArray
				insertObject:[NSNumber numberWithFloat:(ob / interval)]
				atIndex:0];
        [self _drawGraph];
    }

    [fh readInBackgroundAndNotify];
}

- (void)_startNetstat
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    task = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_readFromNetstat:) name:NSFileHandleReadCompletionNotification object:[pipe fileHandleForReading]];
    [task setLaunchPath:@"/usr/sbin/netstat"];
    [task setArguments:[NSArray arrayWithObjects:@"-w", [NSString stringWithFormat:@"%ld", (long)[def integerForKey:@"NetInterval"]], nil]];
    [task launch];
    [[pipe fileHandleForReading] readInBackgroundAndNotify];
}

- (void)_stopNetstat
{
    [task terminate];
    [task release];
    task = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    NSLog(@"NetGraphView dealloc");
    [inBpsArray release];
    [outBpsArray release];
    [super dealloc];
}
   
- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) == nil) return nil;
    [self setTitle:@"Network"];
    inBpsArray = [[NSMutableArray alloc] init];
    outBpsArray = [[NSMutableArray alloc] init];
    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)window
{
    if (window)
        [self _startNetstat];
    else
        [self _stopNetstat];
    [super viewWillMoveToWindow:window];
}

@end
