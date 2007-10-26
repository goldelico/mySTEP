/* 
   NSView.h

   Abstract drawing canvas.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    August 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSView
#define _mySTEP_H_NSView

#import <Foundation/Foundation.h>
#import <Foundation/NSRange.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSGraphics.h>

@class NSPasteboard;
@class NSView;
@class NSClipView;
@class NSScrollView;
@class NSImage;
@class NSCursor;
@class NSBitmapImageRep;
@class NSAffineTransform;

typedef int NSToolTipTag;
typedef int NSTrackingRectTag;

typedef enum _NSBorderType
{ // constants representing the
	NSNoBorder     = 0,							// four types of borders that
	NSLineBorder   = 1,							// can appear around an NSView
	NSBezelBorder  = 2,
	NSGrooveBorder = 3
} NSBorderType;

			// autoresize constants which NSView uses in determining the parts 
enum {		// of a view which are resized when the view's superview is resized
	NSViewNotSizable	= 0,		// view does not resize with its superview. 
	NSViewMinXMargin	= 1,		// left margin between views can stretch.
	NSViewWidthSizable	= 2,		// view's width can stretch.
	NSViewMaxXMargin	= 4,		// right margin between views can stretch.
	NSViewMinYMargin	= 8,		// top margin between views can stretch.
	NSViewHeightSizable	= 16,		// view's height can stretch.
	NSViewMaxYMargin	= 32 		// bottom margin between views can stretch.
};

@interface NSView : NSResponder  <NSCoding> 
{
	NSRect frame;
	NSRect bounds;
	NSRect invalidRect;			// union of all subrects
	NSRect *invalidRects;
	unsigned int nInvalidRects;
	unsigned int cInvalidRects;
	NSAffineTransform *_bounds2frame;	// bounds to superview's bounds - created on demand
	NSAffineTransform *_frame2bounds;	// inverse - created on demand
	NSAffineTransform *_bounds2base;	// bounds to screen - created on demand
	NSAffineTransform *_base2bounds;	// inverse - created on demand
	float frameRotation;
	float boundsRotation;
	NSSize unitSquareSize;	// ?? do we need that or is it just scaling bounds/frame size?
	
	NSView *_nextKeyView;
	NSView *super_view;
	NSMutableArray *sub_views;
    NSArray *_dragTypes;
	NSWindow *window;
    int _gState;
    struct __ViewFlags {
		unsigned int isRotatedFromBase:1;
		unsigned int isRotatedOrScaledFromBase:1;
		unsigned int postFrameChange:1;
		unsigned int postBoundsChange:1;
		unsigned int autoSizeSubviews:1;
		unsigned int autoresizingMask:6;
		unsigned int hasToolTip:1;
		unsigned int _focusRingType:2;
		unsigned int hidden:1;
		unsigned int preservesContentDuringLiveResize:1;
		unsigned int customBounds:1;
//		unsigned int needsDisplay:1;
		} _v;
}

+ (NSFocusRingType) defaultFocusRingType;
+ (NSMenu *) defaultMenu;
+ (NSView *) focusView;										// Focusing

- (BOOL) acceptsFirstMouse:(NSEvent *)event;				// Event Handling
- (void) addCursorRect:(NSRect)aRect cursor:(NSCursor *)anObject;
- (void) addSubview:(NSView *)aView;						// NSView Hierarchy
- (void) addSubview:(NSView *)aView
		 positioned:(NSWindowOrderingMode)place
		 relativeTo:(NSView *)otherView;
- (NSToolTipTag) addToolTipRect:(NSRect) rect owner:(id) owner userData:(void *) data;
- (NSTrackingRectTag) addTrackingRect:(NSRect)aRect
								owner:(id)anObject
							 userData:(void *)data
						 assumeInside:(BOOL)flag;
- (void) adjustPageHeightNew:(float *)newBottom				// Pagination
						 top:(float)oldTop
					  bottom:(float)oldBottom
					   limit:(float)bottomLimit;
- (void) adjustPageWidthNew:(float *)newRight
					   left:(float)oldLeft
					  right:(float)oldRight	 
					  limit:(float)rightLimit;
- (NSRect) adjustScroll:(NSRect)newVisible;					// Scrolling
- (void) allocateGState;									// Graphics State
- (NSView *) ancestorSharedWithView:(NSView *)aView;
- (BOOL) autoresizesSubviews;
- (unsigned int) autoresizingMask;
- (BOOL) autoscroll:(NSEvent *)event;
- (void) beginDocument;
- (void) beginPageInRect:(NSRect) rect
			 atPlacement:(NSPoint) location;
- (NSBitmapImageRep *) bitmapImageRepForCachingDisplayInRect:(NSRect) rect;
- (NSRect) bounds;
- (float) boundsRotation;									// Coord System
- (void) cacheDisplayInRect:(NSRect) rect toBitmapImageRep:(NSBitmapImageRep *) bitmap;
- (BOOL) canBecomeKeyView;
- (BOOL) canDraw;
- (NSRect) centerScanRect:(NSRect)aRect;					// Coord conversion
- (NSPoint) convertPoint:(NSPoint)aPoint fromView:(NSView *)aView;
- (NSPoint) convertPoint:(NSPoint)aPoint toView:(NSView *)aView;
- (NSRect) convertRect:(NSRect)aRect fromView:(NSView *)aView;
- (NSRect) convertRect:(NSRect)aRect toView:(NSView *)aView;
- (NSSize) convertSize:(NSSize)aSize fromView:(NSView *)aView;
- (NSSize) convertSize:(NSSize)aSize toView:(NSView *)aView;
- (NSData *) dataWithEPSInsideRect:(NSRect) rect;
- (NSData *) dataWithPDFInsideRect:(NSRect) rect;
- (NSString *) description;
- (void) didAddSubview:(NSView *) subview;
- (void) discardCursorRects;								// Cursor rects
- (void) display;											// Display view
- (void) displayIfNeeded;
- (void) displayIfNeededIgnoringOpacity;
- (void) displayIfNeededInRect:(NSRect)aRect;
- (void) displayIfNeededInRectIgnoringOpacity:(NSRect)aRect;
- (void) displayRect:(NSRect)aRect;
- (void) displayRectIgnoringOpacity:(NSRect)aRect;
- (void) displayRectIgnoringOpacity:(NSRect)aRect inContext:(NSGraphicsContext *)context;
- (BOOL) dragFile:(NSString *)filename						// Drag and Drop
		 fromRect:(NSRect)rect
		slideBack:(BOOL)slideFlag
			event:(NSEvent *)event;
- (void) dragImage:(NSImage *)anImage
				at:(NSPoint)viewLocation
			offset:(NSSize)initialOffset
			 event:(NSEvent *)event
		pasteboard:(NSPasteboard *)pboard
			source:(id)sourceObject
		 slideBack:(BOOL)slideFlag;
- (BOOL) dragPromisedFilesOfTypes:(NSArray *) types
						 fromRect:(NSRect) rect
						   source:(id) source
						slideBack:(BOOL) flag
							event:(NSEvent *) event;
- (void) drawPageBorderWithSize:(NSSize)borderSize;
- (void) drawRect:(NSRect)rect;
- (void) drawSheetBorderWithSize:(NSSize)borderSize;
- (NSScrollView *) enclosingScrollView;
- (void) endDocument;
- (void) endPage;
- (NSFocusRingType) focusRingType;
- (NSRect) frame;
- (float) frameRotation;									// Frame Rectangle
- (void) getRectsBeingDrawn:(const NSRect **) rects count:(int *) count;
- (void) getRectsExposedDuringLiveResize:(NSRect[4]) exposedRects count:(int *) count;
- (int) gState;
- (float) heightAdjustLimit;
- (NSView *) hitTest:(NSPoint)aPoint;
- (id) initWithFrame:(NSRect)frameRect;
- (BOOL) inLiveResize;
- (BOOL) isDescendantOf:(NSView *)aView;
- (BOOL) isFlipped;
- (BOOL) isHidden;
- (BOOL) isHiddenOrHasHiddenAncestor;
- (BOOL) isOpaque;
- (BOOL) isRotatedFromBase;
- (BOOL) isRotatedOrScaledFromBase;
- (BOOL) knowsPageRange:(NSRangePointer)pages;
- (NSPoint) locationOfPrintRect:(NSRect)aRect;
- (void) lockFocus;
- (BOOL) lockFocusIfCanDraw;
- (BOOL) lockFocusIfCanDrawInContext:(NSGraphicsContext *) context;
- (NSMenu *) menuForEvent:(NSEvent *) event;
- (BOOL) mouse:(NSPoint)aPoint inRect:(NSRect)aRect;
- (BOOL) mouseDownCanMoveWindow;
- (BOOL) needsDisplay;
- (BOOL) needsPanelToBecomeKey;
- (BOOL) needsToDrawRect:(NSRect) rect;
- (NSView *) nextKeyView;
- (NSView *) nextValidKeyView;
- (NSView *) opaqueAncestor;
- (NSAttributedString *) pageFooter;
- (NSAttributedString *) pageHeader;
- (BOOL) performKeyEquivalent:(NSEvent *)event;
- (BOOL) performMnemonic:(NSString *)string;
- (BOOL) postsBoundsChangedNotifications;
- (BOOL) postsFrameChangedNotifications;
- (BOOL) preservesContentDuringLiveResize;
- (NSView *) previousKeyView;
- (NSView *) previousValidKeyView;
- (void) print:(id)sender;
- (NSString *) printJobTitle;
- (NSRect) rectForPage:(int)page;
- (NSRect) rectPreservedDuringLiveResize;
- (void) reflectScrolledClipView:(NSClipView *)aClipView;
- (NSArray *) registeredDraggedTypes;
- (void) registerForDraggedTypes:(NSArray *)newTypes;
- (void) releaseGState;
- (void) removeAllToolTips;
- (void) removeCursorRect:(NSRect)aRect cursor:(NSCursor *)anObject;
- (void) removeFromSuperview;
- (void) removeFromSuperviewWithoutNeedingDisplay;
- (void) removeToolTip:(NSToolTipTag) tag;
- (void) removeTrackingRect:(NSTrackingRectTag)tag;
- (void) renewGState;
- (void) replaceSubview:(NSView *)oldView with:(NSView *)newView;
- (void) resetCursorRects;
- (void) resizeSubviewsWithOldSize:(NSSize)oldSize;			// Resize Subviews
- (void) resizeWithOldSuperviewSize:(NSSize)oldSize;
- (void) rotateByAngle:(float)angle;
- (void) scaleUnitSquareToSize:(NSSize)newSize;
- (void) scrollClipView:(NSClipView *)aClipView toPoint:(NSPoint)aPoint;
- (void) scrollPoint:(NSPoint)aPoint;
- (void) scrollRect:(NSRect)aRect by:(NSSize)delta;
- (BOOL) scrollRectToVisible:(NSRect)aRect;
- (void) setAutoresizesSubviews:(BOOL)flag;
- (void) setAutoresizingMask:(unsigned int)mask;
- (void) setBounds:(NSRect)aRect;
- (void) setBoundsOrigin:(NSPoint)newOrigin;
- (void) setBoundsRotation:(float)angle;
- (void) setBoundsSize:(NSSize)newSize;
- (void) setFocusRingType:(NSFocusRingType) type;
- (void) setFrame:(NSRect)frameRect;
- (void) setFrameOrigin:(NSPoint)newOrigin;
- (void) setFrameRotation:(float)angle;
- (void) setFrameSize:(NSSize)newSize;
- (void) setHidden:(BOOL) flag;
- (void) setKeyboardFocusRingNeedsDisplayInRect:(NSRect)rect;
- (void) setNeedsDisplay:(BOOL)flag;
- (void) setNeedsDisplayInRect:(NSRect)invalidRect;
- (void) setNextKeyView:(NSView *)next;
- (void) setPostsBoundsChangedNotifications:(BOOL)flag;
- (void) setPostsFrameChangedNotifications:(BOOL)flag;		// Notify Ancestors
- (void) setToolTip:(NSString *)string;						// Tool tips
- (void) setUpGState;
- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent;
- (BOOL) shouldDrawColor;
- (void) sortSubviewsUsingFunction:(int (*)(id ,id ,void *))compare 
						   context:(void *)context;
- (NSMutableArray *) subviews;
- (NSView *) superview;
- (int) tag;												// Tag identify
- (NSString *) toolTip;
- (void) translateOriginToPoint:(NSPoint)point;
- (void) unlockFocus;
- (void) unregisterDraggedTypes;
- (void) viewDidEndLiveResize;
- (void) viewDidMoveToSuperview;
- (void) viewDidMoveToWindow;
- (void) viewWillMoveToSuperview:(NSView *)view;
- (void) viewWillMoveToWindow:(NSWindow *)newWindow;
- (void) viewWillStartLiveResize;
- (id) viewWithTag:(int)aTag;
- (NSRect) visibleRect;
- (BOOL) wantsDefaultClipping;
- (float) widthAdjustLimit;
- (void) willRemoveSubview:(NSView *)view;
- (NSWindow *) window;
- (void) writeEPSInsideRect:(NSRect) aRect toPasteboard:(NSPasteboard *) pboard;
- (void) writePDFInsideRect:(NSRect) aRect toPasteboard:(NSPasteboard *) pboard;

@end


extern NSString *NSViewFrameDidChangeNotification;			// Notifications
extern NSString *NSViewBoundsDidChangeNotification;
extern NSString *NSViewFocusDidChangeNotification;
extern NSString *NSViewGlobalFrameDidChangeNotification;

#endif /* _mySTEP_H_NSView */
