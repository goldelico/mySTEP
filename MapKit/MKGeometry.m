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
	double l = coord.latitude * (M_PI / 180.0);		// latitude is limited to approx. +/- 85 deg
	double y = 1.0 + log( tan(l) + 1.0 / cos(l)) / M_PI;
	double x = (180.0 + coord.longitude) / 360.0;
	return MKMapPointMake(x*MKMapWidth, y*0.5*MKMapHeight);
}

// FIXME: this may rotate the map by 180 degrees?

CLLocationCoordinate2D MKCoordinateForMapPoint(MKMapPoint mapPoint)
{
	double x = mapPoint.x / MKMapWidth;			// 0 ... MapWidth
	double y = mapPoint.y / MKMapHeight;		// 0 ... MapHeight
	CLLocationCoordinate2D loc;
	double n;
	x=remainder(x, 1.0);
	y=2.0 * remainder(y, 1.0);
	loc.longitude = x * 360.0 - 180.0;	// -180 ... +180
	n = (2.0 * M_PI) * y - M_PI;	// -PI ... +PI
	loc.latitude = (180.0 / M_PI) * atan(0.5 * (exp(-n) - exp(n)));
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
	// compare remainder with MKMapWidth/Height???
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

MKMapRect MKMapRectOffset(MKMapRect rect, double dx, double dy)
{
	return MKMapRectMake(rect.origin.x+dx, rect.origin.y+dy, rect.size.width, rect.size.height);
}

BOOL MKMapRectEqualToRect(MKMapRect r1, MKMapRect r2)
{
	return MKMapPointEqualToPoint(r1.origin, r2.origin) && MKMapSizeEqualToSize(r1.size, r2.size);
}

BOOL MKMapRectIsEmpty(MKMapRect rect) { return rect.size.width == 0.0 || rect.size.height == 0.0; }	// no area
// FIXME: A rectangle is considered null if its origin point contains an invalid or infinite value.
BOOL MKMapRectIsNull(MKMapRect rect) { return rect.origin.x <= 0.0 || rect.origin.x > MKMapWidth || rect.origin.y <= 0.0 || rect.origin.y > MKMapHeight; }

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

BOOL MKMapRectSpans180thMeridian(MKMapRect rect)
{
	return MKMapRectGetMinX(rect) < 0 || MKMapRectGetMaxX(rect) > MKMapWidth;
}

NSString *MKStringFromMapPoint(MKMapPoint point) { return [NSString stringWithFormat:@"{ %lf, %lf }", point.x, point.y]; }
NSString *MKStringFromMapRect(MKMapRect rect) { return [NSString stringWithFormat:@"{ %@, %@ }", MKStringFromMapPoint(rect.origin), MKStringFromMapSize(rect.size)]; }
NSString *MKStringFromMapSize(MKMapSize size) { return [NSString stringWithFormat:@"{ %lf, %lf }", size.width, size.height]; }

#if TODO

double MKMapPointsPerMeterAtLatitude(CLLocationDegrees lat)
{
	// aus MKMapWidth/Height und cos(lat) berechnen
}

BOOL MKMapRectContainsPoint(MKMapRect rect, MKMapPoint point);
BOOL MKMapRectContainsRect(MKMapRect r1, MKMapRect r2);
void MKMapRectDivide(MKMapRect rect, MKMapRect *slice, MKMapRect *remainder, double amount, CGRectEdge edge);
MKMapRect MKMapRectIntersection(MKMapRect r1, MKMapRect r2);
BOOL MKMapRectIntersectsRect(MKMapRect r1, MKMapRect r2);
MKMapRect MKMapRectRemainder(MKMapRect rect);
MKMapRect MKMapRectUnion(MKMapRect r1, MKMapRect r2);

CLLocationDistance MKMetersBetweenMapPoints(MKMapPoint a, MKMapPoint b)	// convert to CLLocation and ask CL for distance (?)
{
	// annähern oder exakt?
	// Näherung wäre rechtwinkliges Dreieck
	// also ca.
	// horiz dist: avg(MKMetersPerMapPointAtLatitude(lat(a)), same(b)) * fabs(b.origin.x - a.origin.x)
	// vert dist:  meters(MKMapHeight * fabs(b.origin.y - a.origin.y))
	// besser: in CLLocationCoordinate2D umrechnen
	// und Großkreis ansetzen
}

CLLocationDistance MKMetersPerMapPointAtLatitude(CLLocationDegrees latitude)
{
	// aus MKMapWidth/Height und cos(lat) berechnen		
}

#endif

// EOF
