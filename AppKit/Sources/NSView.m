/* 
   NSView.m

   Abstract drawing canvas.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    August 1998

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - heavily reworked to be aligned with 10.4 and use the new backend interface
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>

#import <AppKit/NSView.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSText.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

@class NSClassSwapper;

#include <unistd.h>	// usleep()

#define NOTICE(notif_name)	NSView##notif_name##Notification

// Class variables

BOOL _NSShowAllViews=NO;
BOOL _NSShowAllDrawing=NO;

NSView *__toolTipOwnerView = nil;
static NSPoint __lastPoint = {-1, -1};
static NSTrackingRectTag _trackRectTag = 0;
static NSMutableDictionary *_toolTipsDict = nil;
static NSText *__toolTipText = nil;
static NSPanel *__toolTipWindow = nil;
static unsigned int __mouseMovedEventCounter = 0;
static unsigned int __toolTipSequenceCounter = 0;

//*****************************************************************************
//
// 		GSTrackingRect -- Private class describing tracking/cursor rects
//
//*****************************************************************************

@interface GSTrackingRect : NSObject
{
@public
	NSRect rect;
	NSTrackingRectTag tag;
	id owner;
	void *userData;
	BOOL inside;
}

- (void) push;

@end

@implementation GSTrackingRect

- (void) dealloc
{
	[owner release];
	[super dealloc];
}

- (void) push							{ [owner push]; }

@end /* GSTrackingRect */


@interface NSWindow (TrackingRects)

- (NSMutableArray *) _trackingRects;
- (NSMutableArray *) _cursorRects;

@end

@implementation NSWindow (TrackingRects)

- (NSMutableArray *) _trackingRects
{
	if(!(_trackRects))
		{
		_w.cursorRectsEnabled = YES;
		_trackRects = [NSMutableArray new];
		}

	return _trackRects;
}

- (NSMutableArray *) _cursorRects
{
	if(!(_cursorRects))
		{
		_w.cursorRectsEnabled = YES;
		_cursorRects = [NSMutableArray new];
		}

	return _cursorRects;
}

- (void) mouseMoved:(NSEvent *)event
{
NSPoint current = [event locationInWindow];
int i, j = (_trackRects) ? [_trackRects count] : 0;

	for (i = 0; i < j; ++i)								// Check tracking rects
		{
		GSTrackingRect *r = (GSTrackingRect *)[_trackRects objectAtIndex:i];
		BOOL last = NSMouseInRect(__lastPoint, r->rect, NO);
		BOOL now = NSMouseInRect(current, r->rect, NO);

		if ((last) && (!now))							// Mouse exited event
			{
			NSEvent *e = [NSEvent enterExitEventWithType:NSMouseExited
								  location:current 
								  modifierFlags:[event modifierFlags]
								  timestamp:0 
								  windowNumber:[self windowNumber]
								  context:NULL 
								  eventNumber:__mouseMovedEventCounter++ 
								  trackingNumber:r->tag 
								  userData:r->userData];

			[r->owner mouseExited:e];					// Send event to owner
			}

		if ((!last) && (now))							// Mouse entered event
			{
			NSEvent *e = [NSEvent enterExitEventWithType:NSMouseEntered
								  location:current 
								  modifierFlags:[event modifierFlags]
								  timestamp:0 
								  windowNumber:[self windowNumber]
								  context:NULL 
								  eventNumber:__mouseMovedEventCounter++ 
								  trackingNumber:r->tag 
								  userData:r->userData];

			[r->owner mouseEntered:e];					// Send event to owner
		}	}

	if ((_cursorRects) && ((j = [_cursorRects count]) > 0))
		{
		NSEvent *enter[j], *exit[j];
		int l = 0, k = 0;
	
		for (i = 0; i < j; ++i)							// Check cursor rects
			{
			GSTrackingRect *r =(GSTrackingRect*)[_cursorRects objectAtIndex:i];
			BOOL last = NSMouseInRect(__lastPoint, r->rect, NO);
			BOOL now = NSMouseInRect(current, r->rect, NO);
	
			if ((!last) && (now))							// Mouse entered
				enter[k++] = [NSEvent enterExitEventWithType: NSCursorUpdate
									  location: current
									  modifierFlags:[event modifierFlags]
									  timestamp: 0
									  windowNumber:[self windowNumber]
									  context: [event context]
									  eventNumber: __mouseMovedEventCounter++
									  trackingNumber: (int)YES
									  userData: (void *)r->owner];
	
			if ((last) && (!now))							// Mouse exited
				exit[l++] = [NSEvent enterExitEventWithType: NSCursorUpdate
									 location: current
									 modifierFlags:[event modifierFlags]
									 timestamp: 0
									 windowNumber:[self windowNumber]
									 context: [event context]
									 eventNumber: __mouseMovedEventCounter++
									 trackingNumber: (int)NO
									 userData: (void *)r];
			}
	
		while(k--)
			[self postEvent:enter[k] atStart: YES];
		while(l--)											// Post cursor
			[self postEvent:exit[l] atStart: YES];			// update events
		}

	__lastPoint = current;
}

@end /* NSWindow (TrackingRects) */

//*****************************************************************************
//
// 		NSView 
//
//*****************************************************************************

@implementation NSView

/* NOT YET IMPLEMENTED

printing

-writePDFInsideRect:toPasteboard:' not found
-writeEPSInsideRect:toPasteboard:' not found

	scrolling

-widthAdjustLimit' not found
-heightAdjustLimit' not found

	tooltips

-addToolTipRect:owner:userData:' not found
-removeToolTip:' not found
-removeAllToolTips' not found

	others

-setKeyboardFocusRingNeedsDisplayInRect:' not found
-dragPromisedFilesOfTypes:fromRect:source:slideBack:event:' not found
-> call same of NSWindow with [self convertRect:fromRect toView:nil]
-dragImage:at:offset:event:pasteboard:source:slideBack:' not found
-dragFile:fromRect:slideBack:event:' not found
-adjustPageWidthNew:left:right:limit:' not found
-adjustPageHeightNew:top:bottom:limit:' not found

	drawing

-cacheDisplayInRect:toBitmapImageRep:' not found
-bitmapImageRepForCachingDisplayInRect:' not found

	*/

+ (void) initialize;
{
	NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];			// read from ArgumentsDomain
	_NSShowAllViews=([ud stringForKey:@"NSShowAllViews"] != nil) || getenv("NSShowAllViews");		// -NSShowAllViews (any value)
	_NSShowAllDrawing=([ud stringForKey:@"NSShowAllDrawing"] != nil) || getenv("NSShowAllDrawing");	// -NSShowAllDrawing (any value)
}

+ (NSView *) focusView
{
	return [(NSArray *) [[NSGraphicsContext currentContext] focusStack] lastObject];
}

+ (NSMenu *) defaultMenu; { return nil; }	// override in subclasses
+ (NSFocusRingType) defaultFocusRingType; { return NSFocusRingTypeExterior; }	// override in subclasses

- (void) print:(id) sender
{
	NSPrintOperation *po=[NSPrintOperation printOperationWithView:self];
	[po runOperationModalForWindow:window delegate:nil didRunSelector:_cmd contextInfo:NULL];
}

- (NSData *) dataWithEPSInsideRect:(NSRect) rect; { return NIMP; }

- (NSData *) dataWithPDFInsideRect:(NSRect) rect;
{
	NSMutableData *data=[NSMutableData dataWithCapacity:1000];
	NSPrintOperation *po=[NSPrintOperation PDFOperationWithView:self insideRect:rect toData:data];
	[po setShowsPrintPanel:NO];
	[po setShowsProgressPanel:NO];
	if([po runOperation])
		return data;
	return nil;	// some error
}

- (void) beginDocument;
{
	return;	// default
}

- (void) beginPageInRect:(NSRect) rect atPlacement:(NSPoint) location;
{
	[self lockFocusIfCanDrawInContext:[[NSPrintOperation currentOperation] context]];
	// FIXME: set translation CTM
}

- (void) drawPageBorderWithSize:(NSSize)borderSize;
{
	[self drawSheetBorderWithSize:borderSize];	// call default
}

- (void) drawSheetBorderWithSize:(NSSize)borderSize;
{ // this one is DEPRECATED
	return;	// default
}

- (void) endDocument;
{
	return;
}

- (void) endPage;
{
	[self unlockFocus];
}

- (NSPoint) locationOfPrintRect:(NSRect)aRect;
{
	NSPrintInfo *pi=[[NSPrintOperation currentOperation] printInfo];
	// adjust according to:
	[pi isHorizontallyCentered];
	[pi isVerticallyCentered];
	return NSZeroPoint;
}

- (BOOL) knowsPageRange:(NSRangePointer)pages;
{
	return NO;	// default
}

- (NSAttributedString *) pageFooter;
{
	// Check UserDefaults for NSPrintHeaderAndFooter
	return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Page %d", [[NSPrintOperation currentOperation] currentPage]]] autorelease];
}

- (NSAttributedString *) pageHeader;
{
	// Check UserDefaults for NSPrintHeaderAndFooter
	return [[[NSAttributedString alloc] initWithString:[self printJobTitle]] autorelease];
}

