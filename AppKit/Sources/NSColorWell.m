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

		r = NSDrawTiledRects(_bounds, rect, BUTTON_EDGES_NORMAL, grays, 6);

		if(!_cw.isActive)
			[[NSColor whiteColor] set];
		else
			[[NSColor lightGrayColor] set];
    	}
	else
		{
		r = NSIntersectionRect(_bounds, rect);
		[[NSColor lightGrayColor] set];
		inset = 0;
		}

	NSRectFill(r);										// Fill background
	r = NSInsetRect(_bounds, inset, inset);
	NSDrawGrayBezel(r, rect);							// Draw inner frame
	r = NSInsetRect(r, 2, 2);

	[self drawWellInside: NSIntersectionRect(r, rect)];
}

- (void) drawWellInside:(NSRect)insideRect
{
	[_color drawSwatchInRect:insideRect];
}

- (void) mouseDown:(NSEvent*)event
{
	if(![super isEnabled])
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
		[panel setColor:_color];	// select our color
		// FIXME: closing the ColorPanel should deactivate the current ColorWell (without changing)!
		// so we need to track the WindowClosed notification
		}
	// start a tracking loop to check if we should call + NSColorPanel (BOOL)dragColor:(NSColor *)color withEvent:(NSEvent *)anEvent fromView:(NSView *)sourceView	
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
	[super sendAction:_action to:_target];	// notify action/target
}

- (NSColor*) color						{ return _color; }
- (BOOL) isActive						{ return _cw.isActive; }
- (BOOL) isOpaque						{ return _cw.isBordered; }
- (BOOL) isBordered						{ return _cw.isBordered; }
- (SEL) action; { return _action; }
- (id) target; { return _target; }
- (void) setAction:(SEL) action; { _action=action; }
- (void) setTarget:(id) target; { _target=target; }

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
		}
	else
		{
		_color = [[aDecoder decodeObject] retain];
		[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_cw];
		}
	return self;
}

@end /* NSColorWell */
