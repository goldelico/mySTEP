/* 
   NSSplitView.h

   Allows multiple views to share a region in a window

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Robert Vasvari <vrobi@ddrummer.com>
   Date: Jul 1998
   
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
	int _dividerThickness;
	int _draggedBarWidth;
	BOOL _isVertical;
}

- (void) setDelegate: (id)anObject;
- (id) delegate;
- (void) adjustSubviews;
- (void) drawDividerInRect: (NSRect)aRect;

- (void) setVertical: (BOOL)flag;		// Vert splitview has a vert split bar 
- (BOOL) isVertical;
									// extension methods to make it more usable
- (float) dividerThickness;  		// defaults to 8
- (void) setDividerThickNess: (float)newWidth;
- (float) draggedBarWidth;
- (void) setDraggedBarWidth: (float)newWidth;
								// if flag is yes, dividerThickness is reset to 
								// the height/width of the dimple image + 1;
- (void) setDimpleImage:(NSImage *)anImage resetDividerThickness: (BOOL)flag;
- (NSImage *) dimpleImage;
- (NSColor *) backgroundColor;
- (void) setBackgroundColor:(NSColor *)aColor;
- (NSColor *) dividerColor;
- (void) setDividerColor:(NSColor *)aColor;

@end


@interface NSObject(NSSplitViewDelegate)

- (void) splitView:(NSSplitView *)sender 
		 resizeSubviewsWithOldSize:(NSSize)oldSize;
- (void) splitView:(NSSplitView *)sender 
		 constrainMinCoordinate:(float *)min 
		 maxCoordinate:(float *)max 
		 ofSubviewAt:(int)offset;
- (void) splitViewWillResizeSubviews:(NSNotification *)notification;
- (void) splitViewDidResizeSubviews:(NSNotification *)notification;

@end

extern NSString *NSSplitViewDidResizeSubviewsNotification;	  // Notifications
extern NSString *NSSplitViewWillResizeSubviewsNotification;

#endif /* _mySTEP_H_NSSplitView */
