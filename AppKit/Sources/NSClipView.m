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
		[self addSubview:_documentView];
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
// CHECKME: is this "standard" behaviour?
		if([aView respondsToSelector:@selector(backgroundColor)])								
			ASSIGN(_backgroundColor, (NSColor *)[(id)aView backgroundColor]);	// copy from document view

		[super_view reflectScrolledClipView:self];
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
	NSSize documentBoundsSize = _documentView?[_documentView bounds].size:NSZeroSize;
	NSRect rect;
	rect.origin = _bounds.origin;
	if([self isFlipped] != [_documentView isFlipped])
		rect.origin.y=-rect.origin.y;
	rect.size.width = MIN(documentBoundsSize.width, _bounds.size.width);
	rect.size.height = MIN(documentBoundsSize.height, _bounds.size.height);
	return rect;
}

- (BOOL) autoscroll:(NSEvent*)event			
{
	NSPoint aPoint = [event locationInWindow];
	NSRect aRect;
	if(!_documentView)
		return NO;
	aRect.origin = [_documentView convertPoint:aPoint fromView:nil];
	aRect.size = (NSSize){10,10};
//	NSLog (@"NSClipView: autoscroll %f, %f ", aPoint.x,aPoint.y);
//	NSLog (@"NSClipView: aRect %f, %f ", aRect.origin.x,aRect.origin.y);
	return [_documentView scrollRectToVisible:aRect];
}

- (void) viewBoundsChanged:(NSNotification*)aNotification
{ // document view notification
	[super_view reflectScrolledClipView:self];
}

- (void) viewFrameChanged:(NSNotification*)aNotification
{ // document view notification
	NSRect mr = [_documentView frame];
	NSRect bounds = [self bounds];
	// disable notifications to prevent an infinite loop
	[_documentView setPostsFrameChangedNotifications:NO];	

	NSDebugLog(@"NSClipView viewFrameChanged");		// An unflipped doc view 
													// smaller than clip view 
													// requires an org offset 
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
	[super_view scrollClipView:self toPoint:bounds.origin];	// will call [self scrollToPoint:] and [self setBounds]
	[super_view reflectScrolledClipView:self];
//	[_documentView setNeedsDisplay:NO];		// reset area to draw in subview
	if(NSWidth(mr) < NSWidth(_frame) || NSHeight(mr) < NSHeight(_frame))
		[self setNeedsDisplayInRect:[self visibleRect]];
}

- (void) scaleUnitSquareToSize:(NSSize)newUnitSize
{
	[super scaleUnitSquareToSize:newUnitSize];
	[super_view reflectScrolledClipView:self];
}

- (void) setBounds:(NSRect)b
{
	[super setBounds:b];
	[super_view reflectScrolledClipView:self];
}

- (void) setBoundsOrigin:(NSPoint)aPoint
{
	[super setBoundsOrigin:aPoint];
	[super_view reflectScrolledClipView:self];
}

- (void) setBoundsSize:(NSSize)aSize
{
	[super setBoundsSize:aSize];
	[super_view reflectScrolledClipView:self];
}

- (void) setFrameSize:(NSSize)aSize
{
	[super setFrameSize:aSize];
	[super_view reflectScrolledClipView:self];
}

- (void) setFrameOrigin:(NSPoint)aPoint
{
	[super setFrameOrigin:aPoint];
	[super_view reflectScrolledClipView:self];
}

- (void) setFrame:(NSRect)rect
{
	[super setFrame:rect];
	[super_view reflectScrolledClipView:self];
}

- (void) translateOriginToPoint:(NSPoint)aPoint
{
	[super translateOriginToPoint:aPoint];
	// no need to call [super_view reflectScrolledClipView:self] here;
}

- (id) documentView								{ return _documentView; }
- (BOOL) isOpaque								{ return YES; }
//- (BOOL) isFlipped								{ return [_documentView isFlipped]; }
- (BOOL) isFlipped								{ return YES; }
- (BOOL) copiesOnScroll							{ return _clip.copiesOnScroll; }
- (BOOL) drawsBackground;						{ return _clip.drawsBackground; }
- (void) setCopiesOnScroll:(BOOL)flag			{ _clip.copiesOnScroll = flag; }
- (void) setDocumentCursor:(NSCursor*)aCursor	{ ASSIGN(_cursor, aCursor); }
- (void) setDrawsBackground:(BOOL) flag			{ _clip.drawsBackground=flag; }
- (NSCursor*) documentCursor					{ return _cursor; }
- (NSColor*) backgroundColor					{ return _backgroundColor; }

