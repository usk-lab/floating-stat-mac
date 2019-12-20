#import "FSController.h"
#import "FloatingWindow.h"
#import "CPUGraphView.h"
#import "NetGraphView.h"

@implementation FSController

- (void)_pollTimerHandler:(NSTimer *)timer
{
    NSDictionary *appDict;
    NSString *appName;
    BOOL shouldHide = NO;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoHide"]) {
        shouldHide = NSMouseInRect([NSEvent mouseLocation], [statWindow frame], NO);
    }

    appDict = [[NSWorkspace sharedWorkspace] activeApplication];;
    appName = [[[appDict objectForKey:@"NSApplicationPath"] pathComponents] lastObject];
    if ([autoHideAppArray indexOfObject:appName] != NSNotFound) {
        shouldHide = YES;
    }
    
    if (shouldHide ^ isHidden) {
        if (shouldHide) {
            [statWindow orderOutWithFade:self];
        } else {
            [statWindow orderFrontWithFade:self];
        }
        isHidden = shouldHide;
    }
}

static const float graphSize = 64;
static const float spacing = 2;

NSRect _graphRect(int n)
{
    NSRect rect;
    rect.origin.x = (graphSize + spacing) * n;
    rect.origin.y = 0;
    rect.size.width = graphSize;
    rect.size.height = graphSize;
    return rect;
}

- (void)_showStatusMenu
{
    if (statusItem) return;
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
    statusItem.button.image = [NSImage imageNamed:@"StatusBarIcon"];
    statusItem.button.cell.highlighted = true;
    [statusItem setMenu:statusMenu];
}

- (void)_hideStatusMenu
{
    if (!statusItem) return;
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    [bar removeStatusItem:statusItem];
    [statusItem release];
    statusItem = nil;
}

- (void)_setupStatusMenu
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

    if ([def boolForKey:@"ShowIconOnMenuBar"]) {
        [self _showStatusMenu];
    } else {
        [self _hideStatusMenu];
    }
}

- (void)_setupStatWindow
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSView *contentView = [statWindow contentView];
    int numCPU = [CPUGraphView getCPUCount];
    int nrView = 0;
    int cpu;

    if ([def boolForKey:@"ShowNetGraph"]) {
        if (!netView) {
            netView = [[NetGraphView alloc] initWithFrame:_graphRect(nrView)];
            [contentView addSubview:netView];
        } else {
            [netView setFrame:_graphRect(nrView)];
        }
        nrView++;
    } else {
        if (netView) {
            [netView removeFromSuperview];
            [netView release];
            netView = nil;
        }
    }

    if ([def boolForKey:@"ShowCPUGraph"]) {
        if (!cpuViews) {
            cpuViews = [[NSMutableArray alloc] init];
            for (cpu = 0; cpu < numCPU; cpu ++) {
                NSView *v = [[[CPUGraphView alloc] initWithFrame:_graphRect(nrView + cpu) cpuNumber:cpu] autorelease];
                [contentView addSubview:v];
                [cpuViews addObject:v];
            }
        } else {
            for (cpu = 0; cpu < numCPU; cpu ++) {
                [[cpuViews objectAtIndex:cpu] setFrame:_graphRect(nrView + cpu)];
            }
        }
        nrView += numCPU;
    } else {
        if (cpuViews) {
            for (cpu = 0; cpu < numCPU; cpu ++) {
                [[cpuViews objectAtIndex:cpu] removeFromSuperview];
            }
            [cpuViews release];
            cpuViews = nil;
        }
    }
    
    // Calculate the rect which contains dock but not menuBar
    // (assuming that menu bar is always on the top edge of the screen)
    float menuBarHeight = [[NSStatusBar systemStatusBar] thickness];
    NSRect screenRect = [[NSScreen mainScreen] frame];
    screenRect.size.height -= menuBarHeight;
    
    // Position the status window...
    NSRect windowRect;
    windowRect.size.width = (graphSize + spacing) * nrView - spacing;
    windowRect.size.height = graphSize;

    NSInteger winPos = [def integerForKey:@"WindowPosition"];
    if (winPos == 0 || winPos == 1) {   // top
        windowRect.origin.y = NSMaxY(screenRect) - windowRect.size.height;
    } else {    // bottom
        windowRect.origin.y = NSMinY(screenRect);
    }
    if (winPos == 0 || winPos == 2) {   // left
        windowRect.origin.x = NSMinX(screenRect);
    } else {    // right
        windowRect.origin.x = NSMaxX(screenRect) - windowRect.size.width;
    }
    [statWindow setFrame:windowRect display:NO];
	
	// Place status window in all "Spaces"
	if ([statWindow respondsToSelector:@selector(setCollectionBehavior:)]) {
		[statWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	}
}

- (void)_userDefaultsDidChange:(NSNotification *)notif
{
    //NSLog(@"UserDefaults has been changed. Applying changes...");
    [self _setupStatWindow];
}

void _reopenApplication(ProcessSerialNumber psn)
{
    OSStatus err;
    AEAddressDesc targetDesc;
    AppleEvent ev;
    
    err = AECreateDesc(typeProcessSerialNumber, &psn, sizeof(psn), &targetDesc);
    err = AECreateAppleEvent(kCoreEventClass, kAEReopenApplication, &targetDesc, kAutoGenerateReturnID, kAnyTransactionID, &ev);
    err = AESendMessage(&ev, NULL, kAENoReply, kAEDefaultTimeout);
}

