/* FSController */

#import <Cocoa/Cocoa.h>

@class FloatingWindow;

@interface FSController : NSObject
{
    IBOutlet FloatingWindow *statWindow;
    IBOutlet NSWindow *prefWindow;
    IBOutlet NSUserDefaultsController *defaultController;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSTableView *appTable;
    
    NSStatusItem *statusItem;
    NSTimer *pollTimer;
    NSMutableArray *cpuViews;
    NSView *netView;
    NSMutableArray *autoHideAppArray;
    BOOL isHidden;

}

- (IBAction)showPrefWindow:sender;
- (IBAction)applyPrefChanges:sender;
- (IBAction)revertPrefChanges:sender;
- (IBAction)showAboutPanel:sender;
- (IBAction)addAutoHideApp:sender;
- (IBAction)removeAutoHideApp:sender;

@end