- (NSString *) printJobTitle;
{
	NSString *title=[[[window windowController] document] displayName];
	if(title)
		return title;	// if the window controller has a document that has a display name
	return [window title];	// return the window title or nil
}

- (NSRect) rectForPage:(int)page;
{
	return bounds;
}

- (BOOL) canDraw
{ // if not attached to a window or window not attached to a screen
	if(_v.hidden)
		return NO;
	// FIXME: additional conditions might apply
	return YES;
}

- (BOOL) _lockFocusInContext:(NSGraphicsContext *)context;
{
	NSMutableArray *fstack;
	// FIXME: should lock atomically
	if(!context)
		return NO;	// can't lock on nil context
#if 0
	NSLog(@"_lockFocusInContext:%@", context);
#endif
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:context];
	[[self _bounds2base] set];	// set required transformation matrix
	fstack=(NSMutableArray *) [context focusStack];
	if(!fstack)
		{ // create focus stack
		fstack=[[NSMutableArray alloc] initWithCapacity:3];
		[context setFocusStack:fstack];
		}
	[fstack addObject:self];
#if 0
	NSLog(@"locked");
#endif
	return YES;
}

- (BOOL) lockFocusIfCanDrawInContext:(NSGraphicsContext *)context;
{
	if(![self canDraw])
		return NO;
	return [self _lockFocusInContext:context];
}

- (BOOL) lockFocusIfCanDraw
{
	return [self lockFocusIfCanDrawInContext:[window graphicsContext]];
}

- (void) lockFocus
{ // based on gState
	NSMutableArray *fstack;
	NSGraphicsContext *context;
	[NSGraphicsContext saveGraphicsState];
	if(!window)
		NSLog(@"can't lockFocus without a window");
	else
		{
		int gState=_gState;
#if FIXME
		if(_gState == 0 /* and there is one allocated */)
			[self setUpGState];
#endif
		if(gState == 0)
			gState=[window gState];
		if(!gState)
			{
			NSLog(@"could not get a gState to focus on %@", self);
			}
		else
			[NSGraphicsContext setGraphicsState:gState];	// select private state&context if possible
		}
	context=[NSGraphicsContext currentContext];
	[[self _bounds2base] set];	// set required transformation matrix
	fstack=(NSMutableArray *) [context focusStack];
	if(!fstack)
		{ // create focus stack
		fstack=[[NSMutableArray alloc] initWithCapacity:3];
		[context setFocusStack:fstack];
		}
	[fstack addObject:self];
}

- (void) unlockFocus
{
	NSMutableArray *fstack=(NSMutableArray *) [[NSGraphicsContext currentContext] focusStack];
	if([fstack lastObject] != self)
		{
		NSLog(@"focus stack nesting error: context=%@", [NSGraphicsContext currentContext]);
		NSLog(@"  unlock: %@", self);
		NSLog(@"  found on stack: %@", fstack);
		}
	[fstack removeLastObject];
//	if(_gState)
//		[NSGraphicsContext setGraphicsState:_gState];	// restore private state&context
	[NSGraphicsContext restoreGraphicsState];
}

