/* 
   NSColorWell.m

   Color selection and display control.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/NSColor.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSColorPanel.h>
#import <AppKit/NSEvent.h>

#import "NSAppKitPrivate.h"

@implementation NSColorWell

- (id) initWithFrame:(NSRect)frameRect
{
	if((self=[super initWithFrame: frameRect]))
		{
		_cw.isBordered = YES;
		_color = [[NSColor whiteColor] retain];
		}
	return self;
}

- (void) dealloc
{
	[_color release];
	[super dealloc];
}

- (void) drawRect:(NSRect)rect
{
	float inset = 3;
	NSRect r;

	// 	if(![super isEnabled])

	if (_cw.isBordered)
		{
		float grays[] = { NSBlack, NSBlack, NSWhite,	// Draw outer frame
						  NSWhite, NSDarkGray, NSDarkGray };

		r = NSDrawTiledRects(bounds, rect, BUTTON_EDGES_NORMAL, grays, 6);

		if(!_cw.isActive)
			[[NSColor whiteColor] set];
		else
			[[NSColor lightGrayColor] set];
    	}
	else
		{
		r = NSIntersectionRect(bounds, rect);
		[[NSColor lightGrayColor] set];
		inset = 0;
		}

	NSRectFill(r);										// Fill background
	r = NSInsetRect(bounds, inset, inset);
	NSDrawGrayBezel(r, rect);							// Draw inner frame
	r = NSInsetRect(r, 2, 2);

	[self drawWellInside: NSIntersectionRect(r, rect)];
}

- (void) drawWellInside:(NSRect)insideRect
{
	if(NSIsEmptyRect(insideRect))
		return;
	if([_color alphaComponent] != 1.0)
		{ // is not completely opaque
		NSBezierPath *p=[NSBezierPath new];
		[p moveToPoint:NSMakePoint(NSMinX(insideRect), NSMinY(insideRect))];
		[p lineToPoint:NSMakePoint(NSMaxX(insideRect), NSMaxY(insideRect))];
		[p lineToPoint:NSMakePoint(NSMinX(insideRect), NSMaxY(insideRect))];
		[[NSColor blackColor] setFill];
		[p fill];	// black triangle
		[p removeAllPoints];
		[p moveToPoint:NSMakePoint(NSMinX(insideRect), NSMinY(insideRect))];
		[p lineToPoint:NSMakePoint(NSMaxX(insideRect), NSMaxY(insideRect))];
		[p lineToPoint:NSMakePoint(NSMaxX(insideRect), NSMinY(insideRect))];
		[[NSColor whiteColor] setFill];
		[p fill];	// white triangle
		[p release];
		}
	[_color set];
	NSRectFill(insideRect);	// overlay with current color
}

- (void) mouseDown:(NSEvent*)event
{
	if([super isEnabled])
		return;	// ignore
	_cw.isActive = !(_cw.isActive);
	[self setNeedsDisplay:YES];
	if(_cw.isActive)
		{
		NSColorPanel *panel=[NSColorPanel sharedColorPanel];
		[panel makeKeyAndOrderFront:self];
		[panel setAction:@selector(_changeColor:)];
		[panel setTarget:self];
		[panel setContinuous:[super isContinuous]];
		// FIXME: closing the ColorPanel should deactivate the current ColorWell (without changing)!
		// so we need to track the WindowClosed notification
		}
}

- (void) activate:(BOOL)exclusive							// Activation
{
	_cw.isActive = YES;
}

- (void) deactivate
{
	_cw.isActive = NO;
}

- (void) _changeColor:(id)sender
{
	[self setColor:[sender color]];
	[self deactivate];
	// make [super send our action/target]
}

- (NSColor*) color						{ return _color; }
- (BOOL) isActive						{ return _cw.isActive; }
- (BOOL) isOpaque						{ return _cw.isBordered; }
- (BOOL) isBordered						{ return _cw.isBordered; }

- (void) setColor:(NSColor*)color
{
	ASSIGN(_color, color);
	[self setNeedsDisplay:YES];
}

- (void) setBordered:(BOOL)bordered
{
	_cw.isBordered = bordered;
	[self setNeedsDisplay];
}

- (void) takeColorFrom:(id)sender
{
	if([sender respondsToSelector:@selector(color)])
		[self setColor:[sender color]];
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject: _color];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at: &_cw];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		_color=[[aDecoder decodeObjectForKey:@"NSColor"] retain];
		_cw.isBordered=[aDecoder decodeBoolForKey:@"NSIsBordered"];
		return self;
		}
	_color = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_cw];
	
	return self;
}

@end /* NSColorWell */