- init
{
    [super init];

    // Check if FloatingStat is already running
    ProcessSerialNumber psn = {kNoProcess, kNoProcess}, myPsn;
    NSDictionary *pid;
    Boolean psnIsSame;
    GetCurrentProcess(&myPsn);
    while (GetNextProcess(&psn) != procNotFound) {
        pid = (NSDictionary *)ProcessInformationCopyDictionary(
                &psn, kProcessDictionaryIncludeAllInformationMask);
        SameProcess(&psn, &myPsn, &psnIsSame);
        if ([[pid objectForKey:@"CFBundleName"] isEqualToString:@"FloatingStat"]
                && !psnIsSame)  {
            NSLog(@"Another copy is running.");
            _reopenApplication(psn);
            [NSApp terminate:self];
        }
    }

    // Load default user defaults
    NSDictionary *defaultDefaults =
            [NSDictionary dictionaryWithContentsOfFile:
                [[NSBundle mainBundle]
                    pathForResource:@"DefaultDefaults"
                    ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
    
    return self;
}

- (BOOL)windowShouldClose:sender
{
    [defaultController save:self];
    [self _setupStatusMenu];
    [[NSColorPanel sharedColorPanel] orderOut:self];
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
    [defaultController setAppliesImmediately:NO];

    [statWindow setIgnoresMouseEvents:YES];
    [self _setupStatusMenu];
    [self _setupStatWindow];
    [statWindow orderFront:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    
    autoHideAppArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoHideApplications"] mutableCopy];

    pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_pollTimerHandler:) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notif
{
    // Making sure that netstat process is quitted
    [netView removeFromSuperview];
    [netView release];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [self showPrefWindow:self];
    return NO;
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notif
{
    [self _setupStatWindow];
}



- (IBAction)showPrefWindow:sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [self _showStatusMenu];
    [prefWindow makeKeyAndOrderFront:self];
}

- (IBAction)applyPrefChanges:sender
{
    [defaultController save:self];
}

- (IBAction)revertPrefChanges:sender
{
    [defaultController revert:self];
}

- (IBAction)showAboutPanel:sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:self];
}

- (void)_didEndOpenSheet:(NSOpenPanel *)panel
        returnCode:(int)ret contextInfo:(void *)context
{
    int idx;
    NSArray *filesToOpen;
    NSString *appName;
    
    if (ret != NSOKButton) return;

    filesToOpen = [panel filenames];
    for (idx = 0; idx < [filesToOpen count]; idx++) {
        appName = [[[filesToOpen objectAtIndex:idx] pathComponents] lastObject];
        [autoHideAppArray addObject:appName];
    }
    [[NSUserDefaults standardUserDefaults] setObject:autoHideAppArray forKey:@"AutoHideApplications"];
    [appTable reloadData];
}

- (IBAction)addAutoHideApp:sender
{
    NSArray *fileTypes = [NSArray arrayWithObject:@"app"];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setAllowsMultipleSelection:YES];
    [panel setCanChooseFiles:YES];
    [panel beginSheetForDirectory:@"/Applications"
            file:nil
            types:fileTypes
            modalForWindow:[sender window]
            modalDelegate:self
            didEndSelector:
                @selector(_didEndOpenSheet:returnCode:contextInfo:)
            contextInfo:nil];
}

- (void)_didEndRemoveAleartSheet:(NSWindow *)sheet
        returnCode:(int)ret contextInfo:ctx
{
    if (ret == NSAlertDefaultReturn) return;

    int row;

    row  = [appTable selectedRow];
    [autoHideAppArray removeObjectAtIndex:row];
    
    [[NSUserDefaults standardUserDefaults] setObject:autoHideAppArray forKey:@"AutoHideApplications"];
    [appTable reloadData];
}

- (IBAction)removeAutoHideApp:sender
{
    int row;
    NSString *appPath, *appName;
    
    row  = [appTable selectedRow];
    appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:[autoHideAppArray objectAtIndex:row]];
    appName = [[[NSFileManager defaultManager] componentsToDisplayForPath:appPath] lastObject];

    NSBeginAlertSheet(
        NSLocalizedString(@"Remove Application", @""),
        NSLocalizedString(@"Cancel", @""),
        NSLocalizedString(@"Yes", @""),
        nil,
        [sender window],
        self,
        @selector(_didEndRemoveAleartSheet:returnCode:contextInfo:),
        NULL,
        nil,
        NSLocalizedString(@"Remove %@?", @""),
        appName);
}

// Methods for TableView

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [autoHideAppArray count];
}

- tableView:(NSTableView *)tableView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
        row:(int)row
{
    NSString *colID = [tableColumn identifier];
    NSString *appPath;
    
    appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:[autoHideAppArray objectAtIndex:row]];
    
    if ([colID isEqualToString:@"appIcon"]) {
        return [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    }

    if ([colID isEqualToString:@"appName"]) {
        return [[[NSFileManager defaultManager] componentsToDisplayForPath:appPath] lastObject];
    }
    
    return nil;
}

@end
