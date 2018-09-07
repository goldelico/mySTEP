/*
   NSClipView.m

   Document scrolling content view of a scroll view.

   Copyright (C) 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#include <unistd.h>

#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>

#import <AppKit/NSClipView.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSLayoutManager.h>

#import "NSAppKitPrivate.h"

@implementation NSClipView

- (id) initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if(self)
		{
		_clip.copiesOnScroll = YES;
		_clip.drawsBackground = YES;
		_backgroundColor = [[NSColor controlBackgroundColor] retain];
		}
	return self;
}

- (void) setDocumentView:(NSView*)aView
{
	NSNotificationCenter *dnc;
#if 0
	NSLog(@"%@ setDocumentView: %@", self, aView);
#endif
	if([_documentView window] != [self window])
		NSLog(@"has different Window");
	if(_documentView == aView)
		return; // unchanged
	dnc = [NSNotificationCenter defaultCenter];
	if (_documentView)
		{ // remove existing
		[dnc removeObserver: self
			 name: NSViewFrameDidChangeNotification
			 object: _documentView];
		[dnc removeObserver: self
			 name: NSViewBoundsDidChangeNotification
			 object: _documentView];
		[_documentView removeFromSuperview];	// this may finally release the view
		}

	if ((_documentView = aView)) 
		{ // add new
		if(![_documentView isDescendantOf:self])
			[self addSubview:_documentView];	// add us first
		[self _invalidateCTM];		// our isFlipped state may change
		[_documentView setNeedsDisplay:YES];	// this should set ourselves dirty
		// Register for notifications sent by the document view 
		[_documentView setPostsFrameChangedNotifications:YES];
		[_documentView setPostsBoundsChangedNotifications:YES];

		[dnc addObserver:self 
			 selector:@selector(viewFrameChanged:)
			 name:NSViewFrameDidChangeNotification 
			 object:_documentView];
		[dnc addObserver:self
			 selector:@selector(viewBoundsChanged:)
			 name:NSViewBoundsDidChangeNotification 
			 object:_documentView];
		[_superview reflectScrolledClipView:self];
		}
}

- (NSPoint) constrainScrollPoint:(NSPoint)proposedNewOrigin
{
	NSRect docFrameRect = [self documentRect];
	NSPoint new = proposedNewOrigin;

	if(docFrameRect.size.width >= _bounds.size.width)
		{
		if (proposedNewOrigin.x < docFrameRect.origin.x)
			new.x = docFrameRect.origin.x;
		else 
			{
			float difference = docFrameRect.size.width - _bounds.size.width;
	
			if (proposedNewOrigin.x > difference)
				new.x = difference;
			}
		}				// if doc is smaller than bounds do not adjust Y because of a possible offset to doc's origin
	if(docFrameRect.size.height >= _bounds.size.height)
		{
		if (proposedNewOrigin.y < docFrameRect.origin.y)
			new.y = docFrameRect.origin.y;
		else 
			{
			float difference = docFrameRect.size.height - _bounds.size.height;

			if(proposedNewOrigin.y > difference)
				new.y = difference;
			}
		}

	return new;
}

- (NSRect) documentRect
{
	NSRect documentRect = _documentView?[_documentView frame]:NSZeroRect;;
	documentRect.size.width = MAX( NSWidth(documentRect), NSWidth(_bounds));
	documentRect.size.height = MAX( NSHeight(documentRect), NSHeight(_bounds));
	return documentRect;
}

- (NSRect) documentVisibleRect
{
	return [self convertRect: _bounds toView:_documentView];
}

- (BOOL) autoscroll:(NSEvent*)event			
{
	NSPoint aPoint = [event locationInWindow];
	NSRect frame=[[self superview] convertRect:[self frame] toView:nil];
	NSRect bounds;
	float dx, dy;
//	NSLog(@"autoscroll");
	if(!_documentView)
		return NO;
	// check for valid event type
	if(NSPointInRect(aPoint, frame))
		{ // is inside - check with screen frame
			aPoint=[[self window] convertBaseToScreen:aPoint];
			frame=NSInsetRect([[[self window] screen] visibleFrame], 30.0, 30.0);
			if(NSPointInRect(aPoint, frame))
				return NO;	// no need to scroll
		}
//	NSLog(@"point=%@ frame=%@", NSStringFromPoint(aPoint), NSStringFromRect(frame));
	dx=0.0, dy=0.0;
	if(aPoint.x < NSMinX(frame))
		dx = aPoint.x - NSMinX(frame);	// how far beyond the left
	else if(aPoint.x > NSMaxX(frame))
		dx = aPoint.x - NSMaxX(frame);	// how far beyond the right
	if(aPoint.y < NSMinY(frame))
		dy = aPoint.y - NSMinY(frame);	// how far below the bottom
	else if(aPoint.y > NSMaxY(frame))
		dy = aPoint.y - NSMaxY(frame);	// how far above the top
//	NSLog(@"dx=%g dy=%g", dx, dy);
	bounds=[self bounds];
	bounds.origin.x += dx;
	bounds.origin.y -= dy;
//	NSLog(@"autoscroll %@ -> %@", NSStringFromRect([self bounds]), NSStringFromPoint(bounds.origin));
	[self scrollToPoint:bounds.origin];
	// FIXME: this does also not help
	// the issue is that if we call autorscoll from the NSPeriodic Event there will be no redraw of the contents!
	// and we see multiple stopPeriodicEvent
	[_documentView setNeedsDisplay:YES];	// if triggered by periodic event
//	NSLog(@"  -> %@", NSStringFromRect([self bounds]));
	// FIXME; also return NO if there is no effective change for whatever reasons (e.g. scrolled to end of document)
	return YES;
}

- (void) viewBoundsChanged:(NSNotification*)aNotification
{ // document view notification
	[_superview reflectScrolledClipView:self];
}

- (void) viewFrameChanged:(NSNotification*)aNotification
{ // document view notification
	NSRect mr = [_documentView frame];
	NSRect bounds = [self bounds];
	if(!_window)
		return;	// ignore
	// disable notifications to prevent an infinite loop
	[_documentView setPostsFrameChangedNotifications:NO];	
#if 0
	NSLog(@"NSClipView viewFrameChanged");		// An unflipped doc view 
													// smaller than clip view 
													// requires an org offset 
#endif
	if (mr.size.height < _bounds.size.height)		// in order to appear at
		{											// top of the clip view.
		mr.origin.y = bounds.size.height - mr.size.height;	
		bounds.origin.y = 0;
		}						// reset doc view origin to 0 if it's height
	else						// becomes greater than the	size of the clip
		{						// view. May occur when init docview is resized 		
		mr.origin.y = 0;
									// if document is not flipped adjust init
		if(![self isFlipped])		// scroll position to be top of clip view.
			bounds.origin.y = mr.size.height - bounds.size.height;
		}
							
	if (mr.size.width < bounds.size.width)
		bounds.origin.x = 0;

	if(![self isFlipped])			// if document is not flipped adjust init
		[_documentView setFrameOrigin:mr.origin];	

	[_documentView setPostsFrameChangedNotifications:YES];			// reenable
	[_superview scrollClipView:self toPoint:bounds.origin];			// will call [self scrollToPoint:] and [self setBounds]
	[_superview reflectScrolledClipView:self];
//	[_documentView setNeedsDisplay:NO];		// reset area to draw in subview
	if(NSWidth(mr) < NSWidth(_frame) || NSHeight(mr) < NSHeight(_frame))
		[self setNeedsDisplayInRect:[self visibleRect]];
}

- (void) scaleUnitSquareToSize:(NSSize)newUnitSize
{
	[super scaleUnitSquareToSize:newUnitSize];
	[_superview reflectScrolledClipView:self];
}

- (void) setBounds:(NSRect)b
{
	[super setBounds:b];
	[_superview reflectScrolledClipView:self];
}

- (void) setBoundsOrigin:(NSPoint)aPoint
{
	[super setBoundsOrigin:aPoint];
	[_superview reflectScrolledClipView:self];
}

- (void) setBoundsSize:(NSSize)aSize
{
	[super setBoundsSize:aSize];
	[_superview reflectScrolledClipView:self];
}

// FIXME: keep scrolling position (bounds) stable

- (void) setFrameSize:(NSSize)aSize
{
	_v.customBounds=NO;
	[super setFrameSize:aSize];
	[_superview reflectScrolledClipView:self];
}

- (void) setFrameOrigin:(NSPoint)aPoint
{
	[super setFrameOrigin:aPoint];
	[_superview reflectScrolledClipView:self];
}

- (void) setFrame:(NSRect)rect
{
	_v.customBounds=NO;
	[super setFrame:rect];
	[_superview reflectScrolledClipView:self];
}

// Disable rotation of clipview

- (void) rotateByAngle:(CGFloat)angle				{ NIMP; }
- (void) setBoundsRotation:(CGFloat)angle			{ NIMP; }
- (void) setFrameRotation:(CGFloat)angle			{ NIMP; }

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
#if 0
	NSLog(@"NSClipView resizeSubviewsWithOldSize %@", self);
#endif
	[_documentView resizeWithOldSuperviewSize: oldSize];	// forward to our document view
}

- (void) translateOriginToPoint:(NSPoint)aPoint
{
	[super translateOriginToPoint:aPoint];
	// no need to call [super_view reflectScrolledClipView:self] here;
}

- (id) documentView								{ return _documentView; }
- (BOOL) isOpaque								{ return YES; }

/* FIXME/CHECKME: do we really have to track the isFlipped status of the documentView???
this is how it should be
but this results in problems with NSTextViews (unflipped) embedded in a NSScrollView (flipped)
because this reverses the writing direction within the text container
*/
// - (BOOL) isFlipped								{ return [_documentView isFlipped]; }

