/* 
   NSGeometry.m

   Interface for NSGeometry routines for mySTEP

   Copyright (C) 1995 Free Software Foundation, Inc.
   
   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	1995
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSScanner.h>

NSPoint NSZeroPoint;  						// A zero point
NSRect  NSZeroRect;    						// A zero origin rectangle
NSSize  NSZeroSize;    						// A zero size rectangle

#ifndef NSMakePoint
NSPoint	
NSMakePoint(float x, float y)					{ return (NSPoint){x, y}; }

NSSize 
NSMakeSize(float w, float h)					{ return (NSSize){w, h}; }

NSRect 
NSMakeRect(float x, float y, float w, float h)	{ return (NSRect){x, y, w, h};}

#endif

NSRect 	
NSOffsetRect(NSRect aRect, float dX, float dY)
{
	return (NSRect){{NSMinX(aRect) + dX, NSMinY(aRect) + dY}, aRect.size};
}

NSRect 	
NSInsetRect(NSRect aRect, float dX, float dY)
{
	return (NSRect){{NSMinX(aRect) + dX, NSMinY(aRect) + dY}, 
					{NSWidth(aRect) - (2 * dX), NSHeight(aRect) - (2 * dY)}};
}

void 	
NSDivideRect(NSRect r,
             NSRect *slice,
             NSRect *remainder,
             float amount,
             NSRectEdge edge)
{
	if (NSIsEmptyRect(r))
		{
		*slice = NSZeroRect;
		*remainder = NSZeroRect;

		return;
		}

	switch (edge)
		{
		case NSMinXEdge:
			if (amount > r.size.width)
				{
				*slice = r;
				*remainder = (NSRect){{NSMaxX(r), NSMinY(r)}, {0, NSHeight(r)}};
				}
			else
				{
				*slice = (NSRect){{NSMinX(r), NSMinY(r)}, {amount, NSHeight(r)}};
				*remainder = (NSRect){{NSMaxX(*slice), NSMinY(r)}, 
					{NSMaxX(r) - NSMaxX(*slice), NSHeight(r)}};
				}
			break;

		case NSMinYEdge:
			if (amount > r.size.height)
				{
				*slice = r;
				*remainder = (NSRect){{r.origin.x, NSMaxY(r)}, {r.size.width, 0}};
				}
			else
				{
				*slice = (NSRect){r.origin,{r.size.width, amount}};
				*remainder = (NSRect){{r.origin.x, NSMaxY(*slice)}, 
					{r.size.width, NSMaxY(r) - NSMaxY(*slice)}};
				}
			break;

		case NSMaxXEdge:
			if (amount > r.size.width)
				{
				*slice = r;
				*remainder = (NSRect){r.origin, {0, r.size.height}};
				}
			else
				{
				*slice = (NSRect){{NSMaxX(r) - amount, r.origin.y},
					{amount, r.size.height}};
				*remainder = (NSRect){r.origin,{NSMinX(*slice) - NSMinX(r),
									  r.size.height}};
				}
			break;

		case NSMaxYEdge:
			if (amount > r.size.height)
				{
				*slice = r;
				*remainder = (NSRect){r.origin, {r.size.width, 0}};
				}
			else
				{
				*slice = (NSRect){{r.origin.x, NSMaxY(r) - amount}, 
					{r.size.width, amount}};
				*remainder = (NSRect){r.origin, {r.size.width, 
									  NSMinY(*slice) - r.origin.y}};
				}

		default:
			break;
		}
}

NSRect 	
NSIntegralRect(NSRect aRect)
{
NSRect rect;

	if (NSIsEmptyRect(aRect))
		return NSZeroRect;
	
	rect.origin.x = floor(aRect.origin.x);
	rect.origin.y = floor(aRect.origin.y);
	rect.size.width = ceil(aRect.size.width);
	rect.size.height = ceil(aRect.size.height);

	return rect;
}

NSRect 	
NSUnionRect(NSRect aRect, NSRect bRect)
{
NSRect rect;

	if (NSIsEmptyRect(aRect))
		return (NSIsEmptyRect(bRect)) ? NSZeroRect : bRect;

	if (NSIsEmptyRect(bRect))
		return aRect;
	
	rect = (NSRect){{MIN(NSMinX(aRect), NSMinX(bRect)), 
		MIN(NSMinY(aRect), NSMinY(bRect))}, {0, 0}};

	return (NSRect){{NSMinX(rect),
		NSMinY(rect)},
		{MAX(NSMaxX(aRect), NSMaxX(bRect)) - NSMinX(rect),
			MAX(NSMaxY(aRect), NSMaxY(bRect)) - NSMinY(rect)}};
}

BOOL     
NSIntersectsRect(NSRect aRect, NSRect bRect)
{													// Intersection at a line
	return (NSMaxX(aRect) <= NSMinX(bRect)			// or a point doesn't count
			|| NSMaxX(bRect) <= NSMinX(aRect)
			|| NSMaxY(aRect) <= NSMinY(bRect)
			|| NSMaxY(bRect) <= NSMinY(aRect)) ? NO : YES;
}

NSRect   
NSIntersectionRect (NSRect aRect, NSRect bRect)
{
NSRect rect;

	if (!NSIntersectsRect(aRect, bRect))
    	return NSZeroRect;

	if (NSMinX(aRect) <= NSMinX(bRect))
		{
		rect.size.width = MIN(NSMaxX(aRect), NSMaxX(bRect)) - NSMinX(bRect);
		rect.origin.x = NSMinX(bRect);
		}
	else
		{
		rect.size.width = MIN(NSMaxX(aRect), NSMaxX(bRect)) - NSMinX(aRect);
		rect.origin.x = NSMinX(aRect);
		}

	if (NSMinY(aRect) <= NSMinY(bRect))
		{
		rect.size.height = MIN(NSMaxY(aRect), NSMaxY(bRect)) - NSMinY(bRect);
		rect.origin.y = NSMinY(bRect);
		}
	else
		{
		rect.size.height = MIN(NSMaxY(aRect), NSMaxY(bRect)) - NSMinY(aRect);
		rect.origin.y = NSMinY(aRect);
		}

	return rect;
}

BOOL 	
NSEqualRects(NSRect aRect, NSRect bRect)
{
	return ((NSMinX(aRect) == NSMinX(bRect)) 
			&& (NSMinY(aRect) == NSMinY(bRect)) 
			&& (NSWidth(aRect) == NSWidth(bRect)) 
			&& (NSHeight(aRect) == NSHeight(bRect))) ? YES : NO;
}

BOOL 	
NSEqualSizes(NSSize aSize, NSSize bSize)
{
	return ((aSize.width == bSize.width) 
			&& (aSize.height == bSize.height)) ? YES : NO;
}

BOOL 	
NSEqualPoints(NSPoint aPoint, NSPoint bPoint)
{
	return ((aPoint.x == bPoint.x) && (aPoint.y == bPoint.y)) ? YES : NO;
}

BOOL 	
NSIsEmptyRect(NSRect aRect)
{
	return ((NSWidth(aRect) > 0) && (NSHeight(aRect) > 0)) ? NO : YES;
}

BOOL 	
NSMouseInRect(NSPoint aPoint, NSRect aRect, BOOL flipped)
{
	if (flipped)
		return ((aPoint.x >= NSMinX(aRect))
				&& (aPoint.y >= NSMinY(aRect))
				&& (aPoint.x < NSMaxX(aRect))
				&& (aPoint.y < NSMaxY(aRect))) ? YES : NO;

	return ((aPoint.x >= NSMinX(aRect))
			&& (aPoint.y > NSMinY(aRect))
			&& (aPoint.x < NSMaxX(aRect))
			&& (aPoint.y <= NSMaxY(aRect))) ? YES : NO;
}

BOOL 	
NSPointInRect(NSPoint aPoint, NSRect aRect)
{
	return NSMouseInRect(aPoint, aRect, YES);
}

BOOL 	
NSContainsRect(NSRect aRect, NSRect bRect)
{
	return (!NSIsEmptyRect(bRect)	// b not empty
			&& (NSMinX(aRect) <= NSMinX(bRect))	// and b does not extend beyond a in any direction
			&& (NSMinY(aRect) <= NSMinY(bRect))
			&& (NSMaxX(aRect) >= NSMaxX(bRect))
			&& (NSMaxY(aRect) >= NSMaxY(bRect))) ? YES : NO;
}

NSString *
NSStringFromPoint(NSPoint aPoint)
{
	return [NSString stringWithFormat:@"{%g, %g}", 
										aPoint.x, aPoint.y];
}

NSString *
NSStringFromRect(NSRect aRect)
{
	return [NSString stringWithFormat:
						@"{{%g, %g}, {%g, %g}}",
						NSMinX(aRect), NSMinY(aRect), 
						NSWidth(aRect), NSHeight(aRect)];
}

NSString *
NSStringFromSize(NSSize aSize)
{
	return [NSString stringWithFormat:@"{%g, %g}",
					 					aSize.width, aSize.height];
}

NSPoint	NSPointFromString(NSString *string)
{ // { x, y }
	NSScanner *scanner = [NSScanner scannerWithString:string];
	NSPoint point;
	if([scanner scanString:@"{" intoString:NULL] && [scanner scanFloat:&point.x] && [scanner scanString:@"," intoString:NULL] && [scanner scanFloat:&point.y])
		return point;
	return NSZeroPoint;
}

NSSize NSSizeFromString(NSString *string)
{ // { width, height }
	NSScanner *scanner = [NSScanner scannerWithString:string];
	NSSize size;  
	if([scanner scanString:@"{" intoString:NULL] && [scanner scanFloat:&size.width] && [scanner scanString:@"," intoString:NULL] && [scanner scanFloat:&size.height])
		return size;
	return NSZeroSize;
}

NSRect NSRectFromString(NSString *string)
{ // { { x, y }, { width, height } }
	NSScanner *scanner = [NSScanner scannerWithString:string];
	NSRect rect;
	if ([scanner scanString:@"{" intoString:NULL])
		{
		if([scanner scanString:@"{" intoString:NULL] && [scanner scanFloat:&rect.origin.x] && [scanner scanString:@"," intoString:NULL] && [scanner scanFloat:&rect.origin.y])
			{
			[scanner scanString:@"}" intoString:NULL];
			[scanner scanString:@"," intoString:NULL];
			if([scanner scanString:@"{" intoString:NULL] && [scanner scanFloat:&rect.size.width] && [scanner scanString:@"," intoString:NULL] && [scanner scanFloat:&rect.size.height])
				return rect;
			}
		}
	return NSZeroRect;	// not valid
}
