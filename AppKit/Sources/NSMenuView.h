//
//  NSMenuView.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Thu Mar 27 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//
//	Author:	H. N. Schaller <hns@computer.org>
//	Date:	Apr 2006 - aligned with 10.4
//
//  licensed under the LGPL
//

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

+ (float) menuBarHeight;

- (NSMenu *) attachedMenu;
- (NSMenuView *) attachedMenuView;
- (void) attachSubmenuForItemAtIndex:(int) index;
- (void) detachSubmenu;
- (NSFont *) font;
- (int) highlightedItemIndex;
- (float) horizontalEdgePadding;
- (float) imageAndTitleOffset;	// offset based on width and horizontalEdgePadding
- (float) imageAndTitleWidth;	// max. width of all cells image+title
- (int) indexOfItemAtPoint:(NSPoint) point;
- (id) initAsTearOff;	// returns nil
- (id) initWithFrame:(NSRect) frame;
- (NSRect) innerRect;
- (BOOL) isAttached;
- (BOOL) isHorizontal;
- (BOOL) isTornOff;	// always NO
- (void) itemAdded:(NSNotification *) notification;
- (void) itemChanged:(NSNotification *) notification;
- (void) itemRemoved:(NSNotification *) notification;
- (float) keyEquivalentOffset;	// offset based on width and horizontalEdgePadding
- (float) keyEquivalentWidth;	// max. width of all cells key equivalent
- (NSPoint) locationForSubmenu:(NSMenu *) submenu;
- (NSMenu *) menu;
- (NSMenuItemCell *) menuItemCellForItemAtIndex:(int) index;
- (BOOL) needsSizing;
- (void) performActionWithHighlighingForItemAtIndex:(int) index;
- (NSRect) rectOfItemAtIndex:(int) index;
- (void) setFont:(NSFont *) f;
- (void) setHighlightedItemIndex:(int) index;
- (void) setHorizontal:(BOOL) flag;
- (void) setHorizontalEdgePadding:(float) pad;
- (void) setMenu:(NSMenu *) m;
- (void) setMenuItemCell:(NSMenuItemCell *) cell forItemAtIndex:(int) index;
- (void) setNeedsDisplayForItemAtIndex:(int) index;
- (void) setNeedsSizing:(BOOL) flag;
- (void) setWindowFrameForAttachingToRect:(NSRect) frame onScreen:(NSScreen *) screen preferredEdge:(NSRectEdge) edge popUpSelectedItem:(int) index;
- (void) sizeToFit;
- (float) stateImageOffset;	// offset based on width and horizontalEdgePadding
- (float) stateImageWidth;	// max. width of all cells state image
- (BOOL) trackWithEvent:(NSEvent *) event;
- (void) update;
@end
