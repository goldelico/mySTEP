/* 
NSSplitView.h
 
 Allows multiple views to share a region in a window
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:  Robert Vasvari <vrobi@ddrummer.com>
 Date:	Jul 1998
 Author:  Felipe A. Rodriguez <far@ix.netcom.com>
 Date:	November 1998
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/Foundation.h>

#import <AppKit/AppKit.h>
#import "NSAppKitPrivate.h"

#define NOTICE(notif_name) NSSplitView##notif_name##Notification



@implementation NSSplitView

- (id) initWithFrame:(NSRect)frameRect
{	
	if((self = [super initWithFrame:frameRect]))
		{
		_dividerThickness = _draggedBarWidth = 8;
		[self setDividerColor:[NSColor lightGrayColor]];
//		[self setBackgroundColor:[NSColor lightGrayColor]];
		[self setDimpleImage:[NSImage imageNamed:@"GSDimple"] resetDividerThickness:NO];
		}
	
	return self;
}

- (void) dealloc
{
	[backgroundColor release];
	[dividerColor release];
	[dimpleImage release];
	
	[super dealloc];
}

- (void) mouseDown:(NSEvent *)event 
{
	NSPoint p;
	NSEvent *e;
	NSRect r, r1, bigRect, vr;
	NSView *v=nil, *prev = nil;
	float minCoord = -1, maxCoord = -1;
	int offset = 0, i, count;
	float divVertical, divHorizontal;
	NSDate *distantFuture;
	
	if((count = [sub_views count]) < 2)		// if there are less than two  
		return;								// subviews, there is nothing to do
	
//	[window setAcceptsMouseMovedEvents:YES];
	vr = [self visibleRect];
	// find out which divider was hit
	p = [self convertPoint:[event locationInWindow] fromView:nil];
	for(i = 0; i < count; i++)
		{ // locate subview the divider belongs to; save previous (prev)
		v = [sub_views objectAtIndex:i];
		r = [v frame];
		
		if(!_isVertical)					
			{
			if((p.y > NSMinY(r)) && (p.y < NSMaxY(r)))
				return;	// if click is inside of a subview, return.  should never happen
			if(NSMaxY(r) > p.y)
				{	
				offset = i;								// get enclosing rect
				r = (prev) ? [prev frame] : NSZeroRect;	// for the two views
				r1 = (v) ? [v frame] : NSZeroRect;
				bigRect = NSUnionRect(r1 , r);
				divVertical = _dividerThickness;
				divHorizontal = NSWidth([self frame]);
				minCoord = NSMinY(bigRect) + divVertical;	// set drag limits
				maxCoord = NSMaxY(bigRect) - divVertical;
				r1.origin.y = p.y;
				break;
				}
			}
		else
			{
			if((p.x > NSMinX(r)) && (p.x < NSMaxX(r)))
				return;
			if(NSMaxX(r) > p.x)
				{										
				offset = i;								// get enclosing rect
				r = (prev) ? [prev frame] : NSZeroRect;	// for the two views
				r1 = (v) ? [v frame] : NSZeroRect;
				bigRect = NSUnionRect(r1 , r);
				divHorizontal = _dividerThickness;
				divVertical = NSHeight([self frame]);
				minCoord = NSMinX(bigRect) + divHorizontal;	// set drag limits
				maxCoord = NSMaxX(bigRect) - divHorizontal;
				r1.origin.x = p.x;
				break;
				}
			}
		prev = v;
		}
	
	if(maxCoord == -1)
		return;
	// find out what the dragging limit is 
	if(_delegate && [_delegate respondsToSelector:@selector
		(splitView:constrainMinCoordinate:maxCoordinate:ofSubviewAt:)])
		{	
		if(!_isVertical)
        	{
			float delMinY = minCoord, delMaxY = maxCoord;
			
			[_delegate splitView:self
		  constrainMinCoordinate:&delMinY
				   maxCoordinate:&delMaxY
					 ofSubviewAt:offset];
			if(delMinY > minCoord)					// we are still constrained
				minCoord = delMinY;					// by the original bounds
			if(delMaxY < maxCoord) 
				maxCoord = delMaxY; 
			}
		else
			{
			float delMinX = minCoord, delMaxX = maxCoord;
			
			[_delegate splitView:self
		  constrainMinCoordinate:&delMinX
				   maxCoordinate:&delMaxX
					 ofSubviewAt:offset];
			if(delMinX > minCoord)					// we are still constrained
				minCoord = delMinX;					// by the original bounds
			if(delMaxX < maxCoord) 
				maxCoord = delMaxX; 
			}
		}
	
	[self lockFocus];
	NSRectClip(_bounds);
//	[NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
	[dividerColor set];
	r.size = (NSSize){divHorizontal, divVertical};
	
	e = [NSApp nextEventMatchingMask:GSTrackingLoopMask
						   untilDate:(distantFuture = [NSDate distantFuture]) 
							  inMode:NSEventTrackingRunLoopMode 
							 dequeue:YES];
	
	while([e type] != NSLeftMouseUp)				// user is moving the knob
		{ 											// loop until left mouse up
		if ([e type] == NSLeftMouseDragged)
			p = [self convertPoint:[e locationInWindow] fromView:nil];	// we have a new divider position
		if(!_isVertical)
			{
			if(p.y < minCoord) 
				p.y = minCoord;
			if(p.y > maxCoord) 
				p.y = maxCoord;
			r.origin.y = p.y - (divVertical/2.);
			r.origin.x = NSMinX(vr);
			}
		else
			{
			if(p.x < minCoord) 
				p.x = minCoord;
			if(p.x > maxCoord) 
				p.x = maxCoord;
			r.origin.x = p.x - (divHorizontal/2.);
			r.origin.y = NSMinY(vr);
			}
		NSDebugLog(@"drawing divider at x:%d, y:%d, w:%d, h:%d\n", 
				   (int)NSMinX(r),(int)NSMinY(r),
				   (int)NSWidth(r),(int)NSHeight(r));
		
		NSRectFillUsingOperation(r, NSCompositeXOR);		// draw the divider
		[_window flushWindow];
		e = [NSApp nextEventMatchingMask:GSTrackingLoopMask
							   untilDate:distantFuture 
								  inMode:NSEventTrackingRunLoopMode 
								 dequeue:YES];
		
		NSRectFillUsingOperation(r, NSCompositeXOR);		// undraw divider
		[_window flushWindow];
		}
	
	[self unlockFocus];
//	[NSEvent stopPeriodicEvents];
	r = [prev frame];
	r1 = [v frame];
#if 1
	NSLog(@"r=%@", NSStringFromRect(r));
	NSLog(@"r1=%@", NSStringFromRect(r1));
#endif
	if(!_isVertical)							// resize subviews accordingly
		{
		r.size.height = p.y - NSMinY(bigRect) - (divVertical/2.);
		if(NSHeight(r) < 1.) 
			r.size.height = 1.;
		}
	else
		{
		r.size.width = p.x - NSMinX(bigRect) - (divHorizontal/2.);
		if(NSWidth(r) < 1.) 
			r.size.width = 1.;
		}
	[prev setFrame:r];
	[prev setNeedsDisplay:YES];
	NSDebugLog(@"drawing PREV at x:%d, y:%d, w:%d, h:%d\n", (int)NSMinX(r), 
			   (int)NSMinY(r), (int)NSWidth(r), (int)NSHeight(r));
	
	if(!_isVertical)
		{
		r1.origin.y = p.y + (divVertical/2.);
		if(NSMinY(r1) < 0.) 
			r1.origin.y = 0.;
		r1.size.height = NSHeight(bigRect) - NSHeight(r) - divVertical;
		if(NSHeight(r) < 1.) 
			r.size.height = 1.;
		}
	else
		{
		r1.origin.x = p.x + (divHorizontal/2.);
		if(NSMinX(r1) < 0.) 
			r1.origin.x = 0.;
		r1.size.width = NSWidth(bigRect) - NSWidth(r) - divHorizontal;
		if(NSWidth(r1) < 1.) 
			r1.size.width = 1.;
		}
	[v setFrame:r1];
	[v setNeedsDisplay:YES];
#if 1
	NSLog(@"p=%@", NSStringFromPoint(p));
	NSLog(@"bigRect=%@", NSStringFromRect(bigRect));
	NSLog(@"r=%@", NSStringFromRect(r));
	NSLog(@"r1=%@", NSStringFromRect(r1));
#endif
	NSDebugLog(@"drawing LAST at x:%d, y:%d, w:%d, h:%d\n", (int)NSMinX(r1), 
			   (int)NSMinY(r1), (int)NSWidth(r1), (int)NSHeight(r1));
	
	[_window invalidateCursorRectsForView:self];	
			
//	[window setAcceptsMouseMovedEvents:NO];
//	[self setNeedsDisplay:YES];
}

- (void) adjustSubviews
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillResizeSubviews) object: self];
	
	if((_delegate) && [_delegate respondsToSelector: @selector(splitView:resizeSubviewsWithOldSize:)])
      	[_delegate splitView:self resizeSubviewsWithOldSize:_frame.size];
	else
		{ // split the area up evenly 
		int i, count = [sub_views count];
		int div = (int)(_dividerThickness * (count - 1));
		int w = (int)ceil((NSWidth(_bounds) - div) / count);
		float total = 0, maxSize, divRemainder;
		
		for(i = 0; i < count; i++)
        	{	
			id v = [sub_views objectAtIndex:i];
			NSRect rect, r = [v frame];
			
			if(!_isVertical)
				{					// calc divider thickness not accounted for
				divRemainder = div - (_dividerThickness * i);
				maxSize = total + NSHeight(r) + divRemainder;
				rect = (NSRect){{NSMinX(r),total}, _bounds.size};
				
				if(maxSize <= NSHeight(_bounds))
					{
					total += (NSHeight(r) + _dividerThickness);
					rect.size.height = NSHeight(r);
					}
				else
					{
					rect.size.height = NSHeight(_bounds) - total - divRemainder;
					total += (NSHeight(rect) + _dividerThickness);
					}
				
				if(NSHeight(rect) < 1) 
					rect.size.height = 1;
				if(NSMinY(rect) < 0) 
					rect.origin.y = 0;
				}
			else
				{
				rect.size = NSMakeSize(w, NSHeight(_bounds));
				// make sure nothing spills over
				while((total + NSWidth(rect)) > (NSWidth(_bounds) - div))
					rect.size.width -= 1.;
				
				total += NSWidth(rect);
				
				rect.origin = NSMakePoint((float)ceil(i ? (i * (_dividerThickness + w)) : 0), 0);
				if(NSWidth(rect) < 1) 
					rect.size.width = 1;
				if(NSMinX(rect) < 0) 
					rect.origin.x = 0;
				}
			
			[v setFrame: rect];
			[v setNeedsDisplay:YES];
			}
		}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidResizeSubviews) object: self];
}

- (BOOL) isFlipped							{ return YES; }	// compatibility
- (NSString *) autosaveName;				{ return _autosaveName; }
- (void) setAutosaveName:(NSString *) name; { ASSIGN(_autosaveName, name); }
- (BOOL) isPaneSplitter;					{ return _isPaneSplitter; }
- (void) setIsPaneSplitter:(BOOL) flag;		{ _isPaneSplitter=flag; }
- (BOOL) isVertical							{ return _isVertical; }
- (void) setVertical:(BOOL)flag				{ _isVertical = flag; }
- (void) setDividerThickNess:(float)newWidth{ _dividerThickness = newWidth; }
- (float) dividerThickness 					{ return _dividerThickness; }
- (float) draggedBarWidth 					{ return _draggedBarWidth; }
- (void) setDraggedBarWidth:(float)newWidth	{ _draggedBarWidth = newWidth; }

- (void) drawDividerInRect:(NSRect)aRect
{
	NSPoint dimpleOrg;
	NSSize dimpleSize;
	
	if(!dimpleImage) 								// focus is already on self
		return;
	dimpleSize = [dimpleImage size];
	// composite into the center of the given rect. Since 
	// NSImages are always flipped, we adjust for it here
	dimpleOrg.x = MAX(NSMidX(aRect) - (dimpleSize.width / 2.0), 0.0);
	dimpleOrg.y = MAX(NSMidY(aRect) - (dimpleSize.height / 2.0), 0.0);
//	if([self isFlipped]) 
//		dimpleOrg.y += dimpleSize.height;
	[dimpleImage compositeToPoint:dimpleOrg operation:NSCompositeSourceOver];
}

- (void) setDimpleImage:(NSImage *)anImage resetDividerThickness:(BOOL)flag
{
	ASSIGN(dimpleImage, anImage);
	
	if(flag)
		{
		NSSize s = {8.,8.};
		
		if(dimpleImage) 
			s = [dimpleImage size];
		[self setDividerThickNess: _isVertical ? s.width : s.height];
		}
}

- (void) drawRect:(NSRect)r
{
	int i, count = [sub_views count];
	
	if(backgroundColor)
		{
		[backgroundColor set];
		NSRectFill(r);
		}
	
	for(i = 0; i < (count - 1); i++)						// draw the dimples
		{	
		id v = [sub_views objectAtIndex:i];
		NSRect divRect = [v frame];
		
		if(!_isVertical)
			{
			divRect.origin.y = NSMaxY(divRect);
			divRect.size.height = _dividerThickness;
			}
		else
			{
			divRect.origin.x = NSMaxX(divRect);
			divRect.size.width = _dividerThickness;
			}
		[self drawDividerInRect:divRect];
		}
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if(NSEqualSizes(oldSize, _frame.size))
		return;	// ignore unchanged size
	[self adjustSubviews];
	[_window invalidateCursorRectsForView:self];
}

- (NSImage *) dimpleImage					{ return dimpleImage; }
- (BOOL) isOpaque							{ return backgroundColor != nil; }
- (void) setDividerColor:(NSColor *)aColor	{ ASSIGN(dividerColor, aColor); }
- (void) setBackgroundColor:(NSColor*)aColor{ ASSIGN(backgroundColor,aColor); }
- (NSColor *) dividerColor					{ return dividerColor; }
- (NSColor *) backgroundColor				{ return backgroundColor; }
- (id) delegate								{ return _delegate; }

- (void) setDelegate:(id)anObject
{
	NSNotificationCenter *n;
	
	if(_delegate == anObject)
		return;
	
#define IGNORE_(notif_name) [n removeObserver:_delegate \
										 name:NSSplitView##notif_name##Notification \
									   object:self]
		
		n = [NSNotificationCenter defaultCenter];
	if (_delegate)
		{
		IGNORE_(DidResizeSubviews);
		IGNORE_(WillResizeSubviews);
		}
	
	ASSIGN(_delegate, anObject);
	if(!anObject)
		return;
	
#define OBSERVE_(notif_name) \
	if ([_delegate respondsToSelector:@selector(splitView##notif_name:)]) \
		[n addObserver:_delegate \
			  selector:@selector(splitView##notif_name:) \
				  name:NSSplitView##notif_name##Notification \
				object:self]
		
		OBSERVE_(DidResizeSubviews);
	OBSERVE_(WillResizeSubviews);
}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	NSDebugLog(@"NSSplitView: start encoding\n");
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_delegate];
	[aCoder encodeObject:splitCursor];
	[aCoder encodeObject:dimpleImage];
	[aCoder encodeObject:backgroundColor];
	[aCoder encodeObject:dividerColor];
	[aCoder encodeValueOfObjCType:@encode(int) at:&_dividerThickness];
	[aCoder encodeValueOfObjCType:@encode(int) at:&_draggedBarWidth];
	[aCoder encodeValueOfObjCType:@encode(BOOL) at:&_isVertical];
	NSDebugLog(@"NSView: finish encoding\n");
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		// NSIsPaneSplitter
		_isVertical = [aDecoder decodeBoolForKey:@"NSIsVertical"];
		/*
		 id _delegate;
		int _dividerThickness;
		int _draggedBarWidth;
		id splitCursor;
		BOOL _isVertical;
		NSImage *dimpleImage;
		NSColor *backgroundColor;
		NSColor *dividerColor;
		 */
		[self adjustSubviews];
		return self;
		}
	NSDebugLog(@"NSSplitView: start decoding\n");
	_delegate = [aDecoder decodeObject];
	splitCursor = [aDecoder decodeObject];
	dimpleImage = [aDecoder decodeObject];
	backgroundColor = [aDecoder decodeObject];
	dividerColor = [aDecoder decodeObject];
	[aDecoder decodeValueOfObjCType:@encode(int) at:&_dividerThickness];
	[aDecoder decodeValueOfObjCType:@encode(int) at:&_draggedBarWidth];
	[aDecoder decodeValueOfObjCType:@encode(BOOL) at:&_isVertical];
	NSDebugLog(@"NSView: finish decoding\n");
	
	return self;
}

@end
