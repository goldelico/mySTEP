/** <title>NSProgressIndicator</title>

Copyright (C) 1999 Free Software Foundation, Inc.

Author:  Gerrit van Dyk <gerritvd@decimax.com>
Date: 1999
 
 Adapted: H. Nikolaus Schaller

This file is part of the GNUstep GUI Library.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; see the file COPYING.LIB.
If not, write to the Free Software Foundation,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#import <Foundation/NSTimer.h>
#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

@implementation NSProgressIndicator

NSColor *fillColour = nil;
#define maxCount 20
// NSImage *images[maxCount];

+ (void) initialize
{
	if (self == [NSProgressIndicator class])
		{
		//     [self setVersion: 1];
		// FIXME: Should come from defaults and should be reset when defaults change
		fillColour = [[NSColor blueColor] retain];
		// FIXME: Load the images and set maxCount
		}
}

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame: frameRect]))
		{
		_isIndeterminate = YES;
		_isBezeled = YES;
		_usesThreadedAnimation = YES;
		_animationDelay = 5.0 / 60.0;	// 1 twelfth of a second
		_doubleValue = 0.0;
		_minValue = 0.0;
		_maxValue = 100.0;
		_isDisplayedWhenStopped = YES;
		}
	return self;
}

- (void)dealloc
{
	[_timer release];	// just in case...
	[super dealloc];
}

- (BOOL) isFlipped						{ return YES; }
- (BOOL) isOpaque							{ return NO; }

- (void) animate:(id)sender
{
	if (!_isIndeterminate)
		return;
	
	if (++_count >= maxCount)
		_count = 0;
	
	[self setNeedsDisplay:YES];
}

- (NSTimeInterval)animationDelay { return _animationDelay; }
- (void)setAnimimationDelay:(NSTimeInterval)delay
{
	_animationDelay = delay;
}

- (void) startAnimation:(id)sender
{
	if (!_isIndeterminate || _isRunning)
		return;	// already determinate or already running
	if (_usesThreadedAnimation)
		{
			// Not implemented
		}
	ASSIGN(_timer, [NSTimer scheduledTimerWithTimeInterval: _animationDelay 
														target: self 
													  selector: @selector(animate:)
													  userInfo: nil
													   repeats: YES]);
	_isRunning = YES;
	if (_usesThreadedAnimation)
		[self display];	// most likely the programmer assumes that it becomes at least visible without entering a runloop
	else
		[self setNeedsDisplay:YES];
}

- (void) stopAnimation:(id)sender
{
	if (!_isIndeterminate || !_isRunning)
		return;	
	if (_usesThreadedAnimation)
		{
			// Not implemented
		}
	[_timer invalidate];
	[_timer release];
	_timer=nil;
	_isRunning=NO;
	if (_usesThreadedAnimation)
		[self display];	// most likely the programmer assumes that it becomes at least visible without entering a runloop
	else
		[self setNeedsDisplay:YES];
}

- (BOOL) usesThreadedAnimation
{
	return _usesThreadedAnimation;
}

- (void) setUsesThreadedAnimation:(BOOL)flag
{
	if (_usesThreadedAnimation != flag)
		{
		BOOL wasRunning = _isRunning;
		
		if (wasRunning)
			[self stopAnimation: self];
		
		_usesThreadedAnimation = flag;
		
		if (wasRunning)
			[self startAnimation: self];
		}
}

- (void) incrementBy:(double)delta
{
	_doubleValue += delta;
	if(delta != 0.0)
		[self setNeedsDisplay:YES];
}

- (double) doubleValue { return _doubleValue; }
- (void) setDoubleValue:(double)aValue
{
	if (_doubleValue != aValue)
		{
		_doubleValue = aValue;
		[self setNeedsDisplay:YES];
		}
}

- (double) minValue { return _minValue; }
- (void) setMinValue:(double) newMinimum
{
	if (_minValue != newMinimum)
		{
		_minValue = newMinimum;
		[self setNeedsDisplay:YES];
		}
}

- (double)maxValue { return _maxValue; }
- (void)setMaxValue:(double)newMaximum
{
	if (_maxValue != newMaximum)
		{
		_maxValue = newMaximum;
		[self setNeedsDisplay:YES];
		}
}

- (BOOL)isBezeled { return _isBezeled; }
- (void)setBezeled:(BOOL)flag
{
	if (_isBezeled != flag)
		{
		_isBezeled = flag;
		[self setNeedsDisplay:YES];
		}
}

- (BOOL)isIndeterminate { return _isIndeterminate; }
- (void)setIndeterminate:(BOOL)flag
{
	_isIndeterminate = flag;
	if (flag == NO && _isRunning)
		[self stopAnimation: self];
}

- (BOOL) isDisplayedWhenStopped; { return _isDisplayedWhenStopped; }
- (void) setDisplayedWhenStopped:(BOOL)flag; { _style=_isDisplayedWhenStopped; }
- (NSProgressIndicatorStyle) style; { return _style; }
- (void) setStyle:(NSProgressIndicatorStyle)flag; { _style=flag; }

- (NSControlSize)controlSize
{
	// FIXME
	return NSRegularControlSize;
}

- (void)setControlSize:(NSControlSize)size
{
	// FIXME 
}

- (NSControlTint)controlTint
{
	// FIXME
	return NSDefaultControlTint;
}

- (void)setControlTint:(NSControlTint)tint
{
	// FIXME 
}

- (void) drawRect:(NSRect)rect
{
	if(!_isRunning && !_isDisplayedWhenStopped)
		return;
	if (_isBezeled)
			{
				if(_style == NSProgressIndicatorSpinningStyle)
					/*NSDrawGrayBezel(_bounds, rect)*/;
				else
					NSDrawGrayBezel(_bounds, rect);
			}
	if (_isIndeterminate)
			{ // Draw indeterminate
				CGFloat phi=(_count*2*M_PI)/maxCount;
				if(_isRunning)
					[[NSColor colorWithCalibratedRed:0.5+0.5*sin(phi) green:0.5+0.5*sin(phi+2*M_PI/3) blue:0.5+0.5*sin(phi+4*M_PI/3) alpha:1.0] set];
				else
					[[NSColor grayColor] set];
				if(_style == NSProgressIndicatorSpinningStyle)
					[[NSBezierPath bezierPathWithOvalInRect:_bounds] fill];	// oval (not spinning...)
				else
					NSRectFill(rect);	// rectangular (draw updated parts only)
			}
	else 
			{ // Draw determinate
				double val=(_doubleValue - _minValue) / (_maxValue - _minValue);
				NSRect r = NSInsetRect(_bounds, 1.0, 1.0);
				if(val < 0.0)
					val=0.0;
				else if(val>1.0)
					val=1.0;	// clamp
				if(_style == NSProgressIndicatorSpinningStyle)
						{ // draw "clock"
							NSBezierPath *progress=[NSBezierPath bezierPath];
							NSPoint center=(NSPoint){ NSMidX(r), NSMidY(r) };
							[progress moveToPoint:center];
							[progress appendBezierPathWithArcWithCenter:center
																									 radius:0.25*(NSWidth(r)+NSHeight(r))
																							 startAngle:-90.0
																								 endAngle:360*val-90.0];	// flipped
							[progress closePath];
							[[NSColor blueColor] set];
							[progress fill];
							[[NSBezierPath bezierPathWithOvalInRect:r] stroke];							// draw circle around
						}
				else
						{ // rectangular
							if (NSHeight(r) > NSWidth(r))
								r.size.height = NSHeight(r) * val;
							else
								r.size.width = NSWidth(r) * val;
							[fillColour set];
							NSRectFill(r);
						}
			}
}

// NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at:&_isIndeterminate];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at:&_isBezeled];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at:&_usesThreadedAnimation];
	[aCoder encodeValueOfObjCType: @encode(NSTimeInterval) at:&_animationDelay];
	[aCoder encodeValueOfObjCType: @encode(double) at:&_doubleValue];
	[aCoder encodeValueOfObjCType: @encode(double) at:&_minValue];
	[aCoder encodeValueOfObjCType: @encode(double) at:&_maxValue];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		int piFlags=[aDecoder decodeIntForKey:@"NSpiFlags"];
			
#if 1
			NSLog(@"piFlags = %08x", piFlags);
#endif
#define STYLE ((piFlags&0x1000) >> 12)
#define DISPLAYED_WHEN_STOPPED ((piFlags&0x2000) == 0)
#define INDETERMINATE ((piFlags&0x0002) != 0)
			
			_animationDelay = 5.0 / 60.0;	// 1 twelfth of a second
			_style = STYLE;
			_isDisplayedWhenStopped = DISPLAYED_WHEN_STOPPED;
			_isIndeterminate = INDETERMINATE;
		// which piFlag?
			_isBezeled = YES;
		// separate key?
			_usesThreadedAnimation = YES;
			
		_minValue=[aDecoder decodeFloatForKey:@"NSMinValue"];
		_maxValue=[aDecoder decodeFloatForKey:@"NSMaxValue"];
			_doubleValue=[aDecoder decodeFloatForKey:@"NSValue"];
		(void) [aDecoder decodeObjectForKey:@"NSDrawMatrix"];	// ignore - may be of class NSPSMatrix
		return self;
		}
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_isIndeterminate];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_isBezeled];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_usesThreadedAnimation];
	[aDecoder decodeValueOfObjCType: @encode(NSTimeInterval)
								 at:&_animationDelay];
	[aDecoder decodeValueOfObjCType: @encode(double) at:&_doubleValue];
	[aDecoder decodeValueOfObjCType: @encode(double) at:&_minValue];
	[aDecoder decodeValueOfObjCType: @encode(double) at:&_maxValue];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at:&_isDisplayedWhenStopped];
	return self;
}

- (void) sizeToFit	
{
	// based on style
}

@end
