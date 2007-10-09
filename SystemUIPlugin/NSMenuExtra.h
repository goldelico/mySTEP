//
// taken from Menu Cracker / Growl
//
// i.e. use as #import <SystemUIPlugin/NSMenuExtra.h>
//

#import <Cocoa/Cocoa.h>

// Reverse engineered from the ObjectiveC runtime.
// and description at http://cocoadevcentral.com/articles/000078.php

@interface NSMenuExtra : NSStatusItem
{
// @private
    NSBundle *_bundle;
	IBOutlet NSMenu *_menu;		// Not used - but allows to connect and setMenu: is called
    IBOutlet NSView *_view;		// Not used - NSStatusItem also has a view variable
    float _length;				// Not used - NSStatusItem also has a length variable
    struct {
        unsigned int customView:1;
        unsigned int menuDown:1;
        unsigned int reserved:30;
    } _flags;
    id _controller;
}

- (id) initWithBundle:(NSBundle *) bundle;
- (id) initWithBundle:(NSBundle *) bundle data:(NSData *) data;

- (void) willUnload;

- (NSBundle *) bundle;

- (BOOL) isMenuDown;
- (void) drawMenuBackground:(BOOL)flag;
- (void) popUpMenu:(NSMenu *)menu;

@end