- (void) setBackgroundColor:(NSColor*)aColor
{
	ASSIGN(_backgroundColor, aColor);
}

// Disable rotation of clipview

- (void) rotateByAngle:(float)angle				{ NIMP; }
- (void) setBoundsRotation:(float)angle			{ NIMP; }
- (void) setFrameRotation:(float)angle			{ NIMP; }

- (void) scrollToPoint:(NSPoint) point
{
	point=[self constrainScrollPoint:point];
	point.x = floor(point.x);			// avoid rounding errors by constraining the scroll to integer numbers
	point.y = floor(point.y);
	[self setBoundsOrigin:point];		// translate to new origin
}

- (void) scrollPoint:(NSPoint) point
{ // point should lie within the bounds rect of self
	NSRect start=_bounds;				// original origin
	[super_view scrollClipView:self toPoint:point];	// this may round up/down and to a raster
#if 1	// handle copiesOnScroll
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
		
#if 1
		_NSShowAllDrawing=YES;
#endif

		ySlice=(NSRect) { NSZeroPoint, { start.size.width, 0.0 } };
		xSlice=(NSRect) { NSZeroPoint, { 0.0, start.size.height } };

		if(delta.height < 0)		 		// scroll down, i.e. move document up
			{
			src.size.height += delta.height;
			src.origin.y -= delta.height;	// is negative
			ySlice.size.height = -delta.height;
			ySlice.origin.y = NSMaxY(start) - ySlice.size.height;
			}
		else if(delta.width > 0)			// scroll up, i.e. move document down
			{												
			src.size.height -= delta.height;
			ySlice.size.height = delta.height;
			}

		if(delta.width < 0)		 			// scroll doc left
			{											
			src.size.width += delta.width;
			src.origin.y -= delta.width;	// is negative!
			xSlice.size.width = -delta.width;
			xSlice.origin.y = NSMaxX(start) - xSlice.size.width;
			ySlice.size.width += delta.width;
			}
		else if(delta.width > 0)
			{												
			src.size.width -= delta.width;
			xSlice.size.width = delta.width;
			ySlice.origin.x += delta.width;
			ySlice.size.width -= delta.width;
			}

		// at this point, we have split up the new ClipView contents into three rectangles:
		//
		// src+delta - which is derived by copying pixels from src
		// ySlice - a horizontal rect where to draw fresh content
		// xSlice - a vertical rect where to draw fresh content

		[self scrollRect:src by:delta];		// if threre is anything to copy
		if(!NSIsEmptyRect(xSlice))
			{ // redraw along x axis
#if 0
			NSLog(@"xSlice=%@", NSStringFromRect(xSlice));
#endif
			[self setNeedsDisplayInRect:xSlice];	// redraw background and subview(s)
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
			[self setNeedsDisplayInRect:ySlice];
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
#endif
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
{ // limit dirty area to our frame rect
#if 0
	NSLog(@"NSClipView setNeedsDisplayInRect:%@", NSStringFromRect(rect));
	NSLog(@"  frame:%@", NSStringFromRect(frame));
	NSLog(@"  bounds:%@", NSStringFromRect(bounds));
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
	NSLog(@"  frame:%@", NSStringFromRect(frame));
	NSLog(@"  bounds:%@", NSStringFromRect(bounds));
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
	if(_clip.drawsBackground && _backgroundColor)
		{
		[_backgroundColor set];				
		NSRectFill(rect);
		}
//	rect=[self documentVisibleRect];
//	[NSBezierPath clipRect:rect];	// install clipping before drawing the subview
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
#define COPIESONSCROLL ((cvFlags&0x20)==0)
		_clip.copiesOnScroll = COPIESONSCROLL;
#define DRAWSBACKGROUND ((cvFlags&0x40)!=0)
		_clip.drawsBackground = DRAWSBACKGROUND;
		_backgroundColor=[[aDecoder decodeObjectForKey:@"NSBGColor"] retain];
		_cursor=[[aDecoder decodeObjectForKey:@"NSCursor"] retain];
		if([aDecoder containsValueForKey:@"NSBounds"])
			[self setBounds:[aDecoder decodeRectForKey:@"NSBounds"]];
		_documentView=[[aDecoder decodeObjectForKey:@"NSDocView"] retain];
		if(!_backgroundColor && [_documentView respondsToSelector:@selector(backgroundColor)])								
			ASSIGN(_backgroundColor, (NSColor *)[(id)_documentView backgroundColor]);	// copy from document view
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
