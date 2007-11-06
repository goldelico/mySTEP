/*
   NSClipView.h

   Document scrolling content view of a scroll view.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007 
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSClipView
#define _mySTEP_H_NSClipView

#import <AppKit/NSView.h>

@class NSNotification;
@class NSCursor;
@class NSColor;
@class NSWindow;

@interface NSClipView : NSView
{
	NSColor *_backgroundColor;
	NSView *_documentView;
	NSCursor *_cursor;

    struct __clipFlags {
		unsigned int docIsFlipped:1;
		unsigned int copiesOnScroll:1;
		unsigned int drawsBackground:1;
		unsigned int reserved:5;
		} _clip;
}

- (BOOL) autoscroll:(NSEvent *) event;
- (NSColor *) backgroundColor;
- (NSPoint) constrainScrollPoint:(NSPoint) proposedNewOrigin;
- (BOOL) copiesOnScroll;
- (NSCursor *) documentCursor;
- (NSRect) documentRect;
- (id) documentView;
- (NSRect) documentVisibleRect;
- (BOOL) drawsBackground;
- (void) scrollToPoint:(NSPoint) newOrigin;
- (void) setBackgroundColor:(NSColor *) aColor;
- (void) setCopiesOnScroll:(BOOL) flag;
- (void) setDocumentCursor:(NSCursor *) aCursor;
- (void) setDocumentView:(NSView *) aView;
- (void) setDrawsBackground:(BOOL) flag;
- (void) viewBoundsChanged:(NSNotification *) aNotification;
- (void) viewFrameChanged:(NSNotification *) aNotification;

@end


@interface NSView (NSClipViewAdditions)

- (void) reflectScrolledClipView:(NSClipView *) aClipView;
- (void) scrollClipView:(NSClipView *) aClipView toPoint:(NSPoint) newOrigin;

@end

#endif /* _mySTEP_H_NSClipView */