- (BOOL) isFlipped								{ return YES; }
- (BOOL) copiesOnScroll							{ return _clip.copiesOnScroll; }
- (BOOL) drawsBackground;						{ return _clip.drawsBackground; }
- (void) setCopiesOnScroll:(BOOL)flag			{ _clip.copiesOnScroll = flag; }
- (void) setDocumentCursor:(NSCursor*)aCursor	{ ASSIGN(_cursor, aCursor); }
- (void) setDrawsBackground:(BOOL) flag			{ _clip.drawsBackground=flag; }
- (NSCursor*) documentCursor					{ return _cursor; }

- (NSColor*) backgroundColor
{ // try to get from documentView if not explicitly set
	if(!_backgroundColor && [_documentView respondsToSelector:@selector(backgroundColor)])								
		return (NSColor *)[(id)_documentView backgroundColor];	// get from document view
	return _backgroundColor;
}

- (void) setBackgroundColor:(NSColor*)aColor
{
	ASSIGN(_backgroundColor, aColor);
}

- (void) scrollPoint:(NSPoint) point
{ // finish recursion from NSView's default implementation
#if 0
	NSLog(@"scrollPoint %@", NSStringFromPoint(point));
#endif	
	[_superview scrollClipView:self toPoint:point];	// this should call scrollToPoint which may round up/down to raster
}

