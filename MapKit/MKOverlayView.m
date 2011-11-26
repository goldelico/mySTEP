//
//  MKOverlayView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "MKOverlayView.h"
#import "MKShape.h"
#import "MKMultiPoint.h"
#import "MKPolyline.h"
#import "MKPolygon.h"


@implementation MKOverlayView

- (NSView *) hitTest:(NSPoint)aPoint
{
	return nil;	// always fail
}

- (void) drawRect:(NSRect) rect
{
#if 1
	[[NSColor greenColor] set];
	NSRectFill(rect);
#endif
}

@end

@implementation MKOverlayPathView

@end

@implementation MKCircleView

@end

@implementation MKPolygonView

@end

@implementation MKPolylineView

@end

@implementation MKShape

- (void) dealloc
{
	[subtitle release];
	[title release];
	[super dealloc];
}

- (void) setSubtitle:(NSString *) s;
{
	[subtitle autorelease];
	subtitle=[s copy];
}

- (void) setTitle:(NSString *) t;
{
	[title autorelease];
	title=[t copy];	
}

- (NSString *) subtitle;
{
	return subtitle;
}

- (NSString *) title;
{
	return title;
}

- (CLLocationCoordinate2D) coordinate;
{
	return (CLLocationCoordinate2D) { 0.0, 0.0 };
}

- (void) setCoordinate:(CLLocationCoordinate2D) pos;
{ // changed by user
}

@end

@implementation MKCircle

@end

@implementation MKMultiPoint

- (void) dealloc
{
	if(points)
		free(points);
	[super dealloc];
}

- (NSUInteger) pointCount;
{
	return pointCount;
}

- (MKMapPoint *) points;
{
	return points;
}

- (void) getCoordinates:(CLLocationCoordinate2D *) coords range:(NSRange) range;
{
	unsigned int i=0;
	if(NSMaxRange(range) > pointCount)
		[NSException raise:NSInvalidArgumentException format:@"invalid coordinate range"];		
	for(i=0; i<range.length; i++)
		coords[i]=MKCoordinateForMapPoint(points[range.location+i]);
}

- (void) addPoint:(MKMapPoint) point;
{
	if(pointCount >= capacity)
		points=realloc(points, sizeof(*points) * (capacity=3*capacity+5));	// increase
	if(!points)
		[NSException raise:NSInvalidArgumentException format:@"out of memory"];		
	points[pointCount++]=point;	// add point
}

- (void) addCoordinate:(CLLocationCoordinate2D) coord;
{
	[self addPoint:MKMapPointForCoordinate(coord)];
}

- (void) removePointAtIndex:(unsigned int) idx;
{
	if(idx >= pointCount)
		[NSException raise:NSInvalidArgumentException format:@"index %u out of range 0..%u", idx, pointCount];
	// memcpy as needed
}

@end

@implementation MKPolyline

+ (MKPolyline *) polylineWithCoordinates:(CLLocationCoordinate2D *) coords count:(NSUInteger) count;
{
	MKPolygon *p=[super new];
	while(count-- > 0)
		[p addCoordinate:*coords++];
	return [p autorelease];
}

+ (MKPolyline *) polylineWithPoints:(MKMapPoint *) points count:(NSUInteger) count;
{
	MKPolygon *p=[super new];
	while(count-- > 0)
		[p addPoint:*points++];
	return [p autorelease];	
}

@end

@implementation MKPolygon

- (void) dealloc
{
	[interiorPolygons release];
	[super dealloc];
}

- (NSArray *) interiorPolygons;
{
	return interiorPolygons;
}

+ (MKPolygon *) polygonWithCoordinates:(CLLocationCoordinate2D *) coords count:(NSUInteger) count;
{
	MKPolygon *p=[super new];
	while(count-- > 0)
		[p addCoordinate:*coords++];
	return [p autorelease];
}

+ (MKPolygon *) polygonWithCoordinates:(CLLocationCoordinate2D *) coords count:(NSUInteger) count interiorPolygons:(NSArray *) ip;
{
	MKPolygon *p=[super new];
	p->interiorPolygons=[ip copy];
	while(count-- > 0)
		[p addCoordinate:*coords++];
	return [p autorelease];	
}

+ (MKPolygon *) polygonWithPoints:(MKMapPoint *) points count:(NSUInteger) count;
{
	MKPolygon *p=[super new];
	while(count-- > 0)
		[p addPoint:*points++];
	return [p autorelease];	
}

+ (MKPolygon *) polygonWithPoints:(MKMapPoint *) points count:(NSUInteger) count interiorPolygons:(NSArray *) ip;
{
	MKPolygon *p=[super new];
	p->interiorPolygons=[ip copy];
	while(count-- > 0)
		[p addPoint:*points++];
	return [p autorelease];	
}

@end
