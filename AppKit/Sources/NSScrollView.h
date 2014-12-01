/*
   NSScrollView.h

   View which scrolls another via a clip view.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Aug 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSScrollView
#define _mySTEP_H_NSScrollView

#import <AppKit/NSView.h>

@class NSClipView;
@class NSRulerView;
@class NSColor;
@class NSCursor;
@class NSScroller;

@interface NSScrollView : NSView
{
	NSClipView *_contentView;
	NSScroller *_horizScroller;
	NSScroller *_vertScroller;
	NSRulerView *_horizRuler;
	NSRulerView *_vertRuler;
	NSView *_cornerView;			// peeked from document view
	NSClipView *_headerContentView;	// peeked from document view
	CGFloat _horizontalLineScroll;
	CGFloat _horizontalPageScroll;
	CGFloat _verticalLineScroll;
	CGFloat _verticalPageScroll;
	CGFloat _magnification;
	CGFloat _minMagnification;
	CGFloat _maxMagnification;
	struct {
		UIBITFIELD(unsigned int, hasHorizScroller, 1);
		UIBITFIELD(unsigned int, hasVertScroller, 1);
		UIBITFIELD(unsigned int, hasHorizRuler, 1);
		UIBITFIELD(unsigned int, hasVertRuler, 1);
		UIBITFIELD(unsigned int, scrollsDynamically, 1);
		UIBITFIELD(unsigned int, autohidesScrollers, 1);
		UIBITFIELD(unsigned int, autohidingScrollers, 1);
		UIBITFIELD(unsigned int, doubleLongClick, 1);
		UIBITFIELD(unsigned int, allowMagnification, 1);
		UIBITFIELD(NSBorderType, borderType, 2);
	} _sv;
}

+ (NSSize) contentSizeForFrameSize:(NSSize) frameSize		// Layout
			 hasHorizontalScroller:(BOOL) hFlag
			   hasVerticalScroller:(BOOL) vFlag
						borderType:(NSBorderType) borderType;
+ (NSSize) frameSizeForContentSize:(NSSize) contentSize
			 hasHorizontalScroller:(BOOL) hFlag
			   hasVerticalScroller:(BOOL) vFlag
						borderType:(NSBorderType) borderType;
+ (Class) rulerViewClass;
+ (void) setRulerViewClass:(Class) aClass;					// Rulers

- (BOOL) autohidesScrollers;
- (NSColor *) backgroundColor;
- (NSBorderType) borderType;
- (NSSize) contentSize;
- (NSClipView *) contentView;
- (NSCursor *) documentCursor;
- (id) documentView;
- (NSRect) documentVisibleRect;
- (BOOL) drawsBackground;
- (BOOL) hasHorizontalRuler;
- (BOOL) hasHorizontalScroller;
- (BOOL) hasVerticalRuler;
- (BOOL) hasVerticalScroller;
- (CGFloat) horizontalLineScroll;
- (CGFloat) horizontalPageScroll;
- (NSRulerView *) horizontalRulerView;
- (NSScroller *) horizontalScroller;
- (CGFloat) lineScroll;
- (CGFloat) pageScroll;
- (void) reflectScrolledClipView:(NSClipView *)aClipView;
- (BOOL) rulersVisible;
- (BOOL) scrollsDynamically;
- (void) scrollWheel:(NSEvent *) event;
- (void) setAutohidesScrollers:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) aColor;
- (void) setBorderType:(NSBorderType) borderType;
- (void) setContentView:(NSClipView *) aView;
- (void) setDocumentCursor:(NSCursor *) aCursor;
- (void) setDocumentView:(NSView *) aView;
- (void) setDrawsBackground:(BOOL) flag;
- (void) setHasHorizontalRuler:(BOOL) flag;
- (void) setHasHorizontalScroller:(BOOL) flag;
- (void) setHasVerticalRuler:(BOOL) flag;
- (void) setHasVerticalScroller:(BOOL) flag;
- (void) setHorizontalLineScroll:(CGFloat) aFloat;
- (void) setHorizontalPageScroll:(CGFloat) aFloat;
- (void) setHorizontalRulerView:(NSRulerView *) aRulerView;
- (void) setHorizontalScroller:(NSScroller *) aScroller;
- (void) setLineScroll:(CGFloat) aFloat;
- (void) setPageScroll:(CGFloat) aFloat;
- (void) setRulersVisible:(BOOL) flag;
- (void) setScrollsDynamically:(BOOL) flag;
- (void) setVerticalLineScroll:(CGFloat) aFloat;
- (void) setVerticalPageScroll:(CGFloat) aFloat;
- (void) setVerticalRulerView:(NSRulerView *) aRulerView;
- (void) setVerticalScroller:(NSScroller *) aScroller;
- (void) tile;
- (CGFloat) verticalLineScroll;
- (CGFloat) verticalPageScroll;
- (NSRulerView *) verticalRulerView;
- (NSScroller *) verticalScroller;

- (BOOL) allowsMagnification;	// default NO
- (void) setAllowsMagnification:(BOOL) flag;

- (CGFloat) magnification;	// default 1.0
- (void) setMagnification:(CGFloat) factor;

- (CGFloat) maxMagnification;	// default 4.0
- (void) setMaxMagnification:(CGFloat) factor;
- (CGFloat) minMagnification;	// default 1/4.0
- (void) setMinMagnification:(CGFloat) factor;

- (void) magnifyToFitRect:(NSRect) rect;	// magnify proportionally but clip to min/max
- (void) setMagnification:(CGFloat) magnification centeredAtPoint:(NSPoint) point;	// set magnification (clipped) and center

@end

extern NSString *NSScrollViewWillStartLiveMagnifyNotification;
extern NSString *NSScrollViewDidEndLiveMagnifyNotification;

@interface NSView (NSDocumentViewMagnification)
- (NSRect) rectForSmartMagnificationAtPoint:(NSPoint) location inRect:(NSRect) visibleRect;	// default: NSZeroRect
@end

#endif /* _mySTEP_H_NSScrollView */
