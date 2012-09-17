//
//  MKOverlayView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MapKit.h>

#ifndef NIMP
#define NIMP (nil)
#endif

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
	//	[self drawMapRect:<#(MKMapRect)rect#> zoomScale:1.0 inContext:[NSGraphicsContext currentContext]];
}

- (BOOL) canDrawMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale;
{
	return NO;
}

- (void) drawMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale inContext:(CGContextRef) context;
{
	
}

- (id) initWithOverlay:(id <MKOverlay>) overlay;
{
	if((self=[super initWithFrame:NSZeroRect]))
		{
		_overlay=[overlay retain];
		}
	return self;
}

- (void) dealloc;
{
	[_overlay release];
	[super dealloc];
}

- (MKMapPoint) mapPointForPoint:(CGPoint) point;
{
	return [(MKMapView *) [self superview] _mapPointForPoint:point];
}

- (MKMapRect) mapRectForRect:(CGRect) rect;
{
	return [(MKMapView *) [self superview] _mapRectForRect:rect];
}

- (CGPoint) pointForMapPoint:(MKMapPoint) point;
{
	return [(MKMapView *) [self superview] _pointForMapPoint:point];
}

- (CGRect) rectForMapRect:(MKMapRect) rect;
{
	return [(MKMapView *) [self superview] _rectForMapRect:rect];
}

- (id <MKOverlay>) overlay; { return _overlay; }

- (void) setNeedsDisplayInMapRect:(MKMapRect) rect;
{
//	[self setNeedsDisplayInRect:[self rectForMapRect:rect]];
}

- (void) setNeedsDisplayInMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale;
{
	// adjust for scale
//	[self setNeedsDisplayInRect:[self rectForMapRect:rect]];
}

@end

@implementation MKOverlayPathView	/* : MKOverlayView */

- (void) applyFillPropertiesToContext:(CGContextRef) context atZoomScale:(MKZoomScale) zoomScale;
{
	NIMP;
}

- (void) applyStrokePropertiesToContext:(CGContextRef) context atZoomScale:(MKZoomScale) zoomScale;
{
	NIMP;
}

- (void) createPath;
{
	NIMP;
}

- (void) fillPath:(CGPathRef) p inContext:(CGContextRef) context;
{
	[NSGraphicsContext setCurrentContext:context];
	[p fill];
}

- (void) strokePath:(CGPathRef) p inContext:(CGContextRef) context;
{
	[NSGraphicsContext setCurrentContext:context];
	[p stroke];
}

- (void) invalidatePath;
{
	NIMP;
}

- (UIColor *) fillColor; { return fillColor; }
- (CGLineCap) lineCap; { return lineCap; }
- (NSArray *) lineDashPattern; { return lineDashPattern; }
- (CGFloat) lineDashPhase; { return lineDashPhase; }
- (CGLineJoin) lineJoin; { return lineJoin; }
- (CGFloat) lineWidth; { return lineWidth; }
- (CGFloat) miterLimit; { return miterLimit; }
- (CGPathRef) path; { return path; }
- (UIColor *) strokeColor; { return strokeColor; }

- (void) setFillColor:(UIColor *) color; { [fillColor autorelease]; fillColor=[color retain]; }
- (void) setLineCap:(CGLineCap) cap; { lineCap=cap; }
- (void) setLineDashPattern:(NSArray *) pattern; { [lineDashPattern autorelease]; lineDashPattern=[pattern copy]; }
- (void) setLineDashPhase:(CGFloat) phase; { lineDashPhase=phase; }
- (void) setLineJoin:(CGLineJoin) join; { lineJoin=join; }
- (void) setLineWidth:(CGFloat) width; { lineWidth=width; }
- (void) setMiterLimit:(CGFloat) limit; { miterLimit=limit; }
- (void) setPath:(CGPathRef) path; { NIMP; }
- (void) setStrokeColor:(UIColor *) color; { [strokeColor autorelease]; strokeColor=[color retain]; }

@end

@implementation MKCircleView	/* : MKOverlayPathView */

- (id) initWithCircle:(MKCircle *) circle;
{
	return [super initWithOverlay:circle];
}

- (MKCircle *) circle;
{
	return (MKCircle *) [super overlay];
}

@end