- (NSString *) description
{
	NSMutableString *s;
	s=[NSMutableString stringWithString:NSStringFromClass(isa)];
	[s appendFormat:@" win=%@", [window title]];
	[s appendFormat:@" frame=[%.1lf,%.1lf,%.1lf,%.1lf]", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
	[s appendFormat:@" bounds=[%.1lf,%.1lf,%.1lf,%.1lf]", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height];
	if(nInvalidRects == 1)
		[s appendFormat:@" invalid=[%.1lf,%.1lf,%.1lf,%.1lf]", invalidRects[0].origin.x, invalidRects[0].origin.y, invalidRects[0].size.width, invalidRects[0].size.height];
	if(nInvalidRects > 1)
		[s appendFormat:@" %d invalid rects", nInvalidRects];
	if([self isHidden]) [s appendString:@" isHidden"];
	if([self isFlipped]) [s appendString:@" isFlipped"];
	if([self isOpaque]) [s appendString:@" isOpaque"];
	if([self canDraw]) [s appendString:@" canDraw"];
	if(_v.isRotatedFromBase) [s appendString:@" is rotated"];
	if(_v.isRotatedOrScaledFromBase) [s appendString:@" or scaled"];
	return s;
}

- (NSString *) _descriptionWithSubviews
{
	NSMutableString *s=[NSMutableString stringWithString:[self description]];
	NSEnumerator *e=[sub_views objectEnumerator];
	NSView *v;
	while((v=[e nextObject]))
		{ // prefix all lines with @"  "
		NSString *sub=[v _descriptionWithSubviews];
		NSArray *suba=[sub componentsSeparatedByString:@"\n"];
		[s appendFormat:@"\n  %@", [suba componentsJoinedByString:@"\n  "]];
		}
	return s;
}

- (id) init		{ return [self initWithFrame:NSZeroRect]; }

- (id) initWithFrame:(NSRect)frameRect
{
#if 0
	NSLog(@"NSView: %@ initWithFrame:%@", NSStringFromClass([self class]), NSStringFromRect(frameRect));
#endif
	if((self=[super init]))										// super is NSResponder
		{
#if 0
		NSLog(@"NSView: initWithFrame 1 %@", self);
#endif
		frame = frameRect;
		bounds = (NSRect){NSZeroPoint, frame.size};
//		unitSquareSize = NSMakeSize(1.0, 1.0);		// FIXME???
		sub_views = [NSMutableArray new];
#if 0
		NSLog(@"NSView: initWithFrame 2a %@", self);
#endif
		_v.autoSizeSubviews = YES;
#if 0
		NSLog(@"NSView: initWithFrame 2b %@", self);
#endif
		[super setMenu:[isa defaultMenu]];
#if 0
		NSLog(@"NSView: initWithFrame 3 %@", self);
#endif
		}
#if 0
	NSLog(@"NSView: initWithFrame -> %@", self);
#endif
	return self;
}

- (void) dealloc
{
	if(__toolTipOwnerView == self)
		[self mouseExited:nil];	// call before releasing anything
	[_bounds2frame release];
	[_frame2bounds release];
	[_bounds2base release];
	[_base2bounds release];
	[_dragTypes release];
	// FIXME: release gState if we have a private one
	[sub_views release];
	[super dealloc];
}

- (NSArray *) registeredDraggedTypes; { return _dragTypes; }
- (void) registerForDraggedTypes:(NSArray *)newTypes; { ASSIGN(_dragTypes, newTypes); }	// should make us an enabled dragging target
- (void) unregisterDraggedTypes; { [self registerForDraggedTypes:nil]; }

- (void) setFocusRingType:(NSFocusRingType) type { _v._focusRingType=type; }
- (NSFocusRingType) focusRingType { return _v._focusRingType; }

- (void) addSubview:(NSView *)aView
{
	[self addSubview:aView
		  positioned:NSWindowAbove
		  relativeTo:nil];					// above all siblings
}

- (void) addSubview:(NSView *)aView					// may not be per OS spec
		 positioned:(NSWindowOrderingMode)place		// FIX ME
		 relativeTo:(NSView *)otherView
{
	if(!aView)
		{
		NSLog(@"trying to add nil subview to %@", self);
		return;
		}
	if([self isDescendantOf:aView])
		{ // make sure we aren't making self a subview of self thereby creating a loop in the hierarchy
		NSLog(@"%@ addSubview:%@ positioned:%d relativeTo:%@ requested to create a cycle in the views tree", self, aView, place, otherView);
		// should we raise an exception?
		return;
		}
	if([sub_views indexOfObjectIdenticalTo:aView] != NSNotFound)
		{
		// FIXME: this is just a Workaround!!!
		// FIXME: this does sometimes happen when loading NIBs -- why???
		NSLog(@"%@ is already a subview of %@ (ignored)", aView, self);
		return;
		}
	[aView viewWillMoveToSuperview:self];
	
	// FIXME: check for relative position and otherView and insert at expected position
	
	[sub_views addObject:(id)aView];				// Append to our subview list
	[aView viewDidMoveToSuperview];
	[aView _setSuperview:self];
													// Make ourselves the next 
	[aView setNextResponder:self];					// responder of the view

	[aView viewWillMoveToWindow:window];
	[aView _setWindow:window];						// place on same window as we are
	[aView viewDidMoveToWindow];					// Tell the view what 
													// window it has moved to
	[self didAddSubview:aView];
	[aView setNeedsDisplay:YES];					// (re)draw incl. new view
//	[self setNeedsDisplay:YES];						// (re)draw incl. new view
}

- (NSView *) ancestorSharedWithView:(NSView *)aView
{
	if (self == aView)								// Are they the same view?
		return self;
  
	if ([self isDescendantOf: aView])				// Is self a descendant of 
		return aView;								// view?

	if ([aView isDescendantOf: self])				// Is view a descendant of 
		return self;								// self?
									
	if (![self superview])			// If neither are descendants of each other
		return nil;					// and either does not have a superview
	if (![aView superview])			// then they cannot have a common ancestor
		return nil;
									// Find the common ancestor of superviews
	return [[self superview] ancestorSharedWithView: [aView superview]];
}

- (BOOL) isDescendantOf:(NSView *)aView
{
	if (aView == self || (super_view == aView))
		return YES;

	if (!super_view) 								// No superview then this 
		return NO;									// is end of the line

	return [super_view isDescendantOf:aView];
}

- (NSView *) opaqueAncestor
{
	return (!super_view || [self isOpaque]) ? self : [super_view opaqueAncestor];
}

- (BOOL) isHiddenOrHasHiddenAncestor;
{
	return [self isHidden] || (super_view && [super_view isHiddenOrHasHiddenAncestor]);
}

- (NSScrollView *) enclosingScrollView;
{
	static Class scrollViewClass;
	if(!super_view)
		return nil;
	if(!scrollViewClass)
		scrollViewClass=[NSScrollView class];	// get reference (initialized only once)
	if([super_view isKindOfClass:scrollViewClass])
		return (NSScrollView *) super_view;	// found!
	return [super_view enclosingScrollView];	// go up one level
}

- (void) removeFromSuperviewWithoutNeedingDisplay
{
	[self retain];	// postpone release
	if(window)
		{
		if([window firstResponder] == self)
			[window makeFirstResponder:window];
		[self _setWindow:nil];
		}
	if(super_view)
		{
#if 0
		NSLog(@"removeFromSuperviewWithoutNeedingDisplay before: %@", [super_view subviews]);
#endif
		[super_view willRemoveSubview:self];
		[[super_view subviews] removeObjectIdenticalTo:self];	// this is the extra release mentioned in the documentation
		[self viewWillMoveToSuperview:nil];
		super_view = nil;
		[self viewDidMoveToSuperview];
#if 0
		NSLog(@"removeFromSuperviewWithoutNeedingDisplay after: %@", [super_view subviews]);
#endif
		}
	else
		NSLog(@"trying to remove subview without superview: %@", self);
	[self release];	// postponed dealloc
}

- (void) removeFromSuperview
{
	[self retain];	// postpone release
	if(window)
		{
		if([window firstResponder] == self)
			[window makeFirstResponder:window];
		[self _setWindow:nil];
		}
	if(super_view)
		{
		[super_view willRemoveSubview:self];
		[super_view setNeedsDisplay:YES];	// we could restrict to our own frame rect
		[[super_view subviews] removeObjectIdenticalTo:self];	// this is the extra release mentioned in the documentation
		[self viewWillMoveToSuperview:nil];
		super_view = nil;
		[self viewDidMoveToSuperview];
		}
	else
		NSLog(@"trying to remove subview without superview: %@", self);
	[self release];	// may be our final release!
}

- (void) replaceSubview:(NSView *)oldView with:(NSView *)newView
{
	int index;
	if(!newView || !oldView)
		{
		NSLog(@"NSView warning - can't replace subview %@ with %@", oldView, newView);
		return;
		}
	index = [sub_views indexOfObjectIdenticalTo:oldView];
	
	if(index != NSNotFound) 
		{
		[oldView _setWindow:nil];
		[oldView _setSuperview:nil];
		
		[newView setNextResponder:nil];
		
		[self willRemoveSubview:oldView];
		[sub_views replaceObjectAtIndex:index withObject:newView];
		
		[self didAddSubview:newView];
		[newView _setWindow:window];
		[newView _setSuperview:self];
		[newView setNextResponder:self];
		}
	else
		NSLog(@"NSView warning: replaceSubview: not found: %@, oldView");
}

- (void) sortSubviewsUsingFunction:(int (*)(id ,id ,void *))compare 
						   context:(void *)context
{
	[sub_views sortUsingFunction:compare context:context];
}

- (void) _setWindow:(NSWindow *)newWindow
{
	int i, count;
	if(window == newWindow)
		return;	// no change
	[self viewWillMoveToWindow:newWindow];
	count = [sub_views count];
	if([window firstResponder] == self)
		[window makeFirstResponder:nil];	// we are currently the first responder of the old window
	window=newWindow;	// set new window
	for (i = 0; i < count; ++i)				// Pass down to all subviews
		[[sub_views objectAtIndex:i] _setWindow:newWindow];
	nInvalidRects=0;	// clear cache
	[self setNeedsDisplayInRect:bounds];	// we need to be redisplayed completely in the new window
	[self viewDidMoveToWindow];
}

- (void) viewWillMoveToWindow:(NSWindow *)newWindow
{
	return;	// default: do noting
}

- (void) viewDidMoveToWindow
{
	return;	// default: do nothing
}

- (void) viewWillMoveToSuperview:(NSView *)newView
{
	return;	// default: do noting
}

- (void) viewDidMoveToSuperview
{
	return;	// default: do nothing
}

- (void) didAddSubview:(NSView *) view;
{
	return;	// default: do nothing
}

- (void) willRemoveSubview:(NSView *) view;
{
	return;	// default: do nothing
}

- (void) rotateByAngle:(float)angle
{
	boundsRotation+=angle;
	_v.isRotatedFromBase = _v.isRotatedOrScaledFromBase = YES;
	[self _invalidateCTM];
	if(_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

- (void) setFrame:(NSRect)frameRect
{
	NSSize o;
	if(NSEqualRects(frame, frameRect))
		return;	// no change
	o=frame.size;	// remember old size
	frame=frameRect;
	if(!_v.customBounds)
		bounds.size = frameRect.size;	// always adjust
	if(super_view)
		[self _setSuperview:super_view];	// will also call invalidate
	else
		[self _invalidateCTM];
#if 0
	NSLog(@"autosize %d %@", _v.autoSizeSubviews, self);
#endif
	if(_v.autoSizeSubviews && !NSEqualSizes(o, frame.size))
		[self resizeSubviewsWithOldSize: o];	// Resize subviews
#if 0
	NSLog(@"autosized");
#endif
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
#if 0
	NSLog(@"notified");
#endif
}

- (void) setFrameOrigin:(NSPoint)newOrigin
{
	if(NSEqualPoints(frame.origin, newOrigin))
		return;	// no change
	frame.origin = newOrigin;
	[self _invalidateCTM];
	if(super_view)
		[self _setSuperview:super_view];
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
}

- (void) setFrameSize:(NSSize)newSize
{
	NSSize o = frame.size;
	if(NSEqualSizes(o, newSize))
		return;	// no change
	frame.size = newSize;
	if(!_v.customBounds)
		bounds.size = newSize;	// always adjust
	[self _invalidateCTM];
	if(_v.autoSizeSubviews)
		[self resizeSubviewsWithOldSize:o];				// Resize subviews
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
}

- (void) setFrameRotation:(float)angle
{
	if(frameRotation == angle)
		return;
	frameRotation=angle;
	[self _invalidateCTM];
	_v.isRotatedFromBase = _v.isRotatedOrScaledFromBase = YES;	// FIXME should also be set for superviews
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
}

- (BOOL) isRotatedFromBase
{
	if (_v.isRotatedFromBase)
		return _v.isRotatedFromBase;
	else 
		return (super_view) ? [super_view isRotatedFromBase] : NO;
}

- (BOOL) isRotatedOrScaledFromBase
{
	if (_v.isRotatedOrScaledFromBase)
		return _v.isRotatedOrScaledFromBase;
	else
		return (super_view) ? [super_view isRotatedOrScaledFromBase] : NO;
}

- (void) scaleUnitSquareToSize:(NSSize)newSize
{
	// FIXME!!! isn't it sufficient to update the bounds rect?

//	unitSquareSize=newSize;
	// scale bounds size & origin
	bounds.origin.x /= newSize.width;
	bounds.size.width /= newSize.width;
	bounds.origin.y /= newSize.height;
	bounds.size.height /= newSize.height;
	_v.isRotatedOrScaledFromBase = YES;
	[self _invalidateCTM];
	if (_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

- (void) setBounds:(NSRect)aRect
{
	_v.customBounds=YES;
	if(NSEqualRects(bounds, aRect))
		return;	// no change
	bounds = aRect;
	[self _invalidateCTM];
	if (_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

- (void) setBoundsOrigin:(NSPoint)newOrigin			// translate bounds origin
{													// in opposite direction so that newOrigin becomes the origin when viewed.
	_v.customBounds=YES;
	if(NSEqualPoints(bounds.origin, newOrigin))
		return;	// no change
	bounds.origin = newOrigin;
	[self _invalidateCTM];
	if(_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

- (void) setBoundsSize:(NSSize)newSize
{
	_v.customBounds=YES;
	if(NSEqualSizes(bounds.size, newSize))
		return;	// no change
	bounds.size = newSize;
	[self _invalidateCTM];
	if (_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

- (void) setBoundsRotation:(float)angle
{
	_v.customBounds=YES;
	if(boundsRotation == angle)
		return;	// no change
	boundsRotation=angle;
	[self _invalidateCTM];
	_v.isRotatedFromBase = _v.isRotatedOrScaledFromBase = YES;
	if (_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

- (void) translateOriginToPoint:(NSPoint)point
{
	[self setBoundsOrigin:NSMakePoint(bounds.origin.x-point.x, bounds.origin.y-point.y)];
}

- (NSRect) bounds					{ return bounds; }
- (NSRect) frame					{ return frame; }
- (float) boundsRotation			{ return boundsRotation; }
- (float) frameRotation				{ return frameRotation; }

- (NSRect) centerScanRect:(NSRect)aRect
{
	NSRect n=[self convertRect:aRect toView:nil];		// to NSWindow coordinates
	n.origin=[window convertBaseToScreen:n.origin];
	n.origin.x=0.5+floor(n.origin.x);					// to center of screen pixels - don't round!
	n.origin.y=0.5+floor(n.origin.y);
	n.size.width=rint(n.size.width);					// round to nearest integer size
	n.size.height=rint(n.size.height);
	n.origin=[window convertScreenToBase:n.origin];		// convert back to NSWindow
	return [self convertRect:n fromView:nil];			// and back to view
}

- (void) _invalidateCTM;
{
	ASSIGN(_bounds2frame, nil);
	ASSIGN(_frame2bounds, nil);
	ASSIGN(_bounds2base, nil);
	ASSIGN(_base2bounds, nil);
	[sub_views makeObjectsPerformSelector:_cmd];	// and invalidate all subviews
}

// FIXME: frame and bounds rotation are not correctly handled
// FIXME: scaleUnitSquare is not correctly handled

- (NSAffineTransform*) _bounds2frame;
{ // create transformation matrix
	if(!_bounds2frame)
		{ // FIXME: can we optimize this if(!_v.customBounds) ???
		_bounds2frame=[[NSAffineTransform alloc] init];	// create a new transform
		if([self isFlipped])
			{
			if(_v.isRotatedFromBase)
				[_bounds2frame rotateByDegrees:boundsRotation];	// rotate around origin
			[_bounds2frame translateXBy:0 yBy:bounds.size.height];
			[_bounds2frame scaleXBy:1.0 yBy:-1.0];
			// [_bounds2frame scaleXBy:unitSquareSize.width yBy:-unitSquareSize.height];	// finally (or initially?) scale (incl. origin)
			[_bounds2frame translateXBy:-bounds.origin.x yBy:-bounds.origin.y];
			if(frameRotation != 0.0)
				[_bounds2frame rotateByDegrees:frameRotation];	// rotate around frame origin

			// FIXME: we can optimize this step if(super_view && [super_view isFlipped])

			[_bounds2frame translateXBy:frame.origin.x yBy:-frame.origin.y];	// shift view to its position within superview
			}
		else
			{ // not flipped
			// [_bounds2frame scaleXBy:unitSquareSize.width yBy:unitSquareSize.height];	// finally (or initially?) scale (incl. origin)
			[_bounds2frame translateXBy:-bounds.origin.x yBy:-bounds.origin.y];
			if(boundsRotation != 0.0)
				[_bounds2frame rotateByDegrees:boundsRotation];
			[_bounds2frame translateXBy:frame.origin.x yBy:frame.origin.y];	// shift view to its position within superview
			if(frameRotation != 0.0)
				[_bounds2frame rotateByDegrees:frameRotation];	// rotate around frame origin
			}
		if(super_view && [super_view isFlipped])
			{ // flip back coordinates, but take care that our frame.origin is still expressed in flipped coordinates!
			[_bounds2frame translateXBy:-frame.origin.x yBy:frame.origin.y];	// shift us back (frame.origin is flipped by superview)
			[_bounds2frame scaleXBy:1.0 yBy:-1.0];	// undo flipping
			[_bounds2frame translateXBy:frame.origin.x yBy:frame.origin.y-frame.size.height];	// shift view to its target position within flipped superview
			}
		[_frame2bounds release];
		_frame2bounds=nil;	// recache
		}
	return _bounds2frame;
}

- (NSAffineTransform *) _frame2bounds;
{
	if(!_frame2bounds)
		{ // not cached
		_frame2bounds=[[self _bounds2frame] copy];
		[_frame2bounds invert];	// go back from window to our bounds coordinates
		}
	return _frame2bounds;
}

- (NSAffineTransform *) _bounds2base;
{ // transform base coordinates to NSWindow's base
	if(!_bounds2base)
		{
		if(super_view)
			{
			_bounds2base=[[self _bounds2frame] copy];
#if 0
			if([super_view isFlipped])
				{ // flip back coordinates, but take care that our frame.origin is still expressed in flipped coordinates!
				[_bounds2base translateXBy:-frame.origin.x yBy:frame.origin.y];	// shift us back (frame.origin is flipped by superview)
				[_bounds2base scaleXBy:1.0 yBy:-1.0];	// undo flipping
				[_bounds2base translateXBy:frame.origin.x yBy:frame.origin.y-frame.size.height];	// shift view to its target position within flipped superview
				}
#endif
			[_bounds2base appendTransform:[super_view _bounds2base]];	// merge with superview's transformation(s)
			}
		else
			_bounds2base=[[self _bounds2frame] retain];				// we are the toplevel view
		[_base2bounds release];
		_base2bounds=nil;	// recache
		}
	return _bounds2base;
}

- (NSAffineTransform *) _base2bounds;
{
	if(!_base2bounds)
		{ // not cached
		_base2bounds=[[self _bounds2base] copy];
		[_base2bounds invert];	// go back from window to our bounds coordinates
		}
	return _base2bounds;
}

+ (NSAffineTransform *) _matrixFromView:(NSView *) from toView:(NSView *) to;
{ // transform from 'from' -> base -> 'to' - NOTE: result is NOT necessarily a mutable copy!
	NSAffineTransform *atm;
	if(from == to)
		{ // return identity matrix
		static NSAffineTransform *identity;
		if(!identity) identity=[[NSAffineTransform transform] retain];
		return identity;
		}
	if(!from)
		return [to _base2bounds];	// convert from window coordinates to base only
	if(to == [from superview])
		{ // shortcut to direct superview
		return [from _bounds2frame];
		}
	if(from == [to superview])
		{ // shortcut to direct subview
		return [to _frame2bounds];
		}
	atm=[from _bounds2base];	// convert from base to window coordinates
	if(to)
		{ // and transform from window to base
		atm=[atm copy];	// get a working copy
		[atm appendTransform:[to _base2bounds]];
		[atm autorelease];
		}
	return atm;
}

- (NSPoint) convertPoint:(NSPoint)aPoint fromView:(NSView*)aView
{
	if(aView == self)
		return aPoint;
	return [[isa _matrixFromView:aView toView:self] transformPoint:aPoint];
}

- (NSRect) convertRect:(NSRect)aRect fromView:(NSView *)aView
{
	NSRect r;
	NSAffineTransform *atm;
	if(aView == self)
		return aRect;
	atm=[isa _matrixFromView:aView toView:self];
	r.origin=[atm transformPoint:aRect.origin];
	r.size=[atm transformSize:aRect.size];
	if((aRect.size.height < 0) != (r.size.height < 0))
		r.origin.y-=(r.size.height=-r.size.height);	// there was some flipping involved: r.size.height=sgn(aRect.size.height)*abs(r.size.height)
#if 1
	if(r.size.height < 0)
		{
		NSLog(@"conversion from %@ to %@ results in negative rect height: %@ -> %@", aView, self, NSStringFromRect(aRect), NSStringFromRect(r));
//		abort();
		}
#endif
	return r;
}

- (NSSize) convertSize:(NSSize)aSize fromView:(NSView *)aView
{
	NSSize s;
	if(aView == self)
		return aSize;
	s=[[isa _matrixFromView:aView toView:self] transformSize:aSize];
	if((aSize.height < 0) != (s.height < 0))
		s.height=-s.height;
	return s;
}

- (NSPoint) convertPoint:(NSPoint)aPoint toView:(NSView *)aView
{
	if(aView == self)
		return aPoint;
	return [[isa _matrixFromView:self toView:aView] transformPoint:aPoint];
}

- (NSRect) convertRect:(NSRect)aRect toView:(NSView *)aView
{
	NSRect r;
	NSAffineTransform *atm;
	if(aView == self)
		return aRect;
#if 0
	NSLog(@"convertRect 1");
#endif
	atm=[isa _matrixFromView:self toView:aView];
	r.origin=[atm transformPoint:aRect.origin];
	r.size=[atm transformSize:aRect.size];
	if((aRect.size.height < 0) != (r.size.height < 0))
		r.origin.y-=(r.size.height=-r.size.height);	// there was some flipping involved
#if 0
	NSLog(@"convertRect 2");
#endif
#if 1
	if(r.size.height < 0)
		{
		NSLog(@"conversion to %@ from %@ results in negative rect height: %@ -> %@", aView, self, NSStringFromRect(aRect), NSStringFromRect(r));
		}
#endif
	return r;
}

- (NSSize) convertSize:(NSSize)aSize toView:(NSView *)aView
{
	NSSize s;
	if(aView == self)
		return aSize;
	s=[[isa _matrixFromView:self toView:aView] transformSize:aSize];
	if((aSize.height < 0) != (s.height < 0))
		s.height=-s.height;
	return s;
}

- (void) _setSuperview:(NSView *)superview		
{
	if((super_view = superview) == nil)
		return;	// removed
	[self _invalidateCTM];	// update when needed
	if(_v.hasToolTip)
		{
		NSMutableArray *trackRects = [window _trackingRects];
		int i, j = [trackRects count];

		for (i = 0; i < j; ++i)
			{
			GSTrackingRect *m = (GSTrackingRect *)[trackRects objectAtIndex:i];

			if (m->owner == self)
				{
				[trackRects removeObjectAtIndex:i];
				break;
			}	}

		[self addTrackingRect:bounds owner:self userData:NULL assumeInside:NO];
		}
}

- (void) setPostsFrameChangedNotifications:(BOOL)flag
{
	_v.postFrameChange = flag;
}

- (void) setPostsBoundsChangedNotifications:(BOOL)flag
{
	_v.postBoundsChange = flag;
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if(NSEqualSizes(oldSize, frame.size))
		return;	// ignore unchanged size
#if 1
	NSLog(@"resizeSubviewsWithOldSize:%@ -> %@ %@", NSStringFromSize(oldSize), NSStringFromSize(frame.size), self);
	NSLog(@"subviews=%@", sub_views);
#endif
	if (_v.autoSizeSubviews && !_v.isRotatedFromBase)					 
		{												// resize subviews only
		int i, count = [sub_views count];				// if we are supposed
														// to and we have never
														// been rotated
		for (i = 0; i < count; i++)						// resize the subviews
			[[sub_views objectAtIndex:i] resizeWithOldSuperviewSize: oldSize];
		}
	else
		NSLog(@"can't resizeSubviewsWithOldSize: %@", self);
}

- (void) resizeWithOldSuperviewSize:(NSSize)oldSize		
{
	float change, changePerOption;
	NSSize old_size = frame.size;
	NSSize superViewFrameSize;	// super_view should not be nil!
	BOOL changedOrigin = NO;
	BOOL changedSize = NO;
	int options = 0;
	if(!super_view)
		return;	// how can this happen? We are called as [[sub_views objectAtIndex:i] resizeWithOldSuperviewSize: oldSize]
	superViewFrameSize = [super_view frame].size;	// super_view should not be nil!
	if(NSEqualSizes(oldSize, superViewFrameSize))
		return;	// ignore unchanged size
#if 1
	NSLog(@"resizeWithOldSuperviewSize %x: %@ -> %@ %@", _v.autoresizingMask, NSStringFromSize(oldSize), NSStringFromSize(superViewFrameSize), self);
#endif
	// do nothing if view is not resizable
	if(_v.autoresizingMask == NSViewNotSizable) 
		return;											
														// determine if and how
	if(_v.autoresizingMask & NSViewWidthSizable)		// the X axis can be
		options++;										// resized 
	if(_v.autoresizingMask & NSViewMinXMargin)				
		options++;
	if(_v.autoresizingMask & NSViewMaxXMargin)				
		options++;
														// adjust the X axis if
	if(options > 0)										// any X options are
		{												// set in the mask
		change = superViewFrameSize.width - oldSize.width;
		changePerOption = floor(change / options);		
	
		if(_v.autoresizingMask & NSViewWidthSizable)		
			{		
			float oldFrameWidth = frame.size.width;

			frame.size.width += changePerOption;
			// NSWidth(frame) = MAX(0, NSWidth(frame) + changePerOption);
			if (NSWidth(frame) <= 0)
				{
				NSAssert((NSWidth(frame) <= 0), @"View frame width <= 0!");
				NSLog(@"resizeWithOldSuperviewSize: View frame width <= 0!");
				frame.size.width = 0;
				}
			if(_v.isRotatedFromBase)
				{
				bounds.size.width *= frame.size.width / oldFrameWidth;
				bounds.size.width = floor(bounds.size.width);
				}
			else
				bounds.size.width += changePerOption;
			changedSize = YES;
			}
		if(_v.autoresizingMask & NSViewMinXMargin)
			{
			frame.origin.x += changePerOption;
			changedOrigin = YES;
			}
		}
														// determine if and how 
	options = 0;										// the Y axis can be
	if(_v.autoresizingMask & NSViewHeightSizable)		// resized	
		options++;										
	if(_v.autoresizingMask & NSViewMinYMargin)				
		options++;
	if(_v.autoresizingMask & NSViewMaxYMargin)				
		options++;
														// adjust the Y axis if
	if(options > 0)									// any Y options are  
		{												// set in the mask
		change = superViewFrameSize.height - oldSize.height;
		changePerOption = floor(change/options);		
	
		if(_v.autoresizingMask & NSViewHeightSizable)		
			{											
			float oldFrameHeight = frame.size.height;

			frame.size.height += changePerOption;
			// NSHeight(frame) = MAX(0, NSHeight(frame) + changePerOption);
			if (NSHeight(frame) <= 0)
				{
				NSAssert((NSHeight(frame) <= 0), @"View frame height <= 0!");
				NSLog(@"resizeWithOldSuperviewSize: View frame height <= 0!");
				frame.size.height = 0;
				}
			if(_v.isRotatedFromBase)			
				{										
				bounds.size.height *= frame.size.height/oldFrameHeight;
				bounds.size.height = floor(bounds.size.height);
				}
			else
				bounds.size.height += changePerOption;
			changedSize = YES;
			}
		if(_v.autoresizingMask & NSViewMinYMargin)
			{				
			frame.origin.y += changePerOption;
			changedOrigin = YES;
			}
		}

	if(changedSize && _v.isRotatedFromBase)	
		{
		float sx = frame.size.width / bounds.size.width;
		float sy = frame.size.height / bounds.size.height;
		// FIXME:
		NSLog(@"and now? %@", self);
		}
														
	if(changedSize || changedOrigin)
		{					 
		[self _invalidateCTM];	// update when needed
		[self resizeSubviewsWithOldSize: old_size];	// recursively go down
		}
}

// this is the real drawing method

- (void) drawRect:(NSRect)rect
{
	return;	// default implementation does nothing
}

- (void) _drawRect:(NSRect) rect;
{
	static NSColor *black;
#if 0
	NSLog(@"_drawRect:%@ %@", NSStringFromRect(rect), self);
#endif
	NS_DURING
		if(_NSShowAllDrawing && [window isVisible])
			{ // blink rect that will be redrawn - note that transparent views will get a magenta background by this feature...
			[[NSGraphicsContext currentContext] saveGraphicsState];
			[[NSColor magentaColor] set];
			NSRectFill(rect);
			[window flushWindow];
			usleep(300*1000);	// sleep 0.3 seconds so that effect it is visible
			[[NSGraphicsContext currentContext] restoreGraphicsState];
			}
		// FIXME: this should be part of the setUpGState logic
		if(!black) black=[[NSColor blackColor] retain];
		[black set];				// set default
		if([self wantsDefaultClipping])
			{ // may be switched off to speed up
			  // FIXME: default should clip to list of rects in invalidRects!!!
			[NSBezierPath clipRect:rect];
			}
		[self drawRect:rect];		// that one is overridden in subviews and really draws
		if(_NSShowAllViews && [window isVisible])
			{ // draw box around all views
			[[NSColor brownColor] set];
			NSFrameRect(bounds);
			[window flushWindow];
			}
	NS_HANDLER
		NSLog(@"%@ -drawRect: %@", NSStringFromClass(isa), [localException reason]);
	NS_ENDHANDLER
}

- (BOOL) needsToDrawRect:(NSRect) rect;
{
    int i;    
	if(!NSIntersectsRect(rect, invalidRect))
		return NO;	// overall invalid rect
    for(i = 0; i < nInvalidRects; i++)
		{
        if(NSIntersectsRect(rect, invalidRects[i]))
            return YES;
        }
    return NO;
}

- (void) getRectsBeingDrawn:(const NSRect **) rects count:(int *) count;
{
	NIMP;
	// currently broken
	// we should save the current list at the beginning of drawRect
	// replace the list being written to by an empty one
	// then do drawRect
	// so that an setNeedsDisplayInRect: during drawRect is added to the new list
	// and delete the old one at unlockFocus
	*rects=invalidRects;
	*count=nInvalidRects;
}

- (NSRect) rectPreservedDuringLiveResize;
{
	//	NIMP;
	return NSZeroRect;	// FIXME: not yet supported
}

- (void) getRectsExposedDuringLiveResize:(NSRect[4]) rects count:(int *) count;
{
	//	NIMP;
	*count=0;	// FIXME: not yet supported
}

- (NSRect) visibleRect									// return intersection
{														// between bounds and
	if(super_view)										// superview's visible rect
		{
		NSRect s = [self convertRect:[super_view visibleRect] fromView:super_view];
		return NSIntersectionRect(s, bounds);
		}
	return bounds;										// if no super view, bounds is visible
}

- (BOOL) _addRectNeedingDisplay:(NSRect) rect;
{
	int i;
	for(i=0; i<nInvalidRects; i++)
		{
		// FIXME: the algorithm should create non-overlapping rects only!
		if(NSContainsRect(invalidRects[i], rect))
			return NO;	// someone already completely covers me
		if(NSContainsRect(rect, invalidRects[i]))
			{ // this one is completely covered by me - delete
			memmove((char *)&invalidRects[i], (char *)&invalidRects[i+1], (char *)(&invalidRects[--nInvalidRects])-(char *)(&invalidRects[i]));
			i--;	// keep index intact
			}
		}
	if(nInvalidRects >= cInvalidRects)
		invalidRects=(NSRect *) objc_realloc(invalidRects, sizeof(invalidRects[0])*(cInvalidRects=2*cInvalidRects+3));	// make more room
	if(nInvalidRects == 0)
		invalidRect=rect;	// we are the first rect
	else
		invalidRect=NSUnionRect(invalidRect, rect);	// merge
	invalidRects[nInvalidRects++]=rect;	// append
	return YES;
}

- (void) _removeRectNeedingDisplay:(NSRect) rect;
{ // FIXME: could be better optimized to shrink the invalidRect and split up intersecting parts
	int i;
	for(i=0; i<nInvalidRects; i++)
		{ // remove/cut down all invalidRects that intersect with aRect
		if(NSContainsRect(rect, invalidRects[i]))
			{ // has been completely drawn
			memmove((char *)&invalidRects[i], (char *)&invalidRects[i+1], (char *)(&invalidRects[--nInvalidRects])-(char *)(&invalidRects[i]));
			i--;				// keep index intact
			continue;
			}
		if(NSIntersectsRect(rect, invalidRects[i]))
			{
#if 0
			NSLog(@"drawing rect %@ intersects %@ for %@", NSStringFromRect(rect), NSStringFromRect(invalidRects[i]), self);
#endif
			// what if it intersects???
			// we might cut out parts
			// but since this are only hints to optimize drawing, leave it as it is
			}
		}
	if(nInvalidRects == 0)
		invalidRect=NSZeroRect;	// all has been drawn
}

- (BOOL) needsDisplay;
{
	return !_v.hidden && !NSIsEmptyRect(invalidRect);	// needs to draw something if not empty
	//	return nInvalidRects != 0;
}

- (void) setNeedsDisplay:(BOOL) flag;
{
	if(flag)
		[self setNeedsDisplayInRect:bounds];
	else
		{
		nInvalidRects=0;	// clear list
		invalidRect=NSZeroRect;
		// _v.needsDisplay=NO;	// done
		}
}

- (void) setNeedsDisplayInRect:(NSRect) rect;
{
#if 0
	NSLog(@"-setNeedsDisplayInRect:%@ of %@", NSStringFromRect(rect), self);
#endif
	// _v.needsDisplay=YES;
//	rect=NSIntersectionRect(bounds, rect);	// limit to bounds
	if([self _addRectNeedingDisplay:rect] || YES)
		{ // we (and our superviews) didn't know yet
#if 0
		NSLog(@"setneedsdisplay 1: %@", self);
#endif
		if(super_view)
			{
			NSAffineTransform *atm;
			NSRect r;
			// FIXME: not rotation-safe
			if([self isOpaque])
				; 
				// FIXME:  if we are opaque we should just need to setNeedsDisplay without updating the invalidRect of the superview
				// but the superview must know that there is something to redraw
				// i.e. this is the real reason why we probably need the 'ifNeeded' flag independently of the dirty rects
			atm=[self _bounds2frame];	// goes to our superview
			// HM - we should transform the corners individually and determine min/max dimension of the invalidated superview
			// we can also estimate the bounding box (as long as it is at least the required size)
			r.origin=[atm transformPoint:rect.origin];
			r.size=[atm transformSize:rect.size];
			if((rect.size.height < 0) != (r.size.height < 0))
				r.origin.y-=(r.size.height=-r.size.height);	// there was some flipping involved
			[super_view setNeedsDisplayInRect:r];
			// FIXME: we should simply loop instead of doing a recursion - to call [window setViewsNeedDisplay:YES]; etc. just once
			}
		}
	else
		// FIXME: this does not properly work!
		{ // we already did have the rect invalidated - assume that our superviews also know that
#if 1
		NSLog(@"not increased: %@", self);
		NSLog(@"super_view: %@", super_view);
#endif
		while(super_view)
			{			
			self=super_view;
			// _v.needsDisplay=YES;
			}
		}
	[window setViewsNeedDisplay:YES];	// we have reached the topmost view
#if 0
	NSLog(@"setneedsdisplay 2: %@", self);
#endif
	[NSApp setWindowsNeedUpdate:YES];	// and NSApp should also know...
#if 0
	NSLog(@"setneedsdisplay 3: %@", self);
#endif
}

- (void) setKeyboardFocusRingNeedsDisplayInRect:(NSRect) rect;
{
	[self setNeedsDisplayInRect:NSInsetRect(rect, -5.0, -5.0)];	// invalidate area larger than real bounds
}

// the pattern of the -display methods is: -display-IfNeeded-(In)Rect-IgnoringOpacity

- (void) displayIfNeeded; { if([self needsDisplay]) [self displayRect:invalidRect]; }
- (void) display; { [self displayRect:bounds]; }
- (void) displayIfNeededIgnoringOpacity; { if([self needsDisplay]) [self displayRectIgnoringOpacity:invalidRect]; }
- (void) displayIgnoringOpacity; { [self displayRectIgnoringOpacity:bounds]; }
- (void) displayIfNeededInRect:(NSRect) rect; { if([self needsDisplay]) [self displayRect:rect]; }
- (void) displayRect:(NSRect) rect; { NSView *a=[self opaqueAncestor]; [a displayRectIgnoringOpacity:[self convertRect:rect toView:a]]; }
- (void) displayIfNeededInRectIgnoringOpacity:(NSRect) rect; { if([self needsDisplay]) [self displayRectIgnoringOpacity:rect]; }
- (void) displayRectIgnoringOpacity:(NSRect) rect; { [self displayRectIgnoringOpacity:rect inContext:[window graphicsContext]]; [[window graphicsContext] flushGraphics]; }

- (void) displayRectIgnoringOpacity:(NSRect) rect inContext:(NSGraphicsContext *) context;
{ // recursively draw view and subviews - without flushing
	NSEnumerator *e;
	NSView *subview;
#if 0
	NSLog(@"displayRectIgnoringOpacity:%@ inContext:%@ for %@", NSStringFromRect(rect), context, self);
#endif
	if(!context)
		return;	// has no window (yet)
	// _v.needsDisplay=NO;	// clear the needs-display flag
	if(_v.hidden)
		{ // don't draw me or my subviews
		nInvalidRects=0;	// remove all rects
		invalidRect=NSZeroRect;
		return;
		}
	rect=NSIntersectionRect(bounds, rect);	// shrink to bounds (not invalidRect!)
	if(NSIsEmptyRect(rect))
		return;	// nothing to draw within our bounds
	if(![self lockFocusIfCanDrawInContext:context])
		return;	// can't lock focus
	// NOTE: we must be prepared for the case that drawRect: changes our frame and/or bounds and even calls setNeedsDisplay
	[self _drawRect:rect];	// this may use the invalid rects list as a hint to speed up drawing (i.e. if 2 separate lines of a tableview have been marked as needing display)
	if(context == [window graphicsContext])		// NOTE: remove after drawing!
		[self _removeRectNeedingDisplay:rect];	// should end up with empty list i.e. no more needsDrawing
	e=[sub_views objectEnumerator];
	while((subview=[e nextObject]))	// go downwards independently of their needsDisplay status since we have redrawn the background
		{
		NSAffineTransform *atm;
		NSRect subRect;
		if([subview isHidden])		// this saves converting the rect if the subview doesn't want to be drawn
			continue;
		if(!NSIntersectsRect([subview frame], rect))
			continue;	// subview is not within rect - ignore transformation
		// FIXME: not rotation-safe
		atm=[subview _frame2bounds];	// transform the dirty rect to our subview
										// HM - we should transform the corners individually and determine min/max dimension of the invalidated superview
										// we can also estimate the bounding box (as long as it is at least the required size)
		subRect.origin=[atm transformPoint:rect.origin];
		subRect.size=[atm transformSize:rect.size];
		if((rect.size.height < 0) != (subRect.size.height < 0))
			subRect.origin.y-=(subRect.size.height=-subRect.size.height);	// there was some flipping involved
		[subview displayRectIgnoringOpacity:subRect inContext:context];
		}
	[self unlockFocus];
}

- (BOOL) autoscroll:(NSEvent *)event					// Auto Scrolling
{
	return super_view ? [super_view autoscroll:event] : NO;	// closest ancestor NSClipView will have it overridden
}

- (BOOL) scrollRectToVisible:(NSRect)aRect
{
	if(super_view && [super_view respondsToSelector:@selector(scrollToPoint:)])
		{
		NSRect v = [self visibleRect];
		NSPoint a = [super_view bounds].origin;
		BOOL shouldScroll = NO;

		if(NSWidth(v) == 0 && NSHeight(v) == 0)			
			return NO;

		if((NSWidth(bounds) > NSWidth(v)) && !(NSMinX(v) <= NSMinX(aRect) 
				&& (NSMaxX(v) >= NSMaxX(aRect))))		
			{									// X dimension of aRect is not
			shouldScroll = YES;					// within visible rect
			if(aRect.origin.x < v.origin.x)
				a.x = aRect.origin.x;
			else
				a.x = v.origin.x + (NSMaxX(aRect) - NSMaxX(v));
			}

		if((NSHeight(bounds) > NSHeight(v)) && !(NSMinY(v) <= NSMinY(aRect) 
				&& (NSMaxY(v) >= NSMaxY(aRect))))		
			{									// Y dimension of aRect is not
			shouldScroll = YES;					// within visible rect
			if(aRect.origin.y < v.origin.y)
				a.y = aRect.origin.y;
			else
				a.y = v.origin.y + (NSMaxY(aRect) - NSMaxY(v));
			}

		if(shouldScroll)
			{
			id cSuper = [super_view superview];
			NSClipView *clipView = (NSClipView *) super_view;

			NSDebugLog(@"NSView scrollToPoint: (%1.2f, %1.2f)\n", a.x, a.y);

			a = [(NSClipView *)super_view constrainScrollPoint:a];
			[clipView scrollToPoint:a];

			if([cSuper respondsToSelector:@selector(reflectScrolledClipView:)])
				[(NSScrollView *)cSuper reflectScrolledClipView:clipView];

			return YES;
			}
		}

	return NO;
}

- (NSRect) adjustScroll:(NSRect)newVisible				{ return NSZeroRect; }
- (void) reflectScrolledClipView:(NSClipView*)aClipView { return; }
- (void) scrollClipView:(NSClipView *)aClipView 
				toPoint:(NSPoint)aPoint					{ NIMP }
- (void) scrollPoint:(NSPoint)aPoint					{ NIMP }
- (void) scrollRect:(NSRect)aRect by:(NSSize)delta		{ NIMP }	// here we should use NSCopyBits()

- (id) viewWithTag:(int)aTag
{
int i, count = [sub_views count];
id v;

	for (i = 0; i < count; ++i)
		if ([(v = [sub_views objectAtIndex:i]) tag] == aTag)
			return v;

	return nil;
}

// FIXME: is pretty time consuming...

- (NSView *) hitTest:(NSPoint)aPoint // aPoint is in superview's coordinates (or window base coordinates if there is no superview)
{
	int i;
	NSView *v;
	// can we somehow cache this?
	// We go through the view hierarchy twice:
	//  1. to find shouldBeTreatedAsInkEvent
	//  2. if not to find the view to forward the mouse event to
	// Note: this is a recursive call!
	// basically we need a list of NSRect to NSView mapping that is invalidated as soon as any sub(sub)view moves
	// or we just have a short-term cache that handles the case that hitTest is called for the same point twice (inking!)
#if 0   // doing this trace might slow processing down so much that a double-click is no longer recognized properly
	NSLog(@"%@ hitTest:%@ frame=%@ super-flipped=%d",
		  NSStringFromClass([self class]),
		  NSStringFromPoint(aPoint),
		  NSStringFromRect(frame),
		  [super_view isFlipped]);
#endif
	if(_v.hidden)
		return nil;
	if(super_view)
		{
		if(!NSMouseInRect(aPoint, frame, [super_view isFlipped]))
			{
#if 0
			NSLog(@"  not in rect");
#endif
			return nil;		// If not within our frame then immediately return
			}
		}
	aPoint=[self convertPoint:aPoint fromView:super_view];	// convert from superview's coordinates to ours
	for(i = [sub_views count] - 1; i >= 0; i--)	
		{ // Check our sub_views front to back
		if((v = [[sub_views objectAtIndex:i] hitTest:aPoint]))
			{
#if 0
			NSLog(@"  found %d=%@", i, v);
#endif
			return v;
			}
		}
#if 0
	NSLog(@"  success: %@", self);
#endif
	return self;	// mouse is either in the subview or within self
}

- (BOOL) mouse:(NSPoint)aPoint inRect:(NSRect)aRect
{
	return NSMouseInRect(aPoint, aRect, [self isFlipped]);
}

- (NSMenu *) menuForEvent:(NSEvent *)theEvent				{ return [self menu]; }
- (BOOL) acceptsFirstMouse:(NSEvent *)event					{ return YES; }
- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent*)event	{ return NO; }
- (BOOL) needsPanelToBecomeKey								{ return NO; }

- (BOOL) performKeyEquivalent:(NSEvent *)event
{
	int i=0, cnt=[sub_views count];
	while(i<cnt)	// Check our sub_views
		{
		if([[sub_views objectAtIndex:i] performKeyEquivalent:event])
			{
#if 0
			NSLog(@"%@ performKeyEquivalent -> YES", self);
#endif
			return YES;
			}
		i++;
		}
#if 0
	NSLog(@"%@ performKeyEquivalent -> NO", self);
#endif
	return NO;
}

- (BOOL) performMnemonic:(NSString *)string;
{
	int i=0, cnt = [sub_views count];
	while(i<cnt)	// Check our sub_views
		{
		if([[sub_views objectAtIndex:i] performMnemonic:string])
			return YES;	// any one responded!
		i++;
		}
	return NO;
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[window concludeDragOperation:sender];
}

- (unsigned int) draggingEntered:(id <NSDraggingInfo>)sender
{
	return [window draggingEntered:sender];
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
	[window draggingExited:sender];
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [window draggingUpdated:sender];
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	return [window performDragOperation:sender];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return [window prepareForDragOperation:sender];
}

- (unsigned int) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	// FIXME: override for reasonable defaults!
	return isLocal?0x0000:0x0000;
}

- (NSView*) nextValidKeyView
{ 
	return [_nextKeyView acceptsFirstResponder] ? _nextKeyView : nil;
}

- (NSView*) previousValidKeyView
{ 
NSView *p = [self previousKeyView];

	return [p acceptsFirstResponder] ? p : nil;
}

- (NSView*) previousKeyView
{
NSView *a = [window initialFirstResponder];
NSView *p = nil;

	while (a)
		{
		if (a == self)
			break;
		p = a;
		a = [a nextKeyView];
		}
													// value in p is not valid
	return (a) ? p : nil;							// if self was not found
}

- (void) setNextKeyView:(NSView *)next			{ _nextKeyView = next; }
- (NSView*) nextKeyView							{ return _nextKeyView; }
- (NSView*) superview							{ return super_view; }
- (NSWindow*) window							{ return window; }
- (NSMutableArray*) subviews					{ return sub_views; }
- (unsigned int) autoresizingMask				{ return _v.autoresizingMask; }
- (void) setAutoresizesSubviews:(BOOL)flag		{ _v.autoSizeSubviews = flag; }
- (void) setAutoresizingMask:(unsigned int)mask	{ _v.autoresizingMask = mask; }

- (void) setHidden:(BOOL)flag
{
#if 0
	NSLog(@"setHidden:%d %@", flag, self);
#endif
	_v.hidden = flag;
	[self setNeedsDisplay:!flag];
#if 0
	NSLog(@"after setHidden:%d %@", flag, self);
#endif
	// FIXME: handle nextResponder
		// handle cursor rects
		// etc.
}

- (void) setPreservesContentDuringLiveResize:(BOOL)flag	{ _v.preservesContentDuringLiveResize = flag; }
- (BOOL) autoresizesSubviews					{ return _v.autoSizeSubviews; }
- (BOOL) canBecomeKeyView;						{ return NO; }
- (BOOL) isHidden								{ return _v.hidden; }
- (BOOL) isOpaque								{ return (super_view == nil); }	// only if I represent the NSWindow
- (BOOL) inLiveResize							{ return super_view?[super_view inLiveResize]:NO; }
- (BOOL) shouldDrawColor						{ return YES; }
- (BOOL) wantsDefaultClipping					{ return YES; }
- (BOOL) isFlipped								{ return NO; }
- (BOOL) preservesContentDuringLiveResize		{ return _v.preservesContentDuringLiveResize; }
- (BOOL) postsFrameChangedNotifications			{ return _v.postFrameChange; }
- (BOOL) postsBoundsChangedNotifications		{ return _v.postBoundsChange;}
- (int) tag										{ return -1; }
- (int) gState									{ return _gState; }

- (void) setToolTip:(NSString *)string
{
	if(string)
		{
		if(!_toolTipsDict)
			_toolTipsDict = [NSMutableDictionary new];
		if(!_v.hasToolTip && window)
			[self addTrackingRect:bounds
				  owner:self
				  userData:NULL
				  assumeInside: NO];
		_v.hasToolTip = YES;
		[_toolTipsDict setObject:string forKey:self];
		}
	else
		_v.hasToolTip = NO;
}

- (NSString*) toolTip
{
	return _v.hasToolTip ? [_toolTipsDict objectForKey:self] : nil;
}

- (BOOL) _isMouseInToolTipOwnerView
{
NSPoint location = [window mouseLocationOutsideOfEventStream];
NSPoint p = [self convertPoint:location fromView: nil];

	if(NSMouseInRect(p, bounds, [self isFlipped]))
		{
		[NSTimer scheduledTimerWithTimeInterval: 0.5
				 target: self
				 selector: @selector(_isMouseInToolTipOwnerView)
				 userInfo: nil
				 repeats: NO];

		return YES;
		}

	if([__toolTipWindow isVisible])
		[__toolTipWindow orderOut:(__toolTipOwnerView = nil)];

	return NO;
}

- (void) _showToolTip:(id)sender
{
NSEvent *e = (NSEvent *)[sender userInfo];

	if (__toolTipOwnerView == self && ![__toolTipWindow isVisible]
			&& (__toolTipSequenceCounter == [e eventNumber])
			&& [self _isMouseInToolTipOwnerView])
		{
		NSString *tip = [_toolTipsDict objectForKey:self];
		NSRect r;

		if(!__toolTipWindow)							// create shared 
			{											// tool tip window
			NSRect wRect = {{0,3},{170,20}};
			NSColor *y;
			NSView *v;

			__toolTipText = [[NSText alloc] initWithFrame:wRect];
			y = [NSColor colorWithCalibratedRed:1 green:1 blue:0.5 alpha:1];
			[__toolTipText setDrawsBackground:NO];
			[__toolTipText setSelectable:NO];

			__toolTipWindow = [[NSWindow alloc] initWithContentRect:wRect
							 styleMask:NSBorderlessWindowMask
							 backing:NSBackingStoreNonretained	
							 defer:YES];
			[__toolTipWindow setWorksWhenModal:YES];
			[__toolTipWindow setBackgroundColor:y];
			v = [__toolTipWindow contentView];
			v->_v.interfaceStyle = YES;
			[v addSubview:__toolTipText];
			}

		r.origin = [window convertBaseToScreen:[e locationInWindow]];
		r.origin = (NSPoint){NSMinX(r) + 5, NSMinY(r) + 10};

		[__toolTipText setString:tip];
		[__toolTipText sizeToFit];
		r.size = [__toolTipText frame].size;
		r.size.height += 5;
		r.size.width = [[__toolTipText string] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[__toolTipText font], NSFontAttributeName, nil]].width + 10;
		r.size.width = MIN(NSWidth(r), r.size.width);
		[__toolTipWindow setFrame:r display:YES];
		[__toolTipWindow orderFront:nil];
		}
}

- (void) mouseEntered:(NSEvent *)event
{
	if (_v.hasToolTip)
		{
		if((__toolTipOwnerView != nil) && [__toolTipWindow isVisible])
			[__toolTipWindow orderOut: self];

		/* FIXME: according to http://www.macosxhints.com/article.php?story=20061107125819464&query=tooltip
		
		we should read parameters
		NSInitialToolTipDelay	-int	Time delay (milliseconds?)
		NSToolTipAutoWrappingDisabled	-bool	true or false
		NSToolTipsFont	-string	font name
		NSToolTipsFontSize	-int	font size
		*/
		
		__toolTipSequenceCounter = __mouseMovedEventCounter - 1;

		[NSTimer scheduledTimerWithTimeInterval: 1.0
				 target: (__toolTipOwnerView = self)
				 selector: @selector(_showToolTip:)
				 userInfo: event
				 repeats: NO];
		}

	if(event)
		[super mouseEntered:event];
}

- (void) mouseExited:(NSEvent *)event
{
	if (__toolTipOwnerView == self)
		[__toolTipWindow orderOut:(__toolTipOwnerView = nil)];

	if(event)
		[super mouseExited:event];
}

- (void) addCursorRect:(NSRect)aRect					// Cursor rectangles
				cursor:(NSCursor *)anObject
{
GSTrackingRect *m = [GSTrackingRect alloc];

	m->rect = [self convertRect:aRect toView:nil];
	m->tag = 0;
	m->owner = [anObject retain];
	m->userData = self;
	m->inside = YES;
	[[window _cursorRects] addObject:[m autorelease]];
}

- (void) discardCursorRects
{
NSMutableArray *cursorRects = [window _cursorRects];
id e = [cursorRects reverseObjectEnumerator];
GSTrackingRect *o;
  														// Base remove test 
	while ((o = [e nextObject])) 						// upon cursor object
		if ((id)o->userData == self) 
			[cursorRects removeObject: o];
}

- (void) resetCursorRects
{
	[sub_views makeObjectsPerformSelector:@selector(resetCursorRects)];
}

- (void) removeCursorRect:(NSRect)aRect cursor:(NSCursor *)anObject
{
NSMutableArray *cursorRects = [window _cursorRects];
id e = [cursorRects reverseObjectEnumerator];
GSTrackingRect *o;
  														// Base remove test 
	while ((o = [e nextObject])) 						// upon cursor object
		{
		NSCursor *c = (NSCursor *)o->owner;

		if (c == anObject) 
			{
			[cursorRects removeObject: o];
			break;
		}	}
}

- (void) removeTrackingRect:(NSTrackingRectTag)tag
{
NSMutableArray *trackingRects = [window _trackingRects];
int i, j = [trackingRects count];

	for (i = 0; i < j; ++i)
		{
		GSTrackingRect *m = (GSTrackingRect *)[trackingRects objectAtIndex:i];

		if (m->tag == tag)
			{
			[trackingRects removeObjectAtIndex:i];
			return;
		}	}
}

- (NSTrackingRectTag) addTrackingRect:(NSRect)aRect
								owner:(id)anObject
								userData:(void *)data
								assumeInside:(BOOL)flag
{
NSMutableArray *trackingRects = [window _trackingRects];
GSTrackingRect *m = [GSTrackingRect alloc];

	m->rect = [self convertRect:aRect toView:nil];
	m->tag = (++_trackRectTag);
	m->owner = [anObject retain];
	m->userData = data;
	m->inside = flag;
	[trackingRects addObject: [m autorelease]];

	return m->tag;
}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeRect: frame];
	[aCoder encodeRect: bounds];
	[aCoder encodeConditionalObject:super_view];
	[aCoder encodeObject: sub_views];
	[aCoder encodeConditionalObject:window];
	[aCoder encodeConditionalObject:_nextKeyView];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at: &_v];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 0
	NSLog(@"NSView: %@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
//	NSLog(@"nslog worked");
	NSLog(@"viewflags=%d", [aDecoder decodeIntForKey:@"NSvFlags"]);
#endif
	if(![aDecoder allowsKeyedCoding])
		{
		frame = [aDecoder decodeRect];
		bounds = [aDecoder decodeRect];
		super_view = [aDecoder decodeObject];
		sub_views = [aDecoder decodeObject];
		window = [aDecoder decodeObject];
		_nextKeyView = [aDecoder decodeObject];
		[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_v];
		}
	else
		{ // initialize, then subviews and finally superview
		unsigned int viewflags=[aDecoder decodeIntForKey:@"NSvFlags"];
#if 0
		NSLog(@"viewflags=%d", viewflags);
		NSLog(@"self=%@", self);
#endif
		if([aDecoder containsValueForKey:@"NSFrameSize"])
			self=[self initWithFrame:(NSRect){NSZeroPoint, [aDecoder decodeSizeForKey:@"NSFrameSize"]}];
		else
			self=[self initWithFrame:[aDecoder decodeRectForKey:@"NSFrame"]];
#if 0
		NSLog(@"initwithframe done");
		NSLog(@"self=%@", self);
#endif
		self=[super initWithCoder:aDecoder];	// decode attributes defined by NSResponder
#if 0
		NSLog(@"super initwithcoder done");
		NSLog(@"self=%@", self);
#endif
		
#define RESIZINGMASK ((viewflags&0x3f000000)>24)	// 6 bit
		_v.autoresizingMask=RESIZINGMASK;
#if 0
		NSLog(@"%@ autoresizingMask=%02x", self, _v.autoresizingMask);
#endif
#define RESIZESUBVIEWS ((viewflags&0x00800000)==0)
		_v.autoSizeSubviews=RESIZESUBVIEWS;
#if 1
		if(_v.autoresizingMask != 0 && !_v.autoSizeSubviews)
			NSLog(@"autoresizesSubviews=NO and mask=%x: %@", _v.autoresizingMask, self);
#endif
		
		// how to overwrite NSBounds? - does this occur anywhere?

		if([aDecoder containsValueForKey:@"NSDragTypes"])
			[self registerForDraggedTypes:[aDecoder decodeObjectForKey:@"NSDragTypes"]];
		_nextKeyView = [[aDecoder decodeObjectForKey:@"NSNextKeyView"] retain];
#if 0
		if([[aDecoder decodeObjectForKey:@"NSWindow"] isEqual:@"$null"])
			{
			NSLog(@"NSWindow $null!!! %@", aDecoder);
			}
#endif
		[self _setWindow:[aDecoder decodeObjectForKey:@"NSWindow"]];

#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder);
		NSLog(@"  NSvFlags=%08x", [aDecoder decodeIntForKey:@"NSvFlags"]);
#endif
			{ // this may recursively initialize ourselves
			NSArray *svs=[aDecoder decodeObjectForKey:@"NSSubviews"];	// decode subviews - and connect them to us
			NSEnumerator *e=[svs objectEnumerator];
			NSView *sv;
#if 0
			NSLog(@"subviews=%@", svs);
#endif
			while((sv=[e nextObject]))
				{
				if(![sv isKindOfClass:[NSView class]])
					NSLog(@"%@: subview is not derived from NSView: %@", self, sv);
				else
					[self addSubview:sv];	// and add us as the superview
				}
			}
		[aDecoder decodeObjectForKey:@"NSSuperview"];	// finally load superview (if not yet by somebody else)
#if 0
		NSLog(@"superview=%@", [aDecoder decodeObjectForKey:@"NSSuperview"]);
#endif
		[self setNeedsDisplay:YES];
		}
	return self;
}

- (BOOL) mouseDownCanMoveWindow;	{ return ![self isOpaque]; }
- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return YES; }	// permit ink-anywhere

- (void) allocateGState;
{
//	[NSGraphicsContext setGraphicsState:[window gState]];
	// create a new gState
	[self setUpGState];
	// save the gState reference
}

- (void) releaseGState;
{
	// release memory
	_gState=0;
}

- (void) renewGState;
{
	// will be recreated on next focus
}

- (void) setUpGState; { return; }	// default: do nothing

- (void) viewWillStartLiveResize; { return; }

- (void) viewDidEndLiveResize; { return; }

@end /* NSView */
