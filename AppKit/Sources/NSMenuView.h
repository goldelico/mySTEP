/*
	NSMenuView.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Thu Mar 27 2003.
	Copyright (c) 2003 DSITRI. All rights reserved.

	Author:	H. N. Schaller <hns@computer.org>
	Date:	Apr 2006 - aligned with 10.4
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. November 2007 - aligned with 10.5

	licensed under the LGPL
*/

#import <Foundation/Foundation.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSFont.h>

@class NSPanel;

@interface NSMenuView : NSView
{
    @private
	NSMenu *_menumenu;		// the menu data to be displayed (not the context menu defined by NSResponder!)
	NSFont *_font;
	NSPanel *_menuWindow;
	NSMenuView *_attachedMenuView;
	NSMutableArray *_cells;	// all cells
	NSRect *_rectOfCells;	// sized using realloc()
    int _highlightedItemIndex;
    float _horizontalEdgePadding;
    float _imageAndTitleOffset;
    float _imageAndTitleWidth;
    float _keyEquivalentOffset;
    float _keyEquivalentWidth;
    float _stateImageOffset;
    float _stateImageWidth;
    BOOL _needsSizing;
    BOOL _isHorizontal;
    BOOL _isResizingHorizontally;
	BOOL _isStatusBar;
	BOOL _isContextMenu;
	BOOL _isTornOff;
}

+ (CGFloat) menuBarHeight;

- (NSMenu *) attachedMenu;
- (NSMenuView *) attachedMenuView;
- (void) attachSubmenuForItemAtIndex:(NSInteger) index;
- (void) detachSubmenu;
- (NSFont *) font;
- (NSInteger) highlightedItemIndex;
- (CGFloat) horizontalEdgePadding;
- (CGFloat) imageAndTitleOffset;	// offset based on width and horizontalEdgePadding
- (CGFloat) imageAndTitleWidth;	// max. width of all cells image+title
- (NSInteger) indexOfItemAtPoint:(NSPoint) point;
- (id) initAsTearOff;	// returns nil
- (id) initWithFrame:(NSRect) frame;
- (NSRect) innerRect;
- (BOOL) isAttached;
- (BOOL) isHorizontal;
- (BOOL) isTornOff;	// always NO
- (void) itemAdded:(NSNotification *) notification;
- (void) itemChanged:(NSNotification *) notification;
- (void) itemRemoved:(NSNotification *) notification;
- (CGFloat) keyEquivalentOffset;	// offset based on width and horizontalEdgePadding
- (CGFloat) keyEquivalentWidth;	// max. width of all cells key equivalent
- (NSPoint) locationForSubmenu:(NSMenu *) submenu;
- (NSMenu *) menu;
- (NSMenuItemCell *) menuItemCellForItemAtIndex:(NSInteger) index;
- (BOOL) needsSizing;
- (void) performActionWithHighlighingForItemAtIndex:(NSInteger) index;
- (NSRect) rectOfItemAtIndex:(NSInteger) index;
- (void) setFont:(NSFont *) f;
- (void) setHighlightedItemIndex:(NSInteger) index;
- (void) setHorizontal:(BOOL) flag;
- (void) setHorizontalEdgePadding:(CGFloat) pad;
- (void) setMenu:(NSMenu *) m;
- (void) setMenuItemCell:(NSMenuItemCell *) cell forItemAtIndex:(NSInteger) index;
- (void) setNeedsDisplayForItemAtIndex:(NSInteger) index;
- (void) setNeedsSizing:(BOOL) flag;
- (void) setWindowFrameForAttachingToRect:(NSRect) frame onScreen:(NSScreen *) screen preferredEdge:(NSRectEdge) edge popUpSelectedItem:(NSInteger) index;
- (void) sizeToFit;
- (CGFloat) stateImageOffset;	// offset based on width and horizontalEdgePadding
- (CGFloat) stateImageWidth;	// max. width of all cells state image
- (BOOL) trackWithEvent:(NSEvent *) event;
- (void) update;

@end
