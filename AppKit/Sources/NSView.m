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
#import <Foundation/NSAffineTransform.h>

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
#import <AppKit/NSLayoutManager.h>

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
static NSUInteger __mouseMovedEventCounter = 0;
static NSUInteger __toolTipSequenceCounter = 0;

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
	NSInteger i, j = (_trackRects) ? [_trackRects count] : 0;

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
		NSInteger l = 0, k = 0;
	
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

@implementation NSAffineTransform (NSPrivate)

- (NSRect) _transformRect:(NSRect) aRect;
{ // get the smallest (nonrotated) rectangle that covers all 4 transformed points (which are not necessarily a rectangle!)
	NSPoint p1=[self transformPoint:NSMakePoint(NSMinX(aRect), NSMinY(aRect))];
	NSPoint p2=[self transformPoint:NSMakePoint(NSMaxX(aRect), NSMinY(aRect))];
	NSPoint p3=[self transformPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
	NSPoint p4=[self transformPoint:NSMakePoint(NSMinX(aRect), NSMaxY(aRect))];
	p1.x=MIN(MIN(p1.x, p2.x), MIN(p3.x, p4.x));	// get total minimum
	p1.y=MIN(MIN(p1.y, p2.y), MIN(p3.y, p4.y));	// get total minimum
	p4.x=MAX(MAX(p1.x, p2.x), MAX(p3.x, p4.x));	// get total maximum
	p4.y=MAX(MAX(p1.y, p2.y), MAX(p3.y, p4.y));	// get total maximum
	return (NSRect){p1, { p4.x-p1.x, p4.y-p1.y } };
}

@end


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

- (void) cacheDisplayInRect:(NSRect) rect toBitmapImageRep:(NSBitmapImageRep *) bitmapImageRep
{ // draw into bitmap
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapImageRep]];
	[NSBezierPath clipRect:rect];
	[[NSColor clearColor] set];	// make transparent
	NSRectFill(rect);
	[self drawRect:rect];
	[NSGraphicsContext restoreGraphicsState];
}

- (NSBitmapImageRep *) bitmapImageRepForCachingDisplayInRect:(NSRect) rect
{
	// create a new bitmap with appropriate width, height, depth and color space
	return nil;
}

- (void) print:(id) sender
{
	NSPrintOperation *po=[NSPrintOperation printOperationWithView:self];
	[po runOperationModalForWindow:_window delegate:nil didRunSelector:_cmd contextInfo:NULL];
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
	return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Page %ld", (long)[[NSPrintOperation currentOperation] currentPage]]] autorelease];
}

- (NSAttributedString *) pageHeader;
{
	// Check UserDefaults for NSPrintHeaderAndFooter
	return [[[NSAttributedString alloc] initWithString:[self printJobTitle]] autorelease];
}

- (NSString *) printJobTitle;
{
	NSString *title=[[[_window windowController] document] displayName];
	if(title)
		return title;	// if the window controller has a document that has a display name
	return [_window title];	// return the window title or nil
}

- (NSRect) rectForPage:(NSInteger)page;
{
	return _bounds;
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
		[context setFocusStack:fstack];	// does not retain!
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
	return [self lockFocusIfCanDrawInContext:[_window graphicsContext]];
}

