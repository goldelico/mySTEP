/*
 NSGradient.m
 
 GUI implementation of a colour gradient.
 
 Copyright (C) 2009 Free Software Foundation, Inc.
 
 Author: Fred Kiefer <fredkiefer@gmx.de>
 Date: Oct 2009
 Author: H. Nikolaus Schaller <hns@computer.org>
 Date: Dec 2007
 
 This file is part of the GNUstep GUI Library.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; see the file COPYING.LIB.
 If not, see <http://www.gnu.org/licenses/> or write to the 
 Free Software Foundation, 51 Franklin Street, Fifth Floor, 
 Boston, MA 02110-1301, USA.
 */ 

#import <Foundation/NSGeometry.h>
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSColorSpace.h"
#import "AppKit/NSGradient.h"
#import "AppKit/NSGraphicsContext.h"
#import "NSAppKitPrivate.h"

#include <math.h>

@implementation NSGradient

- (NSColorSpace *) colorSpace; 
{
	return _colorSpace;
}

- (void) drawFromCenter: (NSPoint)startCenter
                 radius: (CGFloat)startRadius
               toCenter: (NSPoint)endCenter 
                 radius: (CGFloat)endRadius
                options: (NSGradientDrawingOptions)options
{
	[[NSGraphicsContext currentContext] _drawGradient: self
										  fromCenter: startCenter
											  radius: startRadius
											toCenter: endCenter
											  radius: endRadius
											 options: options];
}

- (void) drawFromPoint: (NSPoint)startPoint
               toPoint: (NSPoint)endPoint
               options: (NSGradientDrawingOptions)options
{
	[[NSGraphicsContext currentContext] _drawGradient: self
										   fromPoint: startPoint
											 toPoint: endPoint
											 options: options];
}

- (void) drawInBezierPath: (NSBezierPath *)path angle: (CGFloat)angle
{
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	
	[currentContext saveGraphicsState];
	[path addClip];
	[self drawInRect: [path bounds] angle: angle];
	[currentContext restoreGraphicsState];
}

- (void) drawInBezierPath: (NSBezierPath *)path
   relativeCenterPosition: (NSPoint)relativeCenterPoint
{
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	
	[currentContext saveGraphicsState];
	[path addClip];
	[self drawInRect: [path bounds] relativeCenterPosition: relativeCenterPoint];
	[currentContext restoreGraphicsState];
}

- (void) drawInRect: (NSRect)rect angle: (CGFloat)angle
{
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	NSPoint startPoint;
	NSPoint endPoint;
	CGFloat rad;
	CGFloat length;
	
	// Normalize to 0.0 <= angle <= 360.0
	while (angle < 0.0)
		{
			angle += 360.0;
		}
	while (angle > 360.0)
		{
			angle -= 360.0;
		}
	
	if (angle < 90.0)
		{
			startPoint = NSMakePoint(NSMinX(rect), NSMinY(rect));
		}
	else if (angle < 180.0)
		{
			startPoint = NSMakePoint(NSMaxX(rect), NSMinY(rect));
		}
	else if (angle < 270.0)
		{
			startPoint = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
		}
	else
		{
			startPoint = NSMakePoint(NSMinX(rect), NSMaxY(rect));
		}
	rad = M_PI * angle / 180;
	length = fabs(NSWidth(rect) * cos(rad) + NSHeight(rect) * sin(rad));
	endPoint = NSMakePoint(startPoint.x + length * cos(rad), 
						   startPoint.y + length * sin(rad));
	
	[currentContext saveGraphicsState];
	[NSBezierPath clipRect: rect];
	[self drawFromPoint: startPoint
				 toPoint: endPoint
				 options: 0];
	[currentContext restoreGraphicsState];
}

static inline CGFloat sqr(CGFloat a)
{
	return a * a;
}

static inline CGFloat euclidian_distance(NSPoint start, NSPoint end)
{
	return sqrt(sqr(end.x - start.x) + sqr(end.y - start.y));
}

- (void) drawInRect: (NSRect)rect 
relativeCenterPosition: (NSPoint)relativeCenterPoint
{
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	NSPoint startCenter;
	NSPoint endCenter;
	CGFloat endRadius;
	CGFloat distance;
	
	NSAssert(relativeCenterPoint.x >= 0.0 && relativeCenterPoint.x <= 1.0, @"NSGradient invalid relative center point");
	NSAssert(relativeCenterPoint.y >= 0.0 && relativeCenterPoint.y <= 1.0, @"NSGradient invalid relative center point");
	startCenter = NSMakePoint(NSMidX(rect), NSMidY(rect));
	endCenter = NSMakePoint(startCenter.x + rect.size.width * relativeCenterPoint.x, 
							startCenter.y + rect.size.height * relativeCenterPoint.y);
	endRadius = 0.0;
	distance = euclidian_distance(endCenter, NSMakePoint(NSMinX(rect), NSMinY(rect)));
	if (endRadius < distance)
		endRadius = distance;
	distance = euclidian_distance(endCenter, NSMakePoint(NSMaxX(rect), NSMinY(rect)));
	if (endRadius < distance)
		endRadius = distance;
	distance = euclidian_distance(endCenter, NSMakePoint(NSMinX(rect), NSMaxY(rect)));
	if (endRadius < distance)
		endRadius = distance;
	distance = euclidian_distance(endCenter, NSMakePoint(NSMaxX(rect), NSMaxY(rect)));
	if (endRadius < distance)
		endRadius = distance;
	
	[currentContext saveGraphicsState];
	[NSBezierPath clipRect: rect];
	[self drawFromCenter: startCenter
				  radius: 0.0
				toCenter: endCenter 
				  radius: endRadius
				 options: 0];
	[currentContext restoreGraphicsState];
}

