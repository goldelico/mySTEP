//
//  NSMenuItemCell.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Mar 29 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//
//	Author:	H. N. Schaller <hns@computer.org>
//	Date:	Apr 2006 - aligned with 10.4
//  licensed under the LGPL
//

#import <AppKit/NSButtonCell.h>
#import <AppKit/NSMenuItem.h>

@class NSMenuView;

@interface NSMenuItemCell : NSButtonCell
{
    @protected
	NSMenuItem	*menuItem;				// the menuItem we will view
    NSSize		size;					// total size
    float		stateImageWidth;
    float		imageWidth;
    float		titleWidth;
    float		keyEquivalentWidth;
    int			keyEquivGlyphWidth;
	BOOL		needsSizing;			// recalculate size if needed
	BOOL		needsDisplay;
}

- (void) calcSize;	// calculate size - including pading and aligment for vertical menus
- (void) drawBorderAndBackgroundWithFrame:(NSRect) frame inView:(NSView *) view;
- (void) drawImageWithFrame:(NSRect) frame inView:(NSView *) view;
- (void) drawKeyEquivalentWithFrame:(NSRect) frame inView:(NSView *) view;
- (void) drawSeparatorItemWithFrame:(NSRect) frame inView:(NSView *) view;
- (void) drawStateImageWithFrame:(NSRect) frame inView:(NSView *) view;
- (void) drawTitleWithFrame:(NSRect) frame inView:(NSView *) view;
- (NSRect) imageRectForBounds:(NSRect) frame;
- (float) imageWidth;	// image width
- (BOOL) isHighlighted;
- (NSRect) keyEquivalentRectForBounds:(NSRect) frame;
- (float) keyEquivalentWidth;	// key equivalent width
- (NSMenuItem *) menuItem;
- (NSMenuView *) menuView;
- (BOOL) needsDisplay;
- (BOOL) needsSizing;
- (void) setHighlighted:(BOOL) flag;
- (void) setMenuItem:(NSMenuItem *) item;
- (void) setMenuView:(NSMenuView *) menuView;
- (void) setNeedsDisplay:(BOOL) flag;
- (void) setNeedsSizing:(BOOL) flag;
- (void) setTag:(int) tag;
- (NSRect) stateImageRectForBounds:(NSRect) frame;
- (float) stateImageWidth;	// state image width
- (int) tag;
- (NSRect) titleRectForBounds:(NSRect) frame;
- (float) titleWidth;		// title width

@end
