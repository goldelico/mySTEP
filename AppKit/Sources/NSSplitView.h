/* 
   NSSplitView.h

   Allows multiple views to share a region in a window

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Robert Vasvari <vrobi@ddrummer.com>
   Date: Jul 1998
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5    
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSplitView
#define _mySTEP_H_NSSplitView

#import <AppKit/NSView.h>

@class NSImage, NSColor, NSNotification;

@interface NSSplitView : NSView
{
	id _delegate;
	id splitCursor;
	NSImage *dimpleImage;
	NSColor *backgroundColor;
	NSColor *dividerColor;
	NSString*_autosaveName;
	int _dividerThickness;
	int _draggedBarWidth;
	BOOL _isVertical;
	BOOL _isPaneSplitter;
}

- (void) adjustSubviews;
- (NSString *) autosaveName;
- (id) delegate;
- (CGFloat) dividerThickness;  		// defaults to 8
- (void) drawDividerInRect:(NSRect) aRect; 
- (BOOL) isPaneSplitter; 
- (BOOL) isSubviewCollapsed:(NSView *) subview; 
- (BOOL) isVertical;
- (CGFloat) maxPossiblePositionOfDividerAtIndex:(NSInteger) index; 
- (CGFloat) minPossiblePositionOfDividerAtIndex:(NSInteger) index; 
- (void) setAutosaveName:(NSString *) name; 
- (void) setDelegate: (id)anObject;
- (void) setIsPaneSplitter:(BOOL) flag; 
- (void) setPosition:(CGFloat) pos ofDividerAtIndex:(NSInteger) index; 
- (void) setVertical: (BOOL) flag;

@end


@interface NSObject(NSSplitViewDelegate)

- (NSRect) splitView:(NSSplitView *) sender additionalEffectiveRectOfDividerAtIndex:(NSInteger) index;
- (BOOL) splitView:(NSSplitView *) sender canCollapseSubview:(NSView *) subview; 
- (CGFloat) splitView:(NSSplitView *) sender constrainMaxCoordinate:(CGFloat) max ofSubviewAt:(NSInteger) index;
- (CGFloat) splitView:(NSSplitView *) sender constrainMinCoordinate:(CGFloat) min ofSubviewAt:(NSInteger) index; 
- (CGFloat) splitView:(NSSplitView *) sender constrainSplitPosition:(CGFloat) pos ofSubviewAt:(NSInteger) index;
- (NSRect) splitView:(NSSplitView *) sender 
	   effectiveRect:(NSRect) effectiveRect 
		forDrawnRect:(NSRect) rect 
	ofDividerAtIndex:(NSInteger)index; 
- (void) splitView:(NSSplitView *) sender resizeSubviewsWithOldSize:(NSSize) oldSize;
- (BOOL) splitView:(NSSplitView *) sender shouldCollapseSubview:(NSView *) subview forDoubleClickOnDividerAtIndex:(NSInteger) index;
- (void) splitViewDidResizeSubviews:(NSNotification *) notification;
- (void) splitViewWillResizeSubviews:(NSNotification *) notification;

/* NOT IN API */

- (void) splitView:(NSSplitView *) sender 
	constrainMinCoordinate:(CGFloat *) min
	 maxCoordinate:(CGFloat *) max 
	   ofSubviewAt:(NSInteger) offset;

@end

extern NSString *NSSplitViewDidResizeSubviewsNotification;
extern NSString *NSSplitViewWillResizeSubviewsNotification;

#endif /* _mySTEP_H_NSSplitView */