- (void) scrollToPoint:(NSPoint) point
{ // point should lie within the bounds rect of self
	NSRect start=_bounds;				// original origin before translating
	point=[self constrainScrollPoint:point];
	point.x = floorf(point.x);			// avoid rounding errors by constraining the scroll to integer numbers
	point.y = floorf(point.y);
	[self setBoundsOrigin:point];		// translate to new origin
	[self resetCursorRects];
#if 0
	NSLog(@"scrollToPoint %@", NSStringFromPoint(point));
#endif
	if(_clip.copiesOnScroll)
		{
		extern BOOL _NSShowAllDrawing;		// defined in NSView
		NSRect xSlice;						// left or right slice to redraw
		NSRect ySlice;						// top or bottom slice to redraw
		NSRect src=start;					// rectangle to copy from
		NSSize delta;
		delta.height = start.origin.y - _bounds.origin.y;	// how much have new bounds moved?
		delta.width = start.origin.x - _bounds.origin.x;
		if(delta.width == 0.0 && delta.height == 0.0)
			return;	// not moved
#if 0
		{
			extern BOOL _NSShowAllViews;
			extern BOOL _NSShowAllDrawing;
			_NSShowAllDrawing=YES;
			_NSShowAllViews=YES;
		}
#endif

		ySlice=(NSRect) { start.origin, { start.size.width, 0.0 } };
		xSlice=(NSRect) { start.origin, { 0.0, start.size.height } };

		if(delta.height < 0)		 		// scroll down, i.e. move document up
			{
			src.size.height += delta.height;	// is negative
			src.origin.y -= 2.0*delta.height;	// is negative
			ySlice.size.height = -delta.height;
			ySlice.origin.y = NSMaxY(start);
			}
		else if(delta.height > 0)			// scroll up, i.e. move document down
			{
			src.size.height -= delta.height;
			src.origin.y -= delta.height;
			ySlice.size.height = delta.height;
			ySlice.origin.y -= delta.height;
			}

		if(delta.width < 0)		 			// scroll right, doc left
			{
			src.size.width += delta.width;	// is negative!
			src.origin.x -= 2.0*delta.width;	// is negative!
			xSlice.size.width = -delta.width;
			xSlice.origin.x = NSMaxX(start) - xSlice.size.width;
			ySlice.origin.x -= delta.width;
			ySlice.size.width += delta.width;
			}
		else if(delta.width > 0)
			{									
			src.size.width -= delta.width;
			src.origin.x -= delta.width;
			xSlice.size.width = delta.width;
			xSlice.origin.x -= delta.width;
			ySlice.size.width -= delta.width;
			}

		// at this point, we have split up the new ClipView contents into three rectangles:
		//
		// src+delta - which is derived by copying pixels from src
		// ySlice - a horizontal rect where to draw fresh content
		// xSlice - a vertical rect where to draw fresh content

		[self scrollRect:src by:delta];		// if there is anything to copy (src.size.height/width may be negative)
		if(_NSShowAllDrawing)
			{
			[[NSGraphicsContext currentContext] flushGraphics];
			sleep(1);
			}
		if(!NSIsEmptyRect(xSlice))
			{ // redraw along x axis
#if 0
			NSLog(@"xSlice=%@", NSStringFromRect(xSlice));
#endif
			[self displayRect:xSlice];	// redraw background and subview(s)
			if(_NSShowAllDrawing)
				{
				[self lockFocus];
				[[NSColor redColor] set];
				NSFrameRect(xSlice);
				[self unlockFocus];
				[[NSGraphicsContext currentContext] flushGraphics];
				sleep(1);
				[self displayIfNeeded];
				[[NSGraphicsContext currentContext] flushGraphics];
				sleep(1);
				}
			}
		if(!NSIsEmptyRect(ySlice))
			{ // redraw along y axis
//			[self setNeedsDisplayInRect:ySlice];
//			[_window displayIfNeeded];
			[self displayRect:ySlice];
			if(_NSShowAllDrawing)
				{
				[self lockFocus];
				[[NSColor greenColor] set];
				NSFrameRect(ySlice);
				[self unlockFocus];
				[[NSGraphicsContext currentContext] flushGraphics];
				sleep(1);
				[self displayIfNeeded];
				[[NSGraphicsContext currentContext] flushGraphics];
				sleep(1);
				}
			}
		return;
		}
	[_documentView setNeedsDisplay:YES];			// simply redraw the full document view
}