@implementation MKPolygonView	/* : MKOverlayPathView */

- (id) initWithPolygon:(MKPolygon *) polygon;
{
	return [super initWithOverlay:polygon];
}

- (MKPolygon *) polygon;
{
	return (MKPolygon *) [super overlay];
}

@end

@implementation MKPolylineView	/* : MKOverlayPathView */

- (id) initWithPolyline:(MKPolyline *) polyline;
{
	return [super initWithOverlay:polyline];
}

- (MKPolyline *) polyline;
{
	return (MKPolyline *) [super overlay];
}

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

- (id) initWithCenterCoordinate:(CLLocationCoordinate2D) coord radius:(CLLocationDistance) rad;
{
	if((self=[super init]))
		{
		coordinate=coord;
		radius=rad;
		}
	return self;
}

+ (MKCircle *) circleWithCenterCoordinate:(CLLocationCoordinate2D) coord radius:(CLLocationDistance) rad;
{
	return [[[self alloc] initWithCenterCoordinate:coord radius:rad] autorelease];
}

+ (MKCircle *) circleWithMapRect:(MKMapRect) mapRect;	// longest side determines the radius
{
	CLLocationCoordinate2D loc;
	loc.longitude=MKMapRectGetMidX(mapRect);
	loc.latitude=MKMapRectGetMidY(mapRect);
	return [self circleWithCenterCoordinate:loc radius:0.5*MAX(MKMapRectGetWidth(mapRect), MKMapRectGetHeight(mapRect))];
}

- (MKMapRect) boundingMapRect;
{ // CHEKME: is this a stored or a calculated property?
	return MKMapRectMake(coordinate.latitude-radius, coordinate.longitude-radius, 2.0*radius, 2.0*radius);
}

- (CLLocationCoordinate2D) coordinate;
{
	return coordinate;
}

- (CLLocationDistance) radius;
{
	return radius;	
}

- (BOOL) intersectsMapRect:(MKMapRect)rect
{
	return MKMapRectIntersectsRect([self boundingMapRect], rect);
}

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
	unsigned int i;
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

/* MKAnnotation protocol */

- (CLLocationCoordinate2D) coordinate;
{
	CLLocationCoordinate2D center = { 0, 0 };
	unsigned int i;
	for(i=0; i<pointCount; i++)
		{
		CLLocationCoordinate2D pos=MKCoordinateForMapPoint(points[i]);
		center.latitude += pos.latitude;
		center.longitude += pos.longitude;
		}
	if(pointCount > 1)
		{ // average
		center.latitude /= pointCount;
		center.longitude /= pointCount;
		}
	return center;
}

- (void) setCoordinate:(CLLocationCoordinate2D) pos
{
	CLLocationCoordinate2D delta = [self coordinate];
	unsigned int i;
	delta.latitude = pos.latitude - delta.latitude;
	delta.longitude = pos.longitude - delta.longitude;
	if(delta.longitude == 0.0 && delta.latitude == 0.0)
		return;
	for(i=0; i<pointCount; i++)
		{
		CLLocationCoordinate2D pos=MKCoordinateForMapPoint(points[i]);
		pos.latitude += delta.latitude;
		pos.longitude += delta.longitude;
		points[i]=MKMapPointForCoordinate(pos);
		}
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

- (BOOL) intersectsMapRect:(MKMapRect)rect
{
	return MKMapRectIntersectsRect([self boundingMapRect], rect);
}

- (MKMapRect) boundingMapRect;
{
	MKMapRect bounds={ 0, 0, 0, 0 };
	unsigned int i;
	for(i=0; i<pointCount; i++)
		bounds=MKMapRectUnion(bounds, (MKMapRect) { points[i], { 0, 0 } } );	// enlarge by all points
	return bounds;
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

- (BOOL) intersectsMapRect:(MKMapRect)rect
{
	return MKMapRectIntersectsRect([self boundingMapRect], rect);
}

- (MKMapRect) boundingMapRect;
{
	MKMapRect bounds={ 0, 0, 0, 0 };
	unsigned int i;
	for(i=0; i<pointCount; i++)
		bounds=MKMapRectUnion(bounds, (MKMapRect) { points[i], { 0, 0 } } );	// enlarge by all points
	return bounds;
}

@end
