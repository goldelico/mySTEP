//
//  NSAffineTransform.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <Foundation/NSString.h>

#import <AppKit/NSGraphics.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSBezierPath.h>

#import "NSBackendPrivate.h"

@implementation NSAffineTransform (AppKit)

- (void) concat	
{
	[[NSGraphicsContext currentContext] _concatCTM:self];
}

- (void) set
{
	[[NSGraphicsContext currentContext] _setCTM:self];
}

- (NSBezierPath *) transformBezierPath:(NSBezierPath *) aPath;
{
	NSBezierPath *p=[aPath copy];
	[p transformUsingAffineTransform:self];
	return [p autorelease];
}

- (NSRect) _boundingRectForTransformedRect:(NSRect) box
{ // transform all four corners and find bounding box
	NSPoint p[4]={ [self transformPoint:NSMakePoint(NSMinX(box), NSMinY(box))], 
				   [self transformPoint:NSMakePoint(NSMinX(box), NSMaxY(box))],
				   [self transformPoint:NSMakePoint(NSMaxX(box), NSMaxY(box))],
				   [self transformPoint:NSMakePoint(NSMaxX(box), NSMinY(box))] };
	NSPoint min=p[0], max=p[0];
	int i;
	for(i=1; i<4; i++)
		{ // a good compiler tries to unroll this loop
		if(p[i].x < min.x) min.x=p[i].x;
		if(p[i].x > max.x) max.x=p[i].x;
		if(p[i].y < min.y) min.y=p[i].y;
		if(p[i].y > max.y) max.y=p[i].y;
		}
	return NSMakeRect(min.x, min.y, max.x-min.x, max.y-min.y);	// get scaled/rotated bounding rect
}
	
@end /* NSAffineTransform */

@interface NSPSMatrix : NSObject
@end

@implementation NSPSMatrix	/* used by drawing system (unarchived from e.g. NSProgressIndicator) */

- (void) encodeWithCoder:(NSCoder *) coder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder
{
	return self;
}

@end

