//
//  AppController.h
//

#import <Cocoa/Cocoa.h>

@interface NSFlipImageView : NSImageView
{
	BOOL flipped;
}
- (void) setFlipped:(BOOL) flag;
@end

@interface AppController : NSObject
{
    IBOutlet NSTextField  *tf;
    IBOutlet NSWindow  *win;
	IBOutlet NSWindow  *toolWin;
	/* NSMenuView */ id v;
	IBOutlet NSTextField  *cont;
	IBOutlet NSTableView  *buttonTable;
	IBOutlet NSClipView *clipView;
	IBOutlet NSSlider *kvoSlider;
	IBOutlet NSPathControl *pathControl;
	IBOutlet NSImageView *imageDrawing;
	IBOutlet NSMenuItem *longMenu;
	IBOutlet NSFlipImageView *rotation;
	IBOutlet NSView *alignmentView;
	IBOutlet NSPopUpButton *alignmentButton;
	IBOutlet NSPopUpButton *contentToShow;
	IBOutlet NSButton *flip;
}

- (IBAction) doSomething:(id) Sender;
- (IBAction) printBezelStyle:(id) Sender;
- (IBAction) periodic:(id) Sender;
- (IBAction) horizClipView:(id) Sender;
- (IBAction) vertClipView:(id) Sender;
- (IBAction) scroll:(id) sender;
- (IBAction) singleClick:(id) sender;
- (IBAction) rotate:(id) sender;
- (int) alignment;
- (int) contentToShow;
- (BOOL) isFlipped;
- (IBAction) changed:(id) sender;

@end