- (void) lockFocus
{ // based on gState
	NSMutableArray *fstack;
	NSGraphicsContext *context;
	[NSGraphicsContext saveGraphicsState];
	if(!_window)
		NSLog(@"can't lockFocus without a window");
	else
		{
		NSInteger gState=_gState;
#if FIXME
		if(_gState == 0 /* and there is one allocated */)
			[self setUpGState];
#endif
		if(gState == 0)
			gState=[_window gState];	// get from window - will be 0 if window is ordered out
		if(!gState)
			{
			NSLog(@"could not get a gState to focus on %@", self);
			}
		else
			[NSGraphicsContext setGraphicsState:gState];	// select private state&context if possible
		}
	context=[NSGraphicsContext currentContext];
	[[self _bounds2base] set];	// set required transformation matrix
	if(_v.isRotatedFromBase)
		{
		// set rotated clipping rect for frame
		}
	fstack=(NSMutableArray *) [context focusStack];
	if(!fstack)
		{ // create focus stack
		fstack=[[NSMutableArray alloc] initWithCapacity:3];
		[context setFocusStack:fstack];	// does not retain!
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
	s=[NSMutableString stringWithFormat:@"%p: %@", self, NSStringFromClass([self class])];
	[s appendFormat:@" win=%@", [_window title]];
	[s appendFormat:@" frame=[%.1lf,%.1lf,%.1lf,%.1lf]", _frame.origin.x, _frame.origin.y, _frame.size.width, _frame.size.height];
	[s appendFormat:@" bounds=[%.1lf,%.1lf,%.1lf,%.1lf]", _bounds.origin.x, _bounds.origin.y, _bounds.size.width, _bounds.size.height];
	if(_nInvalidRects == 1)
		[s appendFormat:@" invalid[0]=[%.1lf,%.1lf,%.1lf,%.1lf]", _invalidRects[0].origin.x, _invalidRects[0].origin.y, _invalidRects[0].size.width, _invalidRects[0].size.height];
	if(_nInvalidRects > 1)
		[s appendFormat:@" %lu invalid rects", (unsigned long)_nInvalidRects];
	if([self isHidden]) [s appendString:@" isHidden"];
	if([self isFlipped]) [s appendString:@" isFlipped"];
	if([self isOpaque]) [s appendString:@" isOpaque"];
	if([self canDraw]) [s appendString:@" canDraw"];
	if(_v.autoSizeSubviews) [s appendFormat:@" autosize (%02x)", _v.autoresizingMask];
	if(_v.isRotatedFromBase) [s appendString:@" is rotated"];
	if(_v.isRotatedOrScaledFromBase) [s appendString:@" or scaled"];
	return s;
}

- (NSString *) _subtreeDescription
{
	NSMutableString *s=[NSMutableString stringWithString:[self description]];
	NSEnumerator *e=[_subviews objectEnumerator];
	NSView *v;
	while((v=[e nextObject]))
		{ // prefix all lines with @"  "
		NSString *sub=[v _subtreeDescription];
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
		NSLog(@"NSView: initWithFrame 1 %@", [self _subtreeDescription]);
#endif
		_frame = frameRect;
		_bounds = (NSRect){ NSZeroPoint, _frame.size };
		_frame2bounds = [NSAffineTransform new];	// initialize unit transform
		_subviews = [NSMutableArray new];
#if 0
		NSLog(@"NSView: initWithFrame 2a %@", [self _subtreeDescription]);
#endif
		_v.autoSizeSubviews = YES;
#if 0
		NSLog(@"NSView: initWithFrame 2b %@", [self _subtreeDescription]);
#endif
		[self setMenu:[[self class] defaultMenu]];	// initialize with default menu
#if 0
		NSLog(@"NSView: initWithFrame 3 %@", [self _subtreeDescription]);
#endif
		}
#if 0
	NSLog(@"NSView: initWithFrame -> %@", [self _subtreeDescription]);
#endif
	return self;
}

- (void) dealloc
{
	if(__toolTipOwnerView == self)
		[self mouseExited:nil];	// call before releasing anything
	if(_savedInvalidRects)
		objc_free(_savedInvalidRects);	// no longer needed
	if(_invalidRects)
		objc_free(_invalidRects);	// no longer needed
	// FIXME: release gState if we have a private one
	[_subviews makeObjectsPerformSelector:@selector(_setWindow:) withObject:nil];	// nullify window
	[_subviews makeObjectsPerformSelector:@selector(_setSuperview:) withObject:nil];	// nullify superview
	[_bounds2frame release];
	[_frame2bounds release];
	[_bounds2base release];
	[_base2bounds release];
	[_dragTypes release];
	[_subviews release];	// may release subviews (which now have no superview)
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
	if([_subviews indexOfObjectIdenticalTo:aView] != NSNotFound)
		{
		// FIXME: this is just a Workaround for a more fundamental NIB loading problem!!!
		// FIXME: this does sometimes happen when loading NIBs -- why???
		// IDEA: if we make a CustomView and reference some component before we add the hierarchy
		NSLog(@"%@ is already a subview of %@ (ignored)", aView, self);
		return;
		}

	// FIXME: check for relative position and otherView and insert at expected position
	
	[_subviews addObject:aView];				// Append to our subview list
	[aView _setSuperview:self];
													// Make ourselves the next
	[aView setNextResponder:self];					// responder of the view

	[aView _setWindow:_window];						// place on same window as we are
	[self didAddSubview:aView];
	[aView setNeedsDisplay:YES];					// (re)draw incl. new view
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
	if (aView == self || (_superview == aView))
		return YES;

	if (!_superview)								// No superview then this
		return NO;									// is end of the line

	return [_superview isDescendantOf:aView];
}

- (NSView *) opaqueAncestor
{
	return (!_superview || [self isOpaque]) ? self : [_superview opaqueAncestor];
}

- (BOOL) isHiddenOrHasHiddenAncestor;
{
	return [self isHidden] || (_superview && [_superview isHiddenOrHasHiddenAncestor]);
}

- (NSScrollView *) enclosingScrollView;
{
	static Class scrollViewClass;
	if(!_superview)
		return nil;
	if(!scrollViewClass)
		scrollViewClass=[NSScrollView class];	// get reference (initialized only once)
	if([_superview isKindOfClass:scrollViewClass])
		return (NSScrollView *) _superview;	// found!
	return [_superview enclosingScrollView];	// go up one level
}

- (void) removeFromSuperviewWithoutNeedingDisplay	// also releases the view!
{
	[self retain];	// postpone release
	if(_window)
		{
		if([_window firstResponder] == self)
			[_window makeFirstResponder:_window];
		[self _setWindow:nil];
		}
	if(_superview)
		{
#if 0
		NSLog(@"removeFromSuperviewWithoutNeedingDisplay before: %@", [super_view subviews]);
#endif
		[_superview willRemoveSubview:self];
		[[_superview subviews] removeObjectIdenticalTo:self];	// this is the extra release mentioned in the documentation
		[self _setSuperview:nil];
#if 0
		NSLog(@"removeFromSuperviewWithoutNeedingDisplay after: %@", [super_view subviews]);
#endif
		}
	else
		NSLog(@"trying to remove subview without superview: %@", self);
	[self release];	// postpone any dealloc to here
}

- (void) removeFromSuperview	// also releases the view!
{
	[_superview setNeedsDisplay:YES];	// we could restrict to our own frame rect
	[self removeFromSuperviewWithoutNeedingDisplay];
}

- (void) replaceSubview:(NSView *)oldView with:(NSView *)newView
{
	NSInteger index;
	if(!newView || !oldView)
		{
		NSLog(@"NSView warning - can't replace subview %@ with %@", oldView, newView);
		return;
		}
	if(oldView == newView)
		return;
	index = [_subviews indexOfObjectIdenticalTo:oldView];
	
	if(index != NSNotFound)
		{
		[oldView _setWindow:nil];
		// FIXME: call willMoveToSuperview etc.?
		[oldView _setSuperview:nil];	// CHECKME:before resetting superview or after???
		
		[newView setNextResponder:nil];
		
		[self willRemoveSubview:oldView];
		[_subviews replaceObjectAtIndex:index withObject:newView];
		
		[self didAddSubview:newView];	// CHECKME:before setting superview or after???
		[newView _setSuperview:self];	// must be done before _setWindow:
		[newView _setWindow:_window];
		[newView setNextResponder:self];
		}
	else
		NSLog(@"NSView warning: replaceSubview: not found: %@", oldView);
}

- (void) sortSubviewsUsingFunction:(NSComparisonResult (*)(id ,id ,void *))compare 
						   context:(void *)context
{
	[_subviews sortUsingFunction:compare context:context];
}

- (void) _setWindow:(NSWindow *)newWindow
{
	if(_window == newWindow)
		return;	// no change
	if([_window firstResponder] == self)
		// this may still access the view hierarchy as it was before being changed! It may e.g. call -display
		[_window makeFirstResponder:nil];	// we are currently the first responder of the old window - make the window the responder
	[self viewWillMoveToWindow:newWindow];
	[_bounds2base release], _bounds2base=nil;
	[_base2bounds release], _base2bounds=nil;	// no recursion required (done through sub_views makeObjectsPerformSelector:_cmd)
	if(newWindow)
		_window=newWindow;	// set new window before processing siblings - unless we are tearing down
	[_subviews makeObjectsPerformSelector:_cmd withObject:newWindow];	// recursively for all subviews
	_window=newWindow;	// set new window (always)
	_nInvalidRects=0;	// clear invalid rect list
	if(newWindow)
		{
		[self setNeedsDisplayInRect:_bounds];	// we need to be redisplayed completely in the new window
		_v.needsDisplaySubviews=YES;	// mark to redraw subviews
		}
	[self viewDidMoveToWindow];
}

- (void) viewWillMoveToWindow:(NSWindow *)newWindow
{
	return;	// default: do nothing
}

- (void) viewDidMoveToWindow
{
	return;	// default: do nothing
}

- (void) viewWillMoveToSuperview:(NSView *)newView
{
	return;	// default: do nothing
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

- (void) setFrame:(NSRect)frameRect
{
	NSSize o;
#if 0
	NSLog(@"setFrame: %@ %@", NSStringFromRect(frameRect), self);
#endif
#if 1
	if(NSIsEmptyRect(frameRect))
		NSLog(@"setFrame to empty: %@! %@", NSStringFromRect(frameRect), self);
#endif
	if(NSEqualPoints(_frame.origin, frameRect.origin))
		{ // change size only - required for Cocoa compatibility if subclass overwrites setFrameSize
			[self setFrameSize:frameRect.size];	// this will also post a single notification
			return;
		}
	o=_frame.size;	// remember old size
	_frame=frameRect;
	if(!_v.customBounds)	// otherwise, _bounds2frame should be an identity transform
		_bounds.size = _frame.size;	// always adjust
	[self _invalidateCTM];
#if 0
	NSLog(@"autosize %d %@", _v.autoSizeSubviews, self);
#endif
	[self resizeSubviewsWithOldSize: o];	// Resize subviews if needed
#if 0
	NSLog(@"autosized");
#endif
	if(_v.postFrameChange)
		{
#if 0
		NSLog(@"notify FrameDidChange");
#endif
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
		}
}

- (void) setFrameOrigin:(NSPoint)newOrigin
{
#if 0
	NSLog(@"setFrameOrigin: %@ %@", NSStringFromPoint(newOrigin), self);
#endif
	if(!NSEqualPoints(_frame.origin, newOrigin))
		{
		_frame.origin = newOrigin;
		[self _invalidateCTM];
		}
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
}

- (void) setFrameSize:(NSSize)newSize
{
	NSSize o = _frame.size;
#if 0
	NSLog(@"setFrameSize: %@ %@", NSStringFromSize(newSize), self);
#endif
	if(!NSEqualSizes(o, newSize))
		{
#if 1
		if(newSize.height == 0.0)
			NSLog(@"height == 0!");	// this may occur for empty text fields -> leads to NaN bounds
		if(newSize.width == 0.0)
			NSLog(@"width == 0!");
#endif
		_frame.size = newSize;
		if(!_v.customBounds)	// otherwise, _bounds2frame should be an identity transform
			_bounds.size = _frame.size;	// always adjust
		[self _invalidateCTM];
		// scale if bounds != frame size???
		[self resizeSubviewsWithOldSize:o];	// Resize subviews if needed
		}
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
}

- (void) setFrameRotation:(CGFloat)angle
{
	if(_frameRotation != angle)
		{
		_frameRotation=angle;
		[self _invalidateCTM];
		_v.isRotatedFromBase = _v.isRotatedOrScaledFromBase = YES;	// FIXME should also be set for superviews
		}
	if(_v.postFrameChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
}

- (BOOL) isRotatedFromBase
{
	if (_v.isRotatedFromBase)
		return _v.isRotatedFromBase;
	else 
		return (_superview) ? [_superview isRotatedFromBase] : NO;
}

- (BOOL) isRotatedOrScaledFromBase
{
	if (_v.isRotatedOrScaledFromBase)
		return _v.isRotatedOrScaledFromBase;
	else
		return (_superview) ? [_superview isRotatedOrScaledFromBase] : NO;
}

- (NSRect) frame					{ return _frame; }
- (CGFloat) frameRotation				{ return _frameRotation; }

- (NSRect) centerScanRect:(NSRect)aRect
{
	NSRect n=[self convertRect:aRect toView:nil];		// to NSWindow coordinates
	n.origin=[_window convertBaseToScreen:n.origin];
	n.origin.x=0.5+floorf(n.origin.x);					// to center of screen pixels - don't round!
	n.origin.y=0.5+floorf(n.origin.y);
	n.size.width=rint(n.size.width);					// round to nearest integer size
	n.size.height=rint(n.size.height);
	n.origin=[_window convertScreenToBase:n.origin];	// convert back to NSWindow
	return [self convertRect:n fromView:nil];			// and back to view
}

- (void) _invalidateCTMtoBase;
{ // invalidate direct mapping to screen (only)
	[_bounds2base release], _bounds2base=nil;
	[_base2bounds release], _base2bounds=nil;
	[_subviews makeObjectsPerformSelector:_cmd];	// and invalidate all subviews
}

- (void) _updateFlipped;
{ // check if we or our superview have changed flipping state and clear transformation cache
	BOOL flipped=[self isFlipped];
	BOOL superFlipped=(_superview && [_superview isFlipped]);
	if(flipped != _v.flippedCache || superFlipped != _v.superFlippedCache)
		{ // has changed - must invalidate
			_v.flippedCache=flipped;
			_v.superFlippedCache=superFlipped;
			[self _invalidateCTM];
		}
}

- (void) _invalidateCTM;
{
	_invalidRect=NSZeroRect;	// has become invalid as well
	_nInvalidRects=0;			// requires a setNeedsDisplay
	[_bounds2frame release], _bounds2frame=nil;
	[self _invalidateCTMtoBase];	// subviews can keep their individual bounds2frame mapping intact - only their mapping to the screen will change
}

- (NSAffineTransform *) _base2bounds
{ // cached
	static NSAffineTransform *f;	// flip-transform
	if(!f)
		{ // appending f is not the same as scaleXBy:1.0 yBy:-1.0 (which gets the .tY wrong)
		f=[NSAffineTransform transform];
		[f scaleXBy:1.0 yBy:-1.0];
		[f retain];
		}
	[self _updateFlipped];	// detect changes and trigger recalculation
	if(!_base2bounds)
		{
#if 0
		if([self  isKindOfClass:NSClassFromString(@"FlippableView")])
			NSLog(@"flippable");
#endif
#if 1
		NSLog(@"calculating _base2bounds: %@", self);
#endif
		if(_superview)
			_base2bounds=[[_superview _base2bounds] copy];
		else
			_base2bounds=[NSAffineTransform new];
		if(_superview && _v.superFlippedCache)
			{ // undo flipping of superview (because only our frame position is expressed in flipped coordinates but not our own coordinate system)
				NSRect svbounds=[_superview bounds];
				[_base2bounds translateXBy:0.0 yBy:NSMaxY(svbounds)];
				[_base2bounds appendTransform:f];
				[_base2bounds translateXBy:-NSMinX(_frame) yBy:NSMaxY(_frame)-NSMaxY(svbounds)-NSMinY(svbounds)];	// frame position is expressed in super_view bounds coordinates
			}
		else
			[_base2bounds translateXBy:-NSMinX(_frame) yBy:-NSMinY(_frame)];	// frame position is expressed in super_view bounds coordinates
		if(_frameRotation)
			[_base2bounds rotateByDegrees:-_frameRotation];	// FIXME: dreht bei flipped view um linke obere Ecke statt Mitte?
			// ist auch hier ein appendTransform:rotation etwas anderes als rotateByDegrees?
		// if(_v.customBounds) /* do what?) ;
		[_base2bounds appendTransform:_frame2bounds];	// transform frame (i.e. superview bound) to our bounds
		if(_v.flippedCache)
			{ // finally flip bounds
				[_base2bounds appendTransform:f];	// flip
				[_base2bounds translateXBy:0.0 yBy:-NSMaxY(_bounds)];
			}
		}
	return _base2bounds;
}

- (NSAffineTransform *) _bounds2base;
{
	if(!_bounds2base)
		{ // not yet cached
#if 0
			NSLog(@"calculating _bounds2base: %@", self);
#endif
			_bounds2base=[[self _base2bounds] copy];	// always make a (modifiable) copy
			[_bounds2base invert];	// goes back from window coordinates to our bounds coordinates
#if 0
			NSLog(@"base2bounds=%@", _base2bounds);
			NSLog(@"bounds2base=%@", _bounds2base);
#endif
		}
	return _bounds2base;
}

/* getters */

// OK

- (NSRect) bounds
{ // updated after each modifier call
	return _bounds;
}

// OK

- (CGFloat) boundsRotation;
{
	return _boundsRotation;
}

/* absolute setters */

#define deg2rad(X)	(((double)(X))*(M_PI/180.0))

- (void) _setBoundsTransform:(NSAffineTransformStruct) t;
{ /* set _frame2bounds, invalidate and post notifications */
#if 0
	NSLog(@"_setBoundsTransform: m11=%g m12=%g m21=%g m22=%g tX=%g tY=%g", t.m11, t.m12, t.m21, t.m22, t.tX, t.tY);
	NSLog(@"old bounds=%@ matrix=%@ rot=%g", NSStringFromRect([self bounds]), _frame2bounds, [self boundsRotation]);
#endif
	[_frame2bounds setTransformStruct:t];
	_bounds=[_frame2bounds _transformRect:(NSRect) { NSZeroPoint, _frame.size }];	// does not include frameOrigin and frameRotation! and may remove flipping!
#if 0
	NSLog(@"new bounds=%@ matrix=%@ rot=%g", NSStringFromRect([self bounds]), _frame2bounds, [self boundsRotation]);
#endif
	_v.customBounds=YES;
	[self _invalidateCTM];
	if (_v.postBoundsChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(BoundsDidChange) object: self];
}

// fails @ 180 deg
// FIXME: silently ignore empty bounds

- (void) setBounds:(NSRect) b
{
	// FIXME: needs some work to be 100% compatible to Cocoa
#if 0
	NSLog(@"2 setBounds:%@", NSStringFromRect(b));
#endif
	NSSize frameSize=_frame.size;
	NSAffineTransformStruct t;
	CGFloat sx=b.size.width/frameSize.width;
	CGFloat sy=b.size.height/frameSize.height;
	CGFloat rad=deg2rad(_boundsRotation);
	CGFloat s=sin(rad);
	CGFloat c=cos(rad);
	static CGFloat special;	// non zero value
	//	NSLog(@"%30.30f", 2*asin(1)/180.0);
	//	NSLog(@"%g", sinf(deg2rad(180.0)));
	if(_boundsRotation == 180.0)
		NSLog(@"now 180: s=%g c=%g c+1=%g", s, c, c+1.0);
	if(special == 0.0)
		special=sin(M_PI);	// not 0 since sin(M_PI) = 1.22e-16
	if(1 && (c+1.0) == 0.0)
		{ // this appears to be a buggy optimization in Cocoa because it ignores sgn(c)
			t.m11 = -sx;
			t.m12 = 0;
			t.m21 = 0;
			t.m22 = -sy;
		}
	else
		{ // 180 deg
			t.m11 = c * sx;
			t.m12 = -s * sx;
			t.m21 = s * sy;
			t.m22 = c * sy;
		}
	t.tX=b.origin.x;
	t.tY=b.origin.y;
	[self _setBoundsTransform:t];
}

/*
 * setBoundsSize followed by setBoundsOrigin is the same as setBounds
 * setBoundsOrigin followed by setBoundsSize isn't, because setBoundsSize modifies the origin!
 */

// ok

- (void) setBoundsOrigin:(NSPoint) p;
{
#if 0
	NSLog(@"2 setBoundsOrigin:%@", NSStringFromPoint(p));
#endif
	NSAffineTransformStruct t=[_frame2bounds transformStruct];
#if 0
	NSLog(@"m11=%g m12=%g m21=%g m22=%g tX=%g tY=%g", t.m11, t.m12, t.m21, t.m22, t.tX, t.tY);
#endif
	t.tX=p.x;
	t.tY=p.y;
	[self _setBoundsTransform:t];
}

// OK (maybe except @ 180 degrees)
// FIXME: silently ignore empty bounds

- (void) setBoundsSize:(NSSize) newSize;
{
#if 0
	NSLog(@"2 setBoundsSize:%@", NSStringFromSize(newSize));
#endif
	NSAffineTransformStruct t=[_frame2bounds transformStruct];
#if 0
	NSLog(@"m11=%g m12=%g m21=%g m22=%g tX=%g tY=%g", t.m11, t.m12, t.m21, t.m22, t.tX, t.tY);
#endif
	// There is a "optimization" for 180 rotation that delivers very different results from 179.999 or 180.001
	// mainly, the sign of m11,m22 is changed
	
	if(_boundsRotation == 180.0)
		{
		NSLog(@"now 180");
		}
	// can be skipped if never rotated or scaled:
	double D=t.m11*t.m22 - t.m12*t.m21;
	NSPoint o={ (t.m22*t.tX-t.m21*t.tY)/D, (t.m11*t.tY-t.m12*t.tX)/D };	// remove rotation and scale
	CGFloat sx=newSize.width/_frame.size.width;
	CGFloat sy=newSize.height/_frame.size.height;
	if(_boundsRotation == 180.0)
		NSLog(@"now 180");
	CGFloat s=sin(deg2rad(_boundsRotation));
	CGFloat c=cos(deg2rad(_boundsRotation));
	// t.m?? increasingly differs from Cocoa after translateOriginToPoint
	// especially we find differences in the matrix that we reconstruct here directly from boundsRotation, newSize and frame.size
	// the only explanation is that Cocoa dynamically calculates s/c from the old t.m?? values - i.e. ignores sin(rotation)/cos(rotation)
	// i.e. the new rotation matrix should not be /set/ but be calculated
	t.m11 = c * sx;
	t.m12 = -s * sx;
	t.m21 = s * sy;
	t.m22 = c * sy;
	t.tX = t.m11*o.x + t.m21*o.y;	// apply rotation and new scale
	t.tY = t.m12*o.x + t.m22*o.y;
	[self _setBoundsTransform:t];
}

// nok

- (void) setBoundsRotation:(CGFloat) a;
{
#if 0
	NSLog(@"2 setBoundsRotation:%g", a);
#endif
	NSAffineTransformStruct t=[_frame2bounds transformStruct];
#if 0
	NSLog(@"m11=%g m12=%g m21=%g m22=%g tX=%g tY=%g", t.m11, t.m12, t.m21, t.m22, t.tX, t.tY);
#endif
	CGFloat rad=deg2rad(a);
	CGFloat c=cos(rad);
	CGFloat s=sin(rad);
	CGFloat Q = t.m11*t.m11+t.m12*t.m12+t.m21*t.m21+t.m22*t.m22;
	CGFloat D = t.m11*t.m22-t.m12*t.m21;	// invariants (don't change for rotations)
	NSPoint o={ (t.m22*t.tX-t.m21*t.tY)/D, (t.m11*t.tY-t.m12*t.tX)/D };	// remove rotation and scale from origin
	// FIXME: when do we use -sqrt and when +sqrt???
	CGFloat sx = sqrt(0.5*(Q + sqrt(Q*Q - 4*D*D)));
	CGFloat sy = D / sx;	// = sqrt(0.5*(Q - sqrt(Q*Q - 4*D*D))); but a division is cheaper than sqrt
	t.m11 = c * sx;
	t.m12 = -s * sx;
	t.m21 = s * sy;
	t.m22 = c * sy;
	t.tX = t.m11*o.x + t.m21*o.y;	// apply rotation and new scale
	t.tY = t.m12*o.x + t.m22*o.y;
	_boundsRotation=a;	// protect against rounding errors
	[self _setBoundsTransform:t];
}

/* relative modifiers */

// OK

- (void) rotateByAngle:(CGFloat) a;
{
#if 0
	NSLog(@"2 rotateByAngle:%g", a);
#endif
	NSAffineTransformStruct t=[_frame2bounds transformStruct];
	CGFloat rad=deg2rad(a);
	CGFloat c=cos(rad);
	CGFloat s=sin(rad);
	NSAffineTransformStruct n;
	n.m11=c*t.m11+s*t.m12;
	n.m12=-s*t.m11+c*t.m12;
	n.m21=c*t.m21+s*t.m22;
	n.m22=-s*t.m21+c*t.m22;
	n.tX=c*t.tX+s*t.tY;
	n.tY=-s*t.tX+c*t.tY;
	_boundsRotation += a;
	[self _setBoundsTransform:t];
}

// OK

- (void) translateOriginToPoint:(NSPoint) p;
{
#if 0
	NSLog(@"2 translateOriginToPoint:%@", NSStringFromPoint(p));
#endif
	NSAffineTransformStruct t=[_frame2bounds transformStruct];
	t.tX -= p.x;
	t.tY -= p.y;
	[self _setBoundsTransform:t];
}

// OK

- (void) scaleUnitSquareToSize:(NSSize) sz;
{
#if 0
	NSLog(@"2 scaleUnitSquareToSize:%@", NSStringFromSize(sz));
#endif
	NSAffineTransformStruct t=[_frame2bounds transformStruct];
	t.m11 /= sz.width;
	t.m12 /= sz.height;
	t.m21 /= sz.width;
	t.m22 /= sz.height;
	t.tX /= sz.width;
	t.tY /= sz.height;
	[self _setBoundsTransform:t];
}

+ (NSAffineTransform *) _matrixFromView:(NSView *) from toView:(NSView *) to;
{ // transform from 'from' -> base -> 'to' - NOTE: result is NOT necessarily a mutable copy!
	NSAffineTransform *atm;
	if(from == to)
		{ // return identity matrix
			static NSAffineTransform *identity;
			if(!identity) identity=[[NSAffineTransform alloc] init];	// a singleton
			return identity;
		}
	if(!from)
		return [to _base2bounds];	// convert from window coordinates to base only
	atm=[from _bounds2base];	// convert from bounds to window coordinates
	if(to)
		{ // and transform from window to base
#if 0	// UnitTest shows that this is not an exception on Cocoa!
			if([from window] != [to window])
				{
#if 1
				NSLog(@"from: %@", from);
				NSLog(@"to: %@", to);
#endif
				[NSException raise:NSInternalInconsistencyException format:@"views do not belong to the same window"];				
				}
#endif
			atm=[[atm copy] autorelease];	// get a safely modifiable copy
			[atm appendTransform:[to _base2bounds]];
		}
	return atm;
}

- (NSPoint) convertPointFromBase:(NSPoint) p
{
	return [[self _base2bounds] transformPoint:p];
}

- (NSPoint) convertPointToBase:(NSPoint) p
{
	return [[self _bounds2base] transformPoint:p];	
}

- (NSSize) convertSizeFromBase:(NSSize) sz
{
	return [[self _base2bounds] transformSize:sz];
}

- (NSSize) convertSizeToBase:(NSSize) sz
{
	return [[self _bounds2base] transformSize:sz];	
}

// FIXME: check this with a unit test for flipping glitches and rotated bounds

- (NSRect) convertRectFromBase:(NSRect) r
{
	return [[self _base2bounds] _transformRect:r];
}

- (NSRect) convertRectToBase:(NSRect) r
{
	// FIXME: this may be broken if flipping is involved! Use convertRect: toView:nil
	return [[self _bounds2base] _transformRect:r];	
}

- (NSPoint) convertPoint:(NSPoint)aPoint fromView:(NSView*)aView
{
	if(aView == self)
		return aPoint;
	return [[[self class] _matrixFromView:aView toView:self] transformPoint:aPoint];
}

- (NSRect) convertRect:(NSRect)aRect fromView:(NSView *)aView
{
	NSRect r;
	NSAffineTransform *atm;
	if(aView == self)
		return aRect;
	atm=[[self class] _matrixFromView:aView toView:self];
#if 0
	NSLog(@"convert rect atm: %@", atm);
#endif
	// FIXME: check this with a unit test for flipping glitches and rotated bounds
	if(_v.isRotatedFromBase)
		r=[atm _transformRect:aRect];
	else
		{
		r.origin=[atm transformPoint:aRect.origin];
		r.size=[atm transformSize:aRect.size];
		if((aRect.size.height < 0) != (r.size.height < 0))
			r.origin.y-=(r.size.height=-r.size.height);	// there was some flipping involved: r.size.height=sgn(aRect.size.height)*abs(r.size.height)
		}
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
	s=[[[self class] _matrixFromView:aView toView:self] transformSize:aSize];
	if((aSize.height < 0) != (s.height < 0))
		s.height=-s.height;
	return s;
}

- (NSPoint) convertPoint:(NSPoint)aPoint toView:(NSView *)aView
{
	if(aView == self)
		return aPoint;
	return [[[self class] _matrixFromView:self toView:aView] transformPoint:aPoint];
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
	// FIXME
	if(1 || _v.isRotatedFromBase)
		{
#if 0
		NSLog(@"slow"),
#endif
		atm=[[self class] _matrixFromView:self toView:aView];
		// FIXME: check this with a unit test for flipping glitches and rotated bounds
		r=[atm _transformRect:aRect];
		}
	else
		{
#if 0
		NSLog(@"fast");
#endif
		// FIXME: can we do without matrix calculations at all?
		atm=[[self class] _matrixFromView:self toView:aView];
		r.origin=[atm transformPoint:aRect.origin];
		r.size=[atm transformSize:aRect.size];
		if((aRect.size.height < 0) != (r.size.height < 0))
			r.origin.y-=(r.size.height=-r.size.height);	// there was some flipping involved
		}
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
	s=[[[self class] _matrixFromView:self toView:aView] transformSize:aSize];
	if((aSize.height < 0) != (s.height < 0))
		s.height=-s.height;
	return s;
}

- (void) _setSuperview:(NSView *)superview		
{
	if(superview == _superview)
		return;	// nothing to do
	if(!superview)
		{
	if([_superview isKindOfClass:[NSBox class]])
		NSLog(@"is child of NSBox %@", self);
	if([superview isKindOfClass:[NSBox class]])
		NSLog(@"becomes child of NSBox %@", self);
	if([[_superview superview] isKindOfClass:[NSBox class]])
		NSLog(@"is grandchild of NSBox %@", self);
	if([[superview superview] isKindOfClass:[NSBox class]])
		NSLog(@"becomes grandchild of NSBox %@", self);
		}
	[self viewWillMoveToSuperview:superview];
	_superview=superview;
	if(!_superview)
		{
		[self viewDidMoveToSuperview];
		return;	// removed
		}
	[self _invalidateCTMtoBase];	// update when needed
	if(_v.hasToolTip)
		{
		NSMutableArray *trackRects = [_window _trackingRects];
		NSUInteger i, j = [trackRects count];

		for (i = 0; i < j; ++i)
			{
			GSTrackingRect *m = (GSTrackingRect *)[trackRects objectAtIndex:i];

			if (m->owner == self)
				{
				[trackRects removeObjectAtIndex:i];
				break;
				}
			}

		[self addTrackingRect:_bounds owner:self userData:NULL assumeInside:NO];
		}
	[self viewDidMoveToSuperview];
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
#if 0
	NSLog(@"resizeSubviewsWithOldSize:%@ -> %@ %@", NSStringFromSize(oldSize), NSStringFromSize(_frame.size), self);
	NSLog(@"subviews=%@", _subviews);
#endif
	if (_v.isRotatedFromBase)
		{ // only if we have never been rotated
#if 1
		NSLog(@"can't resizeSubviewsWithOldSize (rotated base): %@", self);
#endif
		return;
		}
	if (_v.autoSizeSubviews)
		{	// resize subviews only if we are supposed
		NSInteger i, count = [_subviews count];
		for (i = 0; i < count; i++)		// resize the subviews
			[[_subviews objectAtIndex:i] resizeWithOldSuperviewSize: oldSize];
		return;
		}
#if 1
		NSLog(@"don't autoSizeSubviews: %@", self);
#endif
}

- (void) resizeWithOldSuperviewSize:(NSSize)oldSize		
{ // calls setFrame: and setFrameSize:
	CGFloat change, changePerOption;
	NSRect newFrame = _frame;
	NSSize superViewFrameSize;	// super_view should not be nil!
	BOOL changedOrigin = NO;
	BOOL changedSize = NO;
	int options = 0;
	if(!_superview)
		return;	// how can this happen? We are called as [[sub_views objectAtIndex:i] resizeWithOldSuperviewSize: oldSize]
	superViewFrameSize = [_superview bounds].size;
	if(NSEqualSizes(oldSize, superViewFrameSize))
		return;	// ignore unchanged superview size
#if 0
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
		if(change != 0.0)
			{
			changePerOption = change / options;		
			
			if(_v.autoresizingMask & NSViewWidthSizable)		
				{		
				CGFloat oldFrameWidth = newFrame.size.width;
				
				newFrame.size.width += changePerOption;
				// NSWidth(frame) = MAX(0, NSWidth(frame) + changePerOption);
				if (NSWidth(newFrame) < 0)
					{
			//		NSAssert((NSWidth(old_frame) <= 0), @"View frame width <= 0!");
					NSLog(@"resizeWithOldSuperviewSize: View frame width <= 0!");
					newFrame.size.width = 0;
					}
				if(_v.isRotatedFromBase)
					{
					_bounds.size.width *= newFrame.size.width / oldFrameWidth;	// keep proportion
																				// _bounds.size.width = floorf(_bounds.size.width);
					}
				changedSize = YES;
				}
			if(_v.autoresizingMask & NSViewMinXMargin)
				{
				newFrame.origin.x += changePerOption;
				changedOrigin = YES;
				}
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
	if(options > 0)										// any Y options are
		{												// set in the mask
		change = superViewFrameSize.height - oldSize.height;
		if(change != 0.0)
			{
			changePerOption = change/options;		
			
			if(_v.autoresizingMask & NSViewHeightSizable)		
				{											
				CGFloat oldFrameHeight = newFrame.size.height;
				
				newFrame.size.height += changePerOption;
				if(NSHeight(newFrame) < 0)
					{
					NSLog(@"resizeWithOldSuperviewSize: View frame height <= 0!");
					newFrame.size.height = 0;
					}
				if(_v.isRotatedFromBase)			
					{ // rotated
					_bounds.size.height *= newFrame.size.height/oldFrameHeight;
					// _bounds.size.height = floorf(_bounds.size.height);
					}
				changedSize = YES;
				}
			if([_superview isFlipped])
				{
				if((_v.autoresizingMask & NSViewMaxYMargin))
					{				
					newFrame.origin.y += changePerOption;
					changedOrigin = YES;
					}
				}
			else
				{
				if((_v.autoresizingMask & NSViewMinYMargin))
					{				
					newFrame.origin.y += changePerOption;
					changedOrigin = YES;
					}
				}
			}
		}
	if(changedSize || changedOrigin)
		{
		// CHECKME: does this overwrite bounds.size?
		// Yes, unless we have custom bounds
		[self setFrame:newFrame];
#if 0
		NSLog(@"new frame %@", NSStringFromRect(_frame));
#endif
		if(_v.postFrameChange)
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(FrameDidChange) object: self];
		}
}

- (NSRect) visibleRect
{ // return intersection between frame and superview's visible rect
	if(_window && _superview)
		{
		NSRect s;
		s = [_superview visibleRect];
		s = NSIntersectionRect(s, _frame);	// assume that our frame is also used for clipping
		s = [self convertRect:s fromView:_superview];	// convert to our bounds coordinates
		return NSIntersectionRect(s, _bounds);
		}
	return _bounds;	// if no super view, assume that whole frame is visible
}

// this is the real drawing method

- (void) drawRect:(NSRect)rect
{
	return;	// default implementation does nothing
}

- (BOOL) needsToDrawRect:(NSRect) rect;
{
	int i;
	if(!NSIntersectsRect(rect, _invalidRect))
		return NO;	// outside of overall invalid rect
	for(i = 0; i < _nInvalidRects; i++)
		{ // check individual rects
		if(NSIntersectsRect(rect, _invalidRects[i]))
			return YES;
		}
	return NO;
}

- (void) getRectsBeingDrawn:(const NSRect **) rects count:(NSInteger *) count;
{
	*rects=_savedInvalidRects;
	*count=_nSavedInvalidRects;
}

- (NSRect) rectPreservedDuringLiveResize;
{
	//	NIMP;
	return NSZeroRect;	// FIXME: not yet supported
}

- (void) getRectsExposedDuringLiveResize:(NSRect[4]) rects count:(NSInteger *) count;
{
	//	NIMP;
	*count=0;	// FIXME: not yet supported
}

- (BOOL) needsDisplay;
{
	return !_v.hidden && (_v.needsDisplaySubviews || !NSIsEmptyRect(_invalidRect));	// needs to draw something if not empty
}

- (void) setNeedsDisplay:(BOOL) flag;
{
	if(!_window)
		return;	// ignore if we have no window
	if(flag)
		[self setNeedsDisplayInRect:_bounds];
	else
		{
		_invalidRect=NSZeroRect;
		_v.needsDisplaySubviews=NO;
		}
}

- (void) setNeedsDisplayInRect:(NSRect) rect;
{
	int i;
#if 0
	NSLog(@"-setNeedsDisplayInRect:%@ of %@ superview=%@", NSStringFromRect(rect), self, _superview);
#endif
	if(!_window)
		return;	// ignore if we have no window
	if(NSContainsRect(_invalidRect, rect))
		{
#if 0
		NSLog(@"already known to be invalid");
#endif
		return;	// already known to be dirty
		}
//	_v.needsDisplaySubviews=YES;	// we must also redraw our subviews
#if 0
	NSLog(@"_addRectNeedingDisplay: %@ to %lu", NSStringFromRect(rect), (unsigned long)_nInvalidRects);
#endif
#if 1	// use invalid rects mechanism
	for(i=0; i<_nInvalidRects; i++)
		{ // check if we can merge/expand an existing invalid rect
		if(NSContainsRect(rect, _invalidRects[i]))
			{ // this existing one is completely covered by me - delete
				memmove((char *)&_invalidRects[i], (char *)&_invalidRects[i+1], (char *)(&_invalidRects[--_nInvalidRects])-(char *)(&_invalidRects[i]));
				i--;	// keep index intact
			}
		else if(NSIntersectsRect(rect, _invalidRects[i]))
			{ // overlaps with existing one, delete that one and enlarge our rect to cover both
				rect=NSUnionRect(_invalidRects[i], rect);
				memmove((char *)&_invalidRects[i], (char *)&_invalidRects[i+1], (char *)(&_invalidRects[--_nInvalidRects])-(char *)(&_invalidRects[i]));
				i--;	// keep index intact
			}
		}
	if(_nInvalidRects >= _cInvalidRects)
		_invalidRects=(NSRect *) objc_realloc(_invalidRects, sizeof(_invalidRects[0])*(_cInvalidRects=2*_cInvalidRects+1));	// make more room but at least 1
	_invalidRects[_nInvalidRects++]=rect;	// append
#endif
	_invalidRect=NSUnionRect(_invalidRect, rect);	// merge for overall invalid rect
#if 0
	NSLog(@"  => _nInvalidRects: %lu invalidRect: %@", (unsigned long)_nInvalidRects, NSStringFromRect(_invalidRect));
#endif
	if(_superview)
		{ // FIXME: not rotation-safe
		NSRect r;
		if(NO && [self isOpaque])
			{ // just mark all the superviews to needsDisplaySubviews without updating their dirty rect
			while(_superview)
				{
				self=_superview;
				_v.needsDisplaySubviews=YES;	// mark to redraw subviews
				}
			[_window setViewsNeedDisplay:YES];	// recursion has reached the topmost view
			return;
			}
		r=[self convertRect:rect toView:_superview];
#if 1
		if(NSIsEmptyRect(r))
			NSLog(@"outside superview!");
#endif
		[_superview setNeedsDisplayInRect:r];	// FIXME: we should better loop instead of doing a recursion
		}
	else
		{
#if 0
		NSLog(@"setViewsNeedDisplay: %@", _window);
#endif
		[_window setViewsNeedDisplay:YES];	// upwards recursion has reached the topmost view
		}
}

- (void) setKeyboardFocusRingNeedsDisplayInRect:(NSRect) rect;
{
	// FIXME: this is clipped to bounds...
	[self setNeedsDisplayInRect:NSInsetRect(rect, -5.0, -5.0)];	// invalidate area larger than real bounds
}

// the pattern of the -display methods is: -display-IfNeeded-(In)Rect-IgnoringOpacity

- (void) displayIfNeeded; { if([self needsDisplay]) [self displayRect:_invalidRect]; }
- (void) display; { [self displayRect:_bounds]; }
- (void) displayIfNeededIgnoringOpacity; { if([self needsDisplay]) [self displayRectIgnoringOpacity:_invalidRect]; }
- (void) displayIgnoringOpacity; { [self displayRectIgnoringOpacity:_bounds]; }
- (void) displayIfNeededInRect:(NSRect) rect; { if([self needsDisplay]) [self displayRect:rect]; }
- (void) displayRect:(NSRect) rect; { NSView *a=[self opaqueAncestor]; [a displayRectIgnoringOpacity:[self convertRect:rect toView:a]]; }
- (void) displayIfNeededInRectIgnoringOpacity:(NSRect) rect; { if([self needsDisplay]) [self displayRectIgnoringOpacity:rect]; }
- (void) displayRectIgnoringOpacity:(NSRect) rect; { [self displayRectIgnoringOpacity:rect inContext:[_window graphicsContext]]; [[_window graphicsContext] flushGraphics]; }

- (void) displayRectIgnoringOpacity:(NSRect) rect inContext:(NSGraphicsContext *) context;
{ // recursively draw view and subviews - without flushing
	NSEnumerator *e;
	NSView *subview;
	BOOL locked;
	BOOL displaySubviews;
#if 0
	NSLog(@"displayRectIgnoringOpacity:%@ inContext:%@ for %@", NSStringFromRect(rect), context, self);
#endif
	[self viewWillDraw];	// give views a chance to update, e.g. change layout
	if(!context)
		return;	// has no window (yet)
	if(_savedInvalidRects)
		objc_free(_savedInvalidRects);	// no longer needed
	_savedInvalidRects=_invalidRects;	// copy to buffer
	_nSavedInvalidRects=_nInvalidRects;
	_nInvalidRects=0;	// remove all rects
	_cInvalidRects=0;
	_invalidRects=NULL;	// start with new storage
	_invalidRect=NSZeroRect;	// start over if anyone calls setNeedsDisplayInRect inside drawing code
	if(_v.hidden)
		return;	// don't draw me or my subviews
	rect=NSIntersectionRect(_bounds, rect);	// shrink to bounds (not invalidRect!)
	displaySubviews=_v.needsDisplaySubviews || YES;	// FIXME: geht sonst nicht!
	_v.needsDisplaySubviews=NO;	// prepare since drawing code can call setNeedsDisplay on any subview
	locked=NO;
	if(!NSIsEmptyRect(rect))
		{ // we are dirty ourselves - otherwise we have a dirty but opaque subview
		if(![self lockFocusIfCanDrawInContext:context])
			return;	// can't lock focus
		locked=YES;
		// NOTE: we must be prepared for the case that drawRect: changes our frame and/or bounds and even calls setNeedsDisplay
#if 0
		NSLog(@"_drawRect:%@ %@", NSStringFromRect(rect), self);
#endif
		NS_DURING
			{
				static NSColor *black;
				BOOL clip;
				// FIXME: this should be part of the setUpGState logic
				if(!black) black=[[NSColor blackColor] retain];
				[black set];				// set default
				if(_NSShowAllDrawing && [_window isVisible])
					{ // blink rect that will be redrawn - note that transparent views will get a magenta background by this feature...
					[context saveGraphicsState];
					[[NSColor magentaColor] set];
					NSRectFill(rect);
					[_window flushWindow];
					usleep(300*1000);	// sleep 0.3 seconds so that effect it is visible
					[context restoreGraphicsState];
					}
				if((clip=[self wantsDefaultClipping]))
					{ // may be switched off to speed up
					rect=NSIntersectionRect(rect, _bounds);	// limit to bounds
					[context saveGraphicsState];
					if(_v.isRotatedFromBase)
						{ // FIXME: must also clip to frame (which may be rotated or unrotated)
							// do we do that in lockFocus?
							// or here?
						}
						// FIXME: default should also clip to list of rects in invalidRects!!!
					[NSBezierPath clipRect:rect];	// intersect with our inherited clipping path
					}
#if 1	// detect slow drawing code
			NS_TIME_START(drawRect);
#endif
			[self drawRect:rect];		// that one is overridden in subviews and really draws
#if 1
			NS_TIME_END(drawRect, "drawRect [%.1f,%.1f,%.1f,%.1f] of %s",
						rect.origin.x,rect.origin.y,
						rect.size.width,rect.size.height,
						[[self description] UTF8String]);
#endif
				if(_NSShowAllViews && [_window isVisible])
					{ // draw box around all views
					[[NSColor brownColor] set];
					NSFrameRect(_bounds);
					[_window flushWindow];
					}
				if(clip)
					[context restoreGraphicsState];	// we must restore the clipping path!
			}
		NS_HANDLER
			NSLog(@"%@ -drawRect: NSException %@", NSStringFromClass([self class]), [localException reason]);
		NS_ENDHANDLER
		}
	if(displaySubviews)
		{
		e=[_subviews objectEnumerator];
		while((subview=[e nextObject]))	// go downwards independently of their needsDisplay status since we have redrawn the background
			{
			NSRect subRect;
			if([subview isHidden])		// this saves converting the rect if the subview doesn't want to be drawn
				continue;
			if(!NSIntersectsRect([subview frame], rect))
				{
#if 1
				NSLog(@"subview %@ frame is completely outside rect %@", subview, NSStringFromRect(rect));
#endif
				continue;	// subview is not within rect - ignore transformation
				}
			subRect=[self convertRect:rect toView:subview];	// update subview
			[subview displayRectIgnoringOpacity:subRect inContext:context];
			}
		}
	if(locked)
		[self unlockFocus];	// only after drawing subviews
}

- (BOOL) autoscroll:(NSEvent *)event					// Auto Scrolling
{
	return _superview ? [_superview autoscroll:event] : NO;	// closest ancestor NSClipView will have it overridden
}

- (BOOL) scrollRectToVisible:(NSRect)aRect
{
	if(_superview)
		{
		if([_superview respondsToSelector:@selector(scrollPoint:)])
			{
			NSRect v = [self adjustScroll:[self visibleRect]];
			NSPoint a = [_superview bounds].origin;
			BOOL shouldScroll = NO;
			
			if(NSWidth(v) == 0 && NSHeight(v) == 0)			
				return NO;
			
			if((NSWidth(_bounds) > NSWidth(v)) && !(NSMinX(v) <= NSMinX(aRect) 
												   && (NSMaxX(v) >= NSMaxX(aRect))))		
				{									// X dimension of aRect is not
				shouldScroll = YES;					// within visible rect
				if(aRect.origin.x < v.origin.x)
					a.x = aRect.origin.x;
				else
					a.x = v.origin.x + (NSMaxX(aRect) - NSMaxX(v));
				}
			
			if((NSHeight(_bounds) > NSHeight(v)) && !(NSMinY(v) <= NSMinY(aRect) 
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
				NSView *cSuper = [_superview superview];
				NSDebugLog(@"NSView scrollPoint: (%1.2f, %1.2f)\n", a.x, a.y);
				[cSuper scrollPoint:a];
				if([cSuper respondsToSelector:@selector(reflectScrolledClipView:)])
					[(NSScrollView *)cSuper reflectScrolledClipView:(NSClipView *) cSuper];
				return YES;
				}
			}
		else
			return [_superview scrollRectToVisible:aRect];	// pass up in tree
		}
		
	return NO;
}

- (NSRect) adjustScroll:(NSRect)newVisible				{ return newVisible; }	// default

- (void) reflectScrolledClipView:(NSClipView *)aClipView { return; }	// default

- (void) scrollClipView:(NSClipView *)aClipView 
				toPoint:(NSPoint)aPoint
{
	[aClipView scrollToPoint:aPoint];
}

- (void) scrollPoint:(NSPoint)aPoint
{
	[_superview scrollPoint:aPoint];	// NSClipView will overrride
}

// FIXME:
// [clipView scrollRect:NSMakeRect(0, 0, 100, 100) by:NSMakeSize(10, 30)];
// on MacOS X this defines a rect starting at the lower left corner and moves right/up, i.e. unflipped coordinates
// (at least if the contentView is a NSImageView)
// we must also fix scrollToPoint: in NSClipView to match this

- (void) scrollRect:(NSRect)src by:(NSSize)delta
{ // scroll the rect by given delta (called by scrollPoint)
	NSRect dest;
#if 0
	NSLog(@"scrollRect:%@ by:%@ %@", NSStringFromRect(src), NSStringFromSize(delta), self);
	NSLog(@"window %@", _window);
#endif
	if(![_window isVisible] || (delta.width == 0.0 && delta.height == 0.0) || NSIsEmptyRect(src) || src.size.width <= 0.0 || src.size.height <= 0.0)
		return;	// nothing to scroll
	dest=NSOffsetRect(src, delta.width, delta.height);
//	if(!NSIntersectsRect(dest, _bounds))
//		return;	// no visible result
	[self lockFocus];	// prepare for drawing
	NSCopyBits(0, src, dest.origin);	// copy source rect from current graphics state (0)
	if(_NSShowAllDrawing)
		{ // show copy operation
		[[NSGraphicsContext currentContext] flushGraphics];
		sleep(1);
		[[NSColor blueColor] set];
		NSFrameRect(src);
		[[NSColor yellowColor] set];
		NSFrameRect(dest);
		[[NSGraphicsContext currentContext] flushGraphics];
		sleep(1);
		}
	[self unlockFocus];
}

- (id) viewWithTag:(NSInteger)aTag
{
	NSInteger i, count = [_subviews count];
	id v;
	for (i = 0; i < count; ++i)
		if ([(v = [_subviews objectAtIndex:i]) tag] == aTag)
			return v;
	return nil;
}

// FIXME: this can be pretty time consuming...

- (NSView *) hitTest:(NSPoint) aPoint // aPoint is in superview's coordinates (or window base coordinates if there is no superview)
{
	NSInteger i;
	NSView *v;
	// can we somehow cache this?
	// We go through the view hierarchy twice:
	//  1. to find shouldBeTreatedAsInkEvent
	//  2. if not, to find the view to forward the mouse event to
	// Note: this is a recursive call!
	// basically we need a list of NSRect to NSView mapping that is invalidated as soon as any sub(sub)view moves
	// or we just have a short-term cache that handles the case that hitTest is called for the same point twice (inking!)
#if 0   // doing this trace might slow processing down so much that a double-click is no longer recognized properly
	NSLog(@"%@ hitTest:%@ frame=%@ super-flipped=%d",
		  NSStringFromClass([self class]),
		  NSStringFromPoint(aPoint),
		  NSStringFromRect(_frame),
		  [_superview isFlipped]);
#endif
	if(_v.hidden)
		return nil;	// ignore invisible (sub)views
	if(_superview)
		{
		if(!NSMouseInRect(aPoint, _frame, [_superview isFlipped]))
			{
#if 0
			NSLog(@"  not in rect");
#endif
			return nil;		// If not within our frame then immediately return
			}
		}
	if([_subviews count] > 0)
		{
		aPoint=[self convertPoint:aPoint fromView:_superview];	// transform point from superview's coordinates
		for(i = [_subviews count] - 1; i >= 0; i--)	
			{ // Check our sub_views front to back
				if((v = [[_subviews objectAtIndex:i] hitTest:aPoint]))
					{ // hit in subview
#if 0
					NSLog(@"  found %ld=%@", (long)i, v);
#endif
					return v;
					}
			}
		}
#if 0
	NSLog(@"  success: %@", self);
#endif
	return self;	// mouse is within self
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
	NSInteger i=0, cnt=[_subviews count];
	while(i<cnt)	// Check our sub_views
		{
		if([[_subviews objectAtIndex:i] performKeyEquivalent:event])
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
	NSUInteger i=0, cnt = [_subviews count];
	while(i<cnt)	// Check our sub_views
		{
		if([[_subviews objectAtIndex:i] performMnemonic:string])
			return YES;	// any one responded!
		i++;
		}
	return NO;
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[_window concludeDragOperation:sender];
}

- (NSUInteger) draggingEntered:(id <NSDraggingInfo>)sender
{
	return [_window draggingEntered:sender];
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
	[_window draggingExited:sender];
}

- (NSUInteger) draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [_window draggingUpdated:sender];
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	return [_window performDragOperation:sender];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return [_window prepareForDragOperation:sender];
}

- (NSUInteger) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	// FIXME: override for reasonable defaults!
	return isLocal?0x0000:0x0000;
}

- (NSView *) nextValidKeyView
{ 
	return [_nextKeyView acceptsFirstResponder] ? _nextKeyView : nil;
}

- (NSView *) previousValidKeyView
{ 
NSView *p = [self previousKeyView];

	return [p acceptsFirstResponder] ? p : nil;
}

- (NSView *) previousKeyView
{
NSView *a = [_window initialFirstResponder];
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
- (NSView *) nextKeyView						{ return _nextKeyView; }
- (NSView *) superview							{ return _superview; }
- (NSWindow *) window							{ return _window; }
- (NSMutableArray *) subviews					{ return _subviews; }
- (NSUInteger) autoresizingMask				{ return _v.autoresizingMask; }
- (void) setAutoresizesSubviews:(BOOL)flag		{ _v.autoSizeSubviews = flag; }
- (void) setAutoresizingMask:(NSUInteger)mask	{ _v.autoresizingMask = (unsigned int) mask; }

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
	// FIXME: handle moving firstResponder to nextResponder
		// handle cursor rects
		// etc.
}

- (void) setPreservesContentDuringLiveResize:(BOOL)flag	{ _v.preservesContentDuringLiveResize = flag; }
- (BOOL) autoresizesSubviews					{ return _v.autoSizeSubviews; }
- (BOOL) canBecomeKeyView;						{ return NO; }
- (BOOL) isHidden								{ return _v.hidden; }
- (BOOL) isOpaque								{ return (_superview == nil); }	// only if I represent the NSWindow
- (BOOL) inLiveResize							{ return _superview?[_superview inLiveResize]:NO; }
- (BOOL) shouldDrawColor						{ return YES; }
- (BOOL) wantsDefaultClipping					{ return YES; }
- (BOOL) isFlipped								{ return NO; }
- (BOOL) preservesContentDuringLiveResize		{ return _v.preservesContentDuringLiveResize; }
- (BOOL) postsFrameChangedNotifications			{ return _v.postFrameChange; }
- (BOOL) postsBoundsChangedNotifications		{ return _v.postBoundsChange;}
- (NSInteger) tag								{ return -1; }
- (NSInteger) gState							{ return _gState; }

- (void) setToolTip:(NSString *)string
{
	if(string)
		{
		if(!_toolTipsDict)
			_toolTipsDict = [NSMutableDictionary new];
		if(!_v.hasToolTip && _window)
			[self addTrackingRect:_bounds
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
NSPoint location = [_window mouseLocationOutsideOfEventStream];
NSPoint p = [self convertPoint:location fromView: nil];

	if(NSMouseInRect(p, _bounds, [self isFlipped]))
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

			__toolTipWindow = [[NSPanel alloc] initWithContentRect:wRect
														 styleMask:NSBorderlessWindowMask
														   backing:NSBackingStoreBuffered	// nonretained has backend problems
							 defer:YES];
			[__toolTipWindow setWorksWhenModal:YES];
			[__toolTipWindow setBackgroundColor:y];
			v = [__toolTipWindow contentView];
			[v addSubview:__toolTipText];
			}

		r.origin = [_window convertBaseToScreen:[e locationInWindow]];
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
		
		we should read these parameters from the (global) userdefaults
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
	GSTrackingRect *m = [GSTrackingRect new];
	m->rect = [self convertRect:aRect toView:nil];
	m->tag = 0;
	m->owner = [anObject retain];
	m->userData = self;
	m->inside = YES;
	[[_window _cursorRects] addObject:m];
	[m release];
}

- (void) discardCursorRects
{
NSMutableArray *cursorRects = [_window _cursorRects];
id e = [cursorRects reverseObjectEnumerator];
GSTrackingRect *o;
  														// Base remove test 
	while ((o = [e nextObject])) 						// upon cursor object
		if ((id)o->userData == self) 
			[cursorRects removeObject: o];
}

- (void) resetCursorRects
{
	[_subviews makeObjectsPerformSelector:@selector(resetCursorRects)];
}

- (void) removeCursorRect:(NSRect)aRect cursor:(NSCursor *)anObject
{
	NSMutableArray *cursorRects = [_window _cursorRects];
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
	NSMutableArray *trackingRects = [_window _trackingRects];
	NSInteger i, j = [trackingRects count];

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
	NSMutableArray *trackingRects = [_window _trackingRects];
	GSTrackingRect *m = [GSTrackingRect new];

	m->rect = [self convertRect:aRect toView:nil];
	m->tag = (++_trackRectTag);
	m->owner = [anObject retain];
	m->userData = data;
	m->inside = flag;
	[trackingRects addObject:m];
	[m release];	// m is still retained by trackingRects
	return m->tag;
}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeRect: _frame];
	[aCoder encodeRect: _bounds];
	[aCoder encodeConditionalObject:_superview];
	[aCoder encodeObject: _subviews];
	[aCoder encodeConditionalObject:_window];
	[aCoder encodeConditionalObject:_nextKeyView];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at: &_v];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 0
	NSLog(@"NSView: %@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
//	NSLog(@"nslog worked");
	NSLog(@"1. viewflags=%x", [aDecoder decodeIntForKey:@"NSvFlags"]);
#endif
	if(![aDecoder allowsKeyedCoding])
		{
		_frame = [aDecoder decodeRect];
		_bounds = [aDecoder decodeRect];
		_superview = [aDecoder decodeObject];
		_subviews = [aDecoder decodeObject];
		_window = [aDecoder decodeObject];
		_nextKeyView = [aDecoder decodeObject];
		[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_v];
		}
	else
		{ // initialize, then subviews and finally superview
		unsigned int viewflags=[aDecoder decodeIntForKey:@"NSvFlags"];
#if 0
		NSLog(@"viewflags=%08x", viewflags);
//		NSLog(@"self=%@", self);
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
			NSLog(@"2. viewflags=%x", [aDecoder decodeIntForKey:@"NSvFlags"]);
#endif
		
#define RESIZINGMASK ((viewflags>>0)&0x3f)	// 6 bit
		_v.autoresizingMask=RESIZINGMASK;
#if 0
		NSLog(@"%@ autoresizingMask=%02x", self, _v.autoresizingMask);
#endif
#define RESIZESUBVIEWS (((viewflags>>8)&1) != 0)
		_v.autoSizeSubviews=RESIZESUBVIEWS;
#if 0
		if(_v.autoresizingMask != 0 && !_v.autoSizeSubviews)
			NSLog(@"viewflags=%x viewflags>>8=%x (viewflags>>8)&1=%u autoresizesSubviews=NO and mask=%x: %@", viewflags, viewflags>>8, (viewflags>>8)&1, _v.autoresizingMask, self);
#endif
#define HIDDEN (((viewflags>>31)&1)!=0)
		_v.hidden=HIDDEN;

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
//	[NSGraphicsContext setGraphicsState:[_window gState]];
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

- (void) viewWillDraw;
{
	[_subviews makeObjectsPerformSelector:_cmd];	// send down the hierarchy
}

@end /* NSView */
