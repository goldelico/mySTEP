//
//  MKGeometry.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKGeometry.h>

/* Mercator conversion
 *
 * MapPoints are on the Mercator map in some internal coordinate system
 *   we use points (1/72 inch) so that scale factor 1 makes real world map
 *   range is 0 .. 20000km on latitude and 0 .. 40000km on longitude
 *   MKMapView knows this when fetching, scaling and drawing tiles
 *
 * CLLocationCoordinate2D are on earth surface (-90 (south) .. +90 (north) / -180 (west) .. 180 (east) degrees)
 */

MKMapPoint MKMapPointForCoordinate(CLLocationCoordinate2D coord)
{ // positive coords go east (!) and north
#define mpwidth 1	// express 20000km in Points
#define mpheight 1	// express 40000km in Points
	double l = coord.latitude * (M_PI / 180.0);		// latitude is limited to approx. +/- 85 deg
	double y = 1.0 - log( tan(l) + 1.0 / cos(l)) / M_PI;
	double x = (180.0 - coord.longitude) / 360.0;
	return MKMapPointMake(x*mpwidth, y*0.5*mpheight);
}

CLLocationCoordinate2D MKCoordinateForMapPoint(MKMapPoint mapPoint)
{
	double x = 2.0 * mapPoint.x / mpwidth;				// 0 ... +1
	double y = 2.0 * (mapPoint.y / mpheight - 1.0);		// 0 ... +1
	CLLocationCoordinate2D loc;
	double n;
	x=remainder(x, 1.0);
	y=remainder(y, 1.0);
	loc.longitude = (180.0 - x * 360.0);	// +180 ... -180
	n = M_PI - (2.0 * M_PI) * y;	// +PI ... -PI
	loc.latitude = (180.0 / M_PI) * atan(0.5 * (exp(n) - exp(-n)));
	return loc;
}

MKCoordinateRegion MKCoordinateRegionForMapRect(MKMapRect rect)
{
	return MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(rect), MKMapRectGetMidY(rect))), 0.0, 0.0);
}

MKCoordinateRegion MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D center,
													  CLLocationDistance lat,
													  CLLocationDistance lng)
{
	return MKCoordinateRegionMake(center, MKCoordinateSpanMake(lat, lng));
}

BOOL MKMapPointEqualToPoint(MKMapPoint p1, MKMapPoint p2)
{
	return p1.x == p2.x && p1.y == p2.y;
}

MKMapPoint MKMapPointMake(double x, double y)
{
	return (MKMapPoint) { x, y };
}

double MKMapRectGetHeight(MKMapRect rect) { return rect.size.height; }
double MKMapRectGetMaxX(MKMapRect rect) { return rect.origin.x+rect.size.width; }
double MKMapRectGetMaxY(MKMapRect rect) { return rect.origin.y+rect.size.height; }
double MKMapRectGetMidX(MKMapRect rect) { return rect.origin.x+0.5*rect.size.width; }
double MKMapRectGetMidY(MKMapRect rect) { return rect.origin.y+0.5*rect.size.height; }
double MKMapRectGetMinX(MKMapRect rect) { return rect.origin.x; }
double MKMapRectGetMinY(MKMapRect rect) { return rect.origin.y; }
double MKMapRectGetWidth(MKMapRect rect) { return rect.size.width; }

MKMapRect MKMapRectInset(MKMapRect rect, double dx, double dy)
{
	return MKMapRectMake(rect.origin.x+0.5*dx, rect.origin.y+0.5*dy, rect.size.width-dx, rect.size.height-dy);
}

BOOL MKMapRectEqualToRect(MKMapRect r1, MKMapRect r2)
{
	return MKMapPointEqualToPoint(r1.origin, r2.origin) && MKMapSizeEqualToSize(r1.size, r2.size);
}

BOOL MKMapRectIsEmpty(MKMapRect rect) { return rect.size.width == 0.0 || rect.size.height == 0.0; }	// no area
// FIXME: A rectangle is considered null if its origin point contains an invalid or infinite value.
BOOL MKMapRectIsNull(MKMapRect rect) { return rect.size.width == 0.0 || rect.size.height == 0.0; }

MKMapRect MKMapRectMake(double x, double y, double w, double h)
{
	return (MKMapRect) { { x, y }, { w, h } };
}

BOOL MKMapSizeEqualToSize(MKMapSize r1, MKMapSize r2)
{
	return r1.width == r2.width && r1.height == r2.height;
}

MKMapSize MKMapSizeMake(double w, double h)
{
	return (MKMapSize) { w, h };
}

NSString *MKStringFromMapPoint(MKMapPoint point) { return [NSString stringWithFormat:@"{ %lf, %lf }", point.x, point.y]; }
NSString *MKStringFromMapRect(MKMapRect rect) { return [NSString stringWithFormat:@"{ %@, %@ }", MKStringFromMapPoint(rect.origin), MKStringFromMapSize(rect.size)]; }
NSString *MKStringFromMapSize(MKMapSize size) { return [NSString stringWithFormat:@"{ %lf, %lf }", size.width, size.height]; }

#if TODO

double MKMapPointsPerMeterAtLatitude(CLLocationDegrees lat);
BOOL MKMapRectContainsPoint(MKMapRect rect, MKMapPoint point);
BOOL MKMapRectContainsRect(MKMapRect r1, MKMapRect r2);
void MKMapRectDivide(MKMapRect rect, MKMapRect *slice, MKMapRect *remainder, double amount, CGRectEdge edge);
MKMapRect MKMapRectIntersection(MKMapRect r1, MKMapRect r2);
BOOL MKMapRectIntersectsRect(MKMapRect r1, MKMapRect r2);
MKMapRect MKMapRectOffset(MKMapRect rect, double dx, double dy);
MKMapRect MKMapRectRemainder(MKMapRect rect);
BOOL MKMapRectSpans180thMeridian(MKMapRect rect);
MKMapRect MKMapRectUnion(MKMapRect r1, MKMapRect r2);
CLLocationDistance MKMetersBetweenMapPoints(MKMapPoint a, MKMapPoint b);
CLLocationDistance MKMetersPerMapPointAtLatitude(CLLocationDegrees latitude);

#endif

// EOF