- (BOOL) becomeFirstResponder
{
	return [_documentView becomeFirstResponder];
}

- (void) resetCursorRects
{
	if(_cursor)
		[self addCursorRect:[self visibleRect] cursor:_cursor];
	[_documentView resetCursorRects];
}

- (void) setNeedsDisplayInRect:(NSRect) rect;
{ // limit dirty area to our visible rect
#if 0
	NSLog(@"NSClipView setNeedsDisplayInRect:%@", NSStringFromRect(rect));
	NSLog(@"  frame:%@", NSStringFromRect(_frame));
	NSLog(@"  bounds:%@", NSStringFromRect(_bounds));
	NSLog(@"  visible:%@", NSStringFromRect([self visibleRect]));
	NSLog(@"  docview:%@", [self documentView]);
	NSLog(@"  docrect:%@", NSStringFromRect([self documentRect]));
	NSLog(@"  docvis:%@", NSStringFromRect([self documentVisibleRect]));
#endif
	rect=NSIntersectionRect(rect, [self visibleRect]);
	[super setNeedsDisplayInRect:rect];
}

- (void) displayRectIgnoringOpacity:(NSRect) rect inContext:(NSGraphicsContext *) context;
{ // never draw outside our frame rect
#if 0
	NSLog(@"NSClipView displayRectIgnoringOpacity:%@", NSStringFromRect(rect));
	NSLog(@"  frame:%@", NSStringFromRect(_frame));
	NSLog(@"  bounds:%@", NSStringFromRect(_bounds));
	NSLog(@"  visible:%@", NSStringFromRect([self visibleRect]));
	NSLog(@"  docview:%@", [self documentView]);
	NSLog(@"  docrect:%@", NSStringFromRect([self documentRect]));
	NSLog(@"  docvis:%@", NSStringFromRect([self documentVisibleRect]));
#endif	
	rect=NSIntersectionRect(rect, [self visibleRect]);
	[super displayRectIgnoringOpacity:rect inContext:context];
}

