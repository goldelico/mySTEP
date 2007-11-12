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

	if(docFrameRect.size.width >= bounds.size.width)
		{
		if (proposedNewOrigin.x < docFrameRect.origin.x)
			new.x = docFrameRect.origin.x;
		else 
			{
			float difference = docFrameRect.size.width - bounds.size.width;
	
			if (proposedNewOrigin.x > difference)
				new.x = difference;
			}
		}				// if doc is smaller than bounds do not adjust Y because of a possible offset to doc's origin
	if(docFrameRect.size.height >= bounds.size.height)
		{
		if (proposedNewOrigin.y < docFrameRect.origin.y)
			new.y = docFrameRect.origin.y;
		else 
			{
			float difference = docFrameRect.size.height - bounds.size.height;

			if(proposedNewOrigin.y > difference)
				new.y = difference;
			}
		}

	return new;
}

- (NSRect) documentRect
{
	NSRect documentRect = _documentView?[_documentView frame]:NSZeroRect;;
	documentRect.size.width = MAX( NSWidth(documentRect), NSWidth(bounds));
	documentRect.size.height = MAX( NSHeight(documentRect), NSHeight(bounds));
	return documentRect;
}

- (NSRect) documentVisibleRect
{
	NSSize documentBoundsSize = _documentView?[_documentView bounds].size:NSZeroSize;
	NSRect rect;
	rect.origin = bounds.origin;
	if([self isFlipped] != [_documentView isFlipped])
		rect.origin.y=-rect.origin.y;
	rect.size.width = MIN(documentBoundsSize.width, bounds.size.width);
	rect.size.height = MIN(documentBoundsSize.height, bounds.size.height);
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
	// disable notifications to prevent an infinite loop
	[_documentView setPostsFrameChangedNotifications:NO];	

	NSDebugLog(@"NSClipView viewFrameChanged");		// An unflipped doc view 
													// smaller than clip view 
													// requires an org offset 
	if (mr.size.height < bounds.size.height)		// in order to appear at
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
	[super_view scrollClipView:self toPoint:bounds.origin];
	[super_view reflectScrolledClipView:self];
//	[_documentView setNeedsDisplay:NO];		// reset area to draw in subview
	if(NSWidth(mr) < NSWidth(frame) || NSHeight(mr) < NSHeight(frame))
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
	if(1 || !_clip.copiesOnScroll)
		{
		[super_view scrollClipView:self toPoint:point];
		[_documentView setNeedsDisplay:YES];// we are not copying so redraw the full document view
		}
	else
		{		
		extern BOOL _NSShowAllDrawing;		// defined in NSView
		NSRect ySlice;						// top or bottom slice to redraw
		NSRect xSlice;						// left or right slice to redraw
		NSRect src=NSZeroRect;				// rectangle to copy from
		NSRect dest=NSZeroRect;				// rectangle to copy to
		NSRect start=bounds;				// original origin
		if(start.origin.y != point.y)		 				// scrolling the y axis	
			{												
			if(start.origin.y < point.y)		 			// scroll down document
				{											
				float amount = point.y - start.origin.y;	// calc area visible
															// before and after 
				NSDivideRect(bounds, &ySlice, &dest, amount, NSMinYEdge);
				
				src.origin = dest.origin;
				dest.origin = bounds.origin;				// calc area of slice
															// needing redisplay
				ySlice.origin.y = NSMaxY(bounds) - ySlice.size.height;
				}
			else											// scroll up document 
				{												
				float amount = start.origin.y - point.y;
				
				NSDivideRect(bounds, &ySlice, &dest, amount, NSMinYEdge);
				src.origin = bounds.origin;
				}
			}
		else
			ySlice.size.height = 0;	// not scrolling in y direction
		
		if(start.origin.x != point.x)		 				// scrolling the x axis
			{												
			NSRect xRemainder;	// area to add to ySlice so that we end up with three areas to process
			if(start.origin.x < point.x)		 			// scroll doc right
				{											
				float amount = point.x - start.origin.x;	// calc area visible
															// before and after 
				NSDivideRect(bounds, &xSlice, &xRemainder, amount, NSMinXEdge);
				
				if(start.origin.y != point.y)	
					src.origin.x = xRemainder.origin.x;
				else	 					
					src.origin = xRemainder.origin;
				
				xRemainder.origin = bounds.origin;			// calc area of slice
															// needing redisplay
				xSlice.origin.x = NSMaxX(bounds) - xSlice.size.width;
				}
			else											// scroll doc left
				{											
				float amount = start.origin.x - point.x;	
				
				NSDivideRect(bounds, &xSlice, &xRemainder, amount, NSMinXEdge);
				
				if(start.origin.y != point.y)	
					src.origin.x = bounds.origin.x;	// don't change y
				else	 					
					src.origin = bounds.origin;
				}
			
			if(start.origin.y != point.y)
				{
				dest.size.width = xRemainder.size.width;
				dest.origin.x = xRemainder.origin.x;
				}
			else
				{
				dest.size = xRemainder.size;
				dest.origin = xRemainder.origin;
				}
			}
		else
			xSlice.size.width = 0;	// not scrolling in x direction
		
		src.size=dest.size;
		
		// at this point, we have split up the new ClipView contents into three rectangles:
		//
		// dest - which is derived by copying pixels from src
		// ySlice - a horizontal rect spanning the full bounds width where to draw fresh content
		// xSlice - a vertical rect with same height as dest where to draw fresh content
		
		[self scrollRect:src by:dest.size];	// if threre is anything to copy
		[super_view scrollClipView:self toPoint:point];
		if(!NSIsEmptyRect(xSlice))
			{ // redraw along x axis
#if 0
			NSLog(@"xSlice=%@", NSStringFromRect(xSlice));
#endif
			[self displayRectIgnoringOpacity:xSlice];	// redraw background and subview(s)
			if(_NSShowAllDrawing)
				{
				[self lockFocus];
				[[NSColor redColor] set];
				NSFrameRect(xSlice);
				[self unlockFocus];
				[[NSGraphicsContext currentContext] flushGraphics];
				sleep(1);
				}
			}
		if(!NSIsEmptyRect(ySlice))
			{ // redraw along y axis
			[self displayRectIgnoringOpacity:ySlice];
			if(_NSShowAllDrawing)
				{
				[self lockFocus];
				[[NSColor greenColor] set];
				NSFrameRect(ySlice);
				[self unlockFocus];
				[[NSGraphicsContext currentContext] flushGraphics];
				sleep(1);
				}
			}													
		}
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
#define NOCOPYONSCROLL (cvFlags&0x20)!=0
		_clip.copiesOnScroll = !NOCOPYONSCROLL;
#define DRAWSBACKGROUND (cvFlags&0x40)!=0
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
