/* 
   NSView.h

   Abstract drawing canvas.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    August 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	20. Dezember 2007 - aligned with 10.5
 
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
@class CIFilter;
@class NSMenuItem; 

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

typedef NSInteger NSToolTipTag;
typedef NSInteger NSTrackingRectTag;

@interface NSView : NSResponder  <NSCoding> 
{
	NSView *_nextKeyView;
	NSView *super_view;
	NSMutableArray *sub_views;
    NSArray *_dragTypes;
	NSWindow *_window;
	NSAffineTransform *_bounds2frame;	// bounds to superview's bounds - created on demand
	NSAffineTransform *_frame2bounds;	// inverse - created on demand
	NSAffineTransform *_bounds2base;	// bounds to screen - created on demand
	NSAffineTransform *_base2bounds;	// inverse - created on demand
	NSRect _frame;
	NSRect _bounds;
	NSRect invalidRect;			// union of all subrects
	NSRect *invalidRects;
	NSSize unitSquareSize;	// ?? do we need that or is it just scaling bounds/frame size?
	float frameRotation;
	float boundsRotation;
	unsigned int nInvalidRects;
	unsigned int cInvalidRects;
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
		unsigned int needsDisplaySubviews:1;
		} _v;
}

+ (NSFocusRingType) defaultFocusRingType;
+ (NSMenu *) defaultMenu;
+ (NSView *) focusView;

- (BOOL) acceptsFirstMouse:(NSEvent *) event;
- (void) addCursorRect:(NSRect) aRect cursor:(NSCursor *) anObject;
- (void) addSubview:(NSView *) aView;
- (void) addSubview:(NSView *) aView
		 positioned:(NSWindowOrderingMode) place
		 relativeTo:(NSView *) otherView;
- (NSToolTipTag) addToolTipRect:(NSRect) rect owner:(id) owner userData:(void *) data;
- (void) addTrackingArea:(NSTrackingArea *) area;
- (NSTrackingRectTag) addTrackingRect:(NSRect) aRect
								owner:(id) anObject
							 userData:(void *) data
						 assumeInside:(BOOL) flag;
- (void) adjustPageHeightNew:(CGFloat *) newBottom
						 top:(CGFloat) oldTop
					  bottom:(CGFloat) oldBottom
					   limit:(CGFloat) bottomLimit;
- (void) adjustPageWidthNew:(CGFloat *) newRight
					   left:(CGFloat) oldLeft
					  right:(CGFloat) oldRight	 
					  limit:(CGFloat) rightLimit;
- (NSRect) adjustScroll:(NSRect) newVisible;
- (void) allocateGState;
- (CGFloat) alphaValue; 
- (NSView *) ancestorSharedWithView:(NSView *) aView;
- (BOOL) autoresizesSubviews;
- (NSUInteger) autoresizingMask;
- (BOOL) autoscroll:(NSEvent *) event;
- (NSArray *) backgroundFilters; 
- (void) beginDocument;
- (void) beginPageInRect:(NSRect) rect
			 atPlacement:(NSPoint) location;
- (NSBitmapImageRep *) bitmapImageRepForCachingDisplayInRect:(NSRect) rect;
- (NSRect) bounds;
- (CGFloat) boundsRotation;
- (void) cacheDisplayInRect:(NSRect) rect toBitmapImageRep:(NSBitmapImageRep *) bitmap;
- (BOOL) canBecomeKeyView;
- (BOOL) canDraw;
- (NSRect) centerScanRect:(NSRect) aRect;
- (CIFilter *) compositingFilter;														// Core Image
- (NSArray *) contentFilters; 
- (NSPoint) convertPoint:(NSPoint) aPoint fromView:(NSView *) aView;
- (NSPoint) convertPoint:(NSPoint) aPoint toView:(NSView *) aView;
- (NSPoint) convertPointFromBase:(NSPoint) point; 
- (NSPoint) convertPointToBase:(NSPoint) point; 
- (NSRect) convertRect:(NSRect) aRect fromView:(NSView *) aView;
- (NSRect) convertRect:(NSRect) aRect toView:(NSView *) aView;
- (NSRect) convertRectFromBase:(NSRect) rect; 
- (NSRect) convertRectToBase:(NSRect) rect; 
- (NSSize) convertSize:(NSSize) aSize fromView:(NSView *) aView;
- (NSSize) convertSize:(NSSize) aSize toView:(NSView *) aView;
- (NSSize) convertSizeFromBase:(NSSize) size;
- (NSSize) convertSizeToBase:(NSSize) size; 
- (NSData *) dataWithEPSInsideRect:(NSRect) rect;
- (NSData *) dataWithPDFInsideRect:(NSRect) rect;
- (NSString *) description;
- (void) didAddSubview:(NSView *) subview;
- (void) discardCursorRects;
- (void) display;
- (void) displayIfNeeded;
- (void) displayIfNeededIgnoringOpacity;
- (void) displayIfNeededInRect:(NSRect) aRect;
- (void) displayIfNeededInRectIgnoringOpacity:(NSRect) aRect;
- (void) displayRect:(NSRect) aRect;
- (void) displayRectIgnoringOpacity:(NSRect) aRect;
- (void) displayRectIgnoringOpacity:(NSRect) aRect inContext:(NSGraphicsContext *) context;
- (BOOL) dragFile:(NSString *) filename
		 fromRect:(NSRect) rect
		slideBack:(BOOL) slideFlag
			event:(NSEvent *) event;
- (void) dragImage:(NSImage *) anImage
				at:(NSPoint) viewLocation
			offset:(NSSize) initialOffset
			 event:(NSEvent *) event
		pasteboard:(NSPasteboard *) pboard
			source:(id) sourceObject
		 slideBack:(BOOL) slideFlag;
- (BOOL) dragPromisedFilesOfTypes:(NSArray *) types
						 fromRect:(NSRect) rect
						   source:(id) source
						slideBack:(BOOL) flag
							event:(NSEvent *) event;
- (void) drawPageBorderWithSize:(NSSize) borderSize;
- (void) drawRect:(NSRect) rect;
- (void) drawSheetBorderWithSize:(NSSize) borderSize;
- (NSMenuItem *) enclosingMenuItem; 
- (NSScrollView *) enclosingScrollView;
- (void) endDocument;
- (void) endPage;
- (BOOL) enterFullScreenMode:(NSScreen *) screen withOptions:(NSDictionary *) opts; 
- (void) exitFullScreenModeWithOptions:(NSDictionary *) opts; 
- (NSFocusRingType) focusRingType;
- (NSRect) frame;
- (CGFloat) frameCenterRotation; 
- (CGFloat) frameRotation;
- (void) getRectsBeingDrawn:(const NSRect **) rects count:(NSInteger *) count;
- (void) getRectsExposedDuringLiveResize:(NSRect *) exposedRects count:(NSInteger *) count;
- (NSInteger) gState;
- (CGFloat) heightAdjustLimit;
- (NSView *) hitTest:(NSPoint) aPoint;
- (id) initWithFrame:(NSRect) frameRect;
- (BOOL) inLiveResize;
- (BOOL) isDescendantOf:(NSView *) aView;
- (BOOL) isFlipped;
- (BOOL) isHidden;
- (BOOL) isHiddenOrHasHiddenAncestor;
- (BOOL) isInFullScreenMode; 
- (BOOL) isOpaque;
- (BOOL) isRotatedFromBase;
- (BOOL) isRotatedOrScaledFromBase;
- (BOOL) knowsPageRange:(NSRangePointer) pages;
//- (CALayer *) layer;								// Core Animation
- (NSPoint) locationOfPrintRect:(NSRect) aRect;
- (void) lockFocus;
- (BOOL) lockFocusIfCanDraw;
- (BOOL) lockFocusIfCanDrawInContext:(NSGraphicsContext *) context;
- (NSMenu *) menuForEvent:(NSEvent *) event;
- (BOOL) mouse:(NSPoint) aPoint inRect:(NSRect) aRect;
- (BOOL) mouseDownCanMoveWindow;
- (BOOL) needsDisplay;
- (BOOL) needsPanelToBecomeKey;
- (BOOL) needsToDrawRect:(NSRect) rect;
- (NSView *) nextKeyView;
- (NSView *) nextValidKeyView;
- (NSView *) opaqueAncestor;
- (NSAttributedString *) pageFooter;
- (NSAttributedString *) pageHeader;
- (BOOL) performKeyEquivalent:(NSEvent *) event;
- (BOOL) performMnemonic:(NSString *) string;
- (BOOL) postsBoundsChangedNotifications;
- (BOOL) postsFrameChangedNotifications;
- (BOOL) preservesContentDuringLiveResize;
- (NSView *) previousKeyView;
- (NSView *) previousValidKeyView;
- (void) print:(id) sender;
- (NSString *) printJobTitle;
- (NSRect) rectForPage:(NSInteger) page;
- (NSRect) rectPreservedDuringLiveResize;
- (void) reflectScrolledClipView:(NSClipView *) aClipView;
- (NSArray *) registeredDraggedTypes;
- (void) registerForDraggedTypes:(NSArray *) newTypes;
- (void) releaseGState;
- (void) removeAllToolTips;
- (void) removeCursorRect:(NSRect) aRect cursor:(NSCursor *) anObject;
- (void) removeFromSuperview;
- (void) removeFromSuperviewWithoutNeedingDisplay;
- (void) removeToolTip:(NSToolTipTag) tag;
- (void) removeTrackingArea:(NSTrackingArea *) area; 
- (void) removeTrackingRect:(NSTrackingRectTag) tag;
- (void) renewGState;
- (void) replaceSubview:(NSView *) oldView with:(NSView *) newView;
- (void) resetCursorRects;
- (void) resizeSubviewsWithOldSize:(NSSize) oldSize;
- (void) resizeWithOldSuperviewSize:(NSSize) oldSize;
- (void) rotateByAngle:(CGFloat) angle;
- (void) scaleUnitSquareToSize:(NSSize) newSize;
- (void) scrollClipView:(NSClipView *) aClipView toPoint:(NSPoint) aPoint;
- (void) scrollPoint:(NSPoint) aPoint;
- (void) scrollRect:(NSRect) aRect by:(NSSize) delta;
- (BOOL) scrollRectToVisible:(NSRect) aRect;
- (void) setAlphaValue:(CGFloat) alpha; 
- (void) setAutoresizesSubviews:(BOOL) flag;
- (void) setAutoresizingMask:(NSUInteger) mask;
- (void) setBackgroundFilters:(NSArray *) bgFilters; 
- (void) setBounds:(NSRect) aRect;
- (void) setBoundsOrigin:(NSPoint) newOrigin;
- (void) setBoundsRotation:(CGFloat) angle;
- (void) setBoundsSize:(NSSize) newSize;
- (void) setCompositingFilter:(CIFilter *) compFilter; 
- (void) setContentFilters:(NSArray *) contentFilters; 
- (void) setFocusRingType:(NSFocusRingType) type;
- (void) setFrame:(NSRect) frameRect;
- (void) setFrameCenterRotation:(CGFloat) val; 
- (void) setFrameOrigin:(NSPoint) newOrigin;
- (void) setFrameRotation:(CGFloat) angle;
- (void) setFrameSize:(NSSize) newSize;
- (void) setHidden:(BOOL) flag;
- (void) setKeyboardFocusRingNeedsDisplayInRect:(NSRect) rect;
//- (void) setLayer:(CALayer *) layer;							// Core Animation
- (void) setNeedsDisplay:(BOOL) flag;
- (void) setNeedsDisplayInRect:(NSRect) invalidRect;
- (void) setNextKeyView:(NSView *) next;
- (void) setPostsBoundsChangedNotifications:(BOOL) flag;
- (void) setPostsFrameChangedNotifications:(BOOL) flag;
- (void) setShadow:(NSShadow *) shadow; 
- (void) setSubviews:(NSArray *) subviews; 
- (void) setToolTip:(NSString *) string;
- (void) setUpGState;
- (void) setWantsLayer:(BOOL) wantsLayer;						// Core Animation
- (NSShadow *) shadow; 
- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *) anEvent;
- (BOOL) shouldDrawColor;
- (void) sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *)) compare 
						   context:(void *) context;
- (NSMutableArray *) subviews;
- (NSView *) superview;
- (NSInteger) tag;
- (NSString *) toolTip;
- (NSArray *) trackingAreas; 
- (void) translateOriginToPoint:(NSPoint) point;
- (void) translateRectsNeedingDisplayInRect:(NSRect) rect by:(NSSize) size; 
- (void) unlockFocus;
- (void) unregisterDraggedTypes;
- (void) viewDidEndLiveResize;
- (void) viewDidHide; 
- (void) viewDidMoveToSuperview;
- (void) viewDidMoveToWindow;
- (void) viewDidUnhide;
- (void) viewWillDraw; 
- (void) viewWillMoveToSuperview:(NSView *) view;
- (void) viewWillMoveToWindow:(NSWindow *) newWindow;
- (void) viewWillStartLiveResize;
- (id) viewWithTag:(NSInteger) aTag;
- (NSRect) visibleRect;
- (BOOL) wantsDefaultClipping;
- (BOOL) wantsLayer;										// Core Animation
- (CGFloat) widthAdjustLimit;
- (void) willRemoveSubview:(NSView *) view;
- (NSWindow *) window;
- (void) writeEPSInsideRect:(NSRect) aRect toPasteboard:(NSPasteboard *) pboard;
- (void) writePDFInsideRect:(NSRect) aRect toPasteboard:(NSPasteboard *) pboard;

@end

@interface NSObject(NSToolTipOwner)

- (NSString *) view:(NSView *) view stringForToolTip:(NSToolTipTag) toolTipTag point:(NSPoint) pt userData:(void *) userData;

@end

extern NSString * const NSFullScreenModeAllScreens;
extern NSString * const NSFullScreenModeSetting;
extern NSString * const NSFullScreenModeWindowLevel;

extern NSString *NSViewFrameDidChangeNotification;
extern NSString *NSViewBoundsDidChangeNotification;
extern NSString *NSViewFocusDidChangeNotification;
extern NSString *NSViewGlobalFrameDidChangeNotification;
extern NSString *NSViewDidUpdateTrackingAreasNotification; 

#endif /* _mySTEP_H_NSView */