- (void) drawRect:(NSRect)rect
{
	if(_clip.drawsBackground)
		{
		[[self backgroundColor] set];				
		NSRectFill(rect);
		}
#if 1
	rect=[self documentVisibleRect];
	[NSBezierPath clipRect:rect];	// install clipping before drawing the subview
#endif
}

- (NSView *) hitTest:(NSPoint) aPoint // aPoint is in superview's coordinates (or window base coordinates if there is no superview)
{
#if 0
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
#if 1
			NSLog(@"  not in rect");
#endif
			return nil;		// If not within our frame then immediately return
			}
		}
	return [_documentView hitTest:aPoint];	// ask document view or it't subviews
}

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	NIMP;
}

- (id) initWithCoder:(id)aDecoder
{
	NSNotificationCenter *dnc;
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		long cvFlags=[aDecoder decodeInt32ForKey:@"NScvFlags"];
		// should encode: copies on scroll, drawsBackground
#if 0
		NSLog(@"cvFlags=%08lx", cvFlags);
#endif
#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder);
#endif
#define COPIESONSCROLL ((cvFlags&0x02)==0)
		// sometimes not properly loaded???
		_clip.copiesOnScroll = COPIESONSCROLL;
		_clip.copiesOnScroll = YES;
#define DRAWSBACKGROUND ((cvFlags&0x04)!=0)
		_clip.drawsBackground = DRAWSBACKGROUND;
		_backgroundColor=[[aDecoder decodeObjectForKey:@"NSBGColor"] retain];
		_cursor=[[aDecoder decodeObjectForKey:@"NSCursor"] retain];
		if([aDecoder containsValueForKey:@"NSBounds"])
			[self setBounds:[aDecoder decodeRectForKey:@"NSBounds"]];
		_documentView=[[aDecoder decodeObjectForKey:@"NSDocView"] retain];
		[aDecoder decodeBoolForKey:@"NSAutomaticallyAdjustsContentInsets"];
		if([_documentView window] != [self window])
			NSLog(@"has different Window");
		// Register for notifications sent by the document view 
		[_documentView setPostsFrameChangedNotifications:YES];
		[_documentView setPostsBoundsChangedNotifications:YES];
		dnc = [NSNotificationCenter defaultCenter];
		[dnc addObserver:self 
				selector:@selector(viewFrameChanged:)
					name:NSViewFrameDidChangeNotification 
				  object:_documentView];
		[dnc addObserver:self
				selector:@selector(viewBoundsChanged:)
					name:NSViewBoundsDidChangeNotification 
				  object:_documentView];
		return self;
		}
	return NIMP;
}

@end