- (void) getColor: (NSColor **)color
         location: (CGFloat *)location
          atIndex: (NSInteger)index
{
	NSAssert(index >= 0 && index < _numberOfColorStops, @"NSGradient invalid index");
	
	if (color)
		*color = [_colors objectAtIndex: index];
	if (location)
		*location = _locations[index];
}

- (id) initWithColors: (NSArray *)colorArray;
{
	return [self initWithColors: colorArray 
					atLocations: NULL
					 colorSpace: nil];
}

- (id) initWithColors: (NSArray *)colorArray
          atLocations: (const CGFloat *)locations
           colorSpace: (NSColorSpace *)colorSpace;
{
	if ((self = [super init]))
		{
			_numberOfColorStops = [colorArray count];
			NSAssert(_numberOfColorStops >= 2, @"NSGradient needs at least 2 locations");
			if (colorSpace == nil)
				{
					colorSpace = [[colorArray objectAtIndex: 0] colorSpace];
				}
			ASSIGN(_colorSpace, colorSpace);
			
			// FIXME: Convert all colours to colour space
			ASSIGN(_colors, colorArray);
			
			_locations = objc_malloc(sizeof(_locations[0])*_numberOfColorStops);
			if (locations)
				{
					// FIXME: Check that the locations are properly ordered
					memcpy(_locations, locations, sizeof(_locations[0]) * _numberOfColorStops);
				}
			else
				{
					NSUInteger i;
					
					// evenly spaced
					for (i = 0; i < _numberOfColorStops; i++)
						_locations[i] = (CGFloat)i / (_numberOfColorStops - 1);
				}
		}
	return self;
}

- (id) initWithColorsAndLocations: (NSColor *)color, ...
{
	va_list ap;
	NSUInteger max = 128;
	NSUInteger count = 0;
	CGFloat *locations = objc_malloc(max * sizeof(*locations));
	NSMutableArray *colorArray = [[NSMutableArray alloc] init];
	
	va_start(ap, color);
	while (color != nil)
		{
			if (max <= count)
				{
					max *= 2;
					locations = (CGFloat*)objc_realloc(locations, max * sizeof(*locations));
				}
			[colorArray addObject: color];
			// gcc insists on using double here
			locations[count++] = (CGFloat)va_arg(ap, double);
			
			color = va_arg(ap, id);
		}
	va_end(ap);
	
	self = [self initWithColors: colorArray
					atLocations: locations
					 colorSpace: nil];
	
	[colorArray release];
	objc_free(locations);
	return self;
}

- (id) initWithStartingColor: (NSColor *)startColor endingColor: (NSColor *)endColor
{
	return [self initWithColors: [NSArray arrayWithObjects: startColor, endColor, nil]];
}

- (void) dealloc
{
	[_colorSpace release];
	[_colors release];
	objc_free(_locations);
	[super dealloc];
}

- (NSColor *) interpolatedColorAtLocation: (CGFloat)location
{
	NSUInteger i;
	
	if (location <= _locations[0])
		{
			return [_colors objectAtIndex: 0];
		}
	
	if (location >= _locations[_numberOfColorStops - 1])
		{
			return [_colors objectAtIndex: _numberOfColorStops - 1];
		}
	
	for (i = 1; i < _numberOfColorStops; i++)
		{
			if (location <= _locations[i])
				{
					NSColor *c1 = [_colors objectAtIndex: i - 1];
					NSColor *c2 = [_colors objectAtIndex: i];
					CGFloat fraction = (_locations[i] - location) / (_locations[i] - _locations[i - 1]);
					
					// FIXME: Works only for RGB colours and does not respect the colour space
					return [c1 blendedColorWithFraction: fraction
												ofColor: c2];
				}
		}
	
	return nil;
}

- (NSInteger) numberOfColorStops
{
	return _numberOfColorStops;
}

/*
 * Copying
 */
- (id) copyWithZone: (NSZone*)zone
{
	NSGradient *g = (NSGradient*)NSCopyObject(self, 0, zone);
	
	[g->_colorSpace retain];
	[g->_colors retain];
	g->_locations = objc_malloc(sizeof(g->_locations[0]) * _numberOfColorStops);
	memcpy(g->_locations, _locations, sizeof(g->_locations[0]) * _numberOfColorStops);
	
	return g;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
	if ([aCoder allowsKeyedCoding])
		{
		}
	else
		{
		}
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
	if ([aDecoder allowsKeyedCoding])
		{
		}
	else
		{
		}
	return self;
}

@end
