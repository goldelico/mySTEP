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
	float inset = 7;
	NSRect r;

	if (_cw.isBordered)
		{
		float grays[] = { NSBlack, NSBlack, NSWhite,	// Draw outer frame
						  NSWhite, NSDarkGray, NSDarkGray };

		r = NSDrawTiledRects(bounds, rect, BUTTON_EDGES_NORMAL, grays, 6);

		if(_cw.isActive)
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
	if (NSIsEmptyRect(insideRect))
		return;
	[_color set];
	NSRectFill(insideRect);
}

- (void) mouseDown:(NSEvent*)event
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];

	if(!NSMouseInRect(p, NSInsetRect(bounds, 7, 7), NO))
		{	// click on border
		_cw.isActive = !(_cw.isActive);
		[self setNeedsDisplay:YES];
		if(_cw.isActive)
			{
			[[NSColorPanel sharedColorPanel] display];
			[[NSColorPanel sharedColorPanel] makeKeyAndOrderFront:self];
			}
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

- (NSColor*) color						{ return _color; }
- (void) setColor:(NSColor*)color		{ ASSIGN(_color, color); }
- (BOOL) isActive						{ return _cw.isActive; }
- (BOOL) isOpaque						{ return _cw.isBordered; }
- (BOOL) isBordered						{ return _cw.isBordered; }

- (void) setBordered:(BOOL)bordered
{
	_cw.isBordered = bordered;
	[self setNeedsDisplay];
}

- (void) takeColorFrom:(id)sender
{
	if ([sender respondsToSelector:@selector(color)])
		ASSIGN(_color, [sender color]);
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
