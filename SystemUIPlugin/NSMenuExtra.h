//
// taken from Menu Cracker
// and description at http://cocoadevcentral.com/articles/000078.php
//
// i.e. use as #import <SystemUIPlugin/NSMenuExtra.h>
//

#import <Cocoa/Cocoa.h>

// Reverse engineered from the ObjectiveC runtime.

@interface NSMenuExtra  : NSStatusItem
{
// @private
    NSBundle *_bundle;
	NSMenu *_menu;
    NSView *_view;
    float _length;
    struct {
        unsigned int customView:1;
        unsigned int menuDown:1;
        unsigned int reserved:30;
    } _flags;
    id _controller;
}

- (id)initWithBundle:(NSBundle *) bundle;
- (id)initWithBundle:(NSBundle *) bundle data:(NSData *) data;

- (void)willUnload;

- (NSBundle *)bundle;

- (BOOL) isMenuDown;
- (void) drawMenuBackground:(BOOL)flag;
- (void) popUpMenu:(NSMenu *)menu;

@end
