//
//  MKGeometry.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
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
 *   since MapPoints are some internal coordinate system we defined them to
 *   start at the southwest corner (-180deg) with (0,0) and span towards north east (+180)
 *
 * CLLocationCoordinate2D are on earth surface
 *   (-90 (south) .. +90 (north) / -180 (west) .. 180 (east) degrees)
 */

#define POINTS_PER_METER (72/0.0254)
#define EQUATOR_RADIUS	6378127.0	// WGS84 in meters
#define POLE_RADIUS 6356752.314
#define MKMapWidth (2*M_PI*EQUATOR_RADIUS*POINTS_PER_METER)	// total width of map expressed in typographic points
#define MKMapHeight (M_PI*POLE_RADIUS*POINTS_PER_METER)		// total height of map

// Mercator map projection:

MKMapPoint MKMapPointForCoordinate(CLLocationCoordinate2D coord)
{ // positive coords go east (!) and north
	double l = coord.latitude * (M_PI / 180.0);		// latitude is limited to approx. +/- 85 deg
	double n = log( tan(l) + 1.0 / cos(l));
	double y = 0.5 + n / (2.0 * M_PI);
	double x = (180.0 + coord.longitude) / 360.0;
	return MKMapPointMake(x*MKMapWidth, y*MKMapHeight);
}

CLLocationCoordinate2D MKCoordinateForMapPoint(MKMapPoint mapPoint)
{
	double x = mapPoint.x / MKMapWidth;			// 0 ... MapWidth : 0 = -180 deg (west)
	double y = mapPoint.y / MKMapHeight;		// 0 ... MapHeigh : 0 = north
	CLLocationCoordinate2D loc;
	double n, l;
	x = fmod(x, 1.0);	// see http://www.gnu.org/s/hello/manual/libc/Remainder-Functions.html
	y = fmod(y, 1.0);
	n = y * (2.0 * M_PI) - M_PI;	// -PI ... +PI
	l = atan(0.5 * (exp(n) - exp(-n)));
	loc.latitude = (180.0 / M_PI) * l;
	loc.longitude = x * 360.0 - 180.0;	// -180 ... +180
	return loc;
}

// FIXME: the rect becomes distorted when represented as "span"!
// FIXME: there is no reverse function for this

MKCoordinateRegion MKCoordinateRegionForMapRect(MKMapRect rect)
{
	return MKCoordinateRegionMake(MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(rect), MKMapRectGetMidY(rect))),
								  MKCoordinateSpanMake( // FIXME:
													   /* lat */ 0.0, /* lng */ 0.0 )
								  );
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

double MKMapPointsPerMeterAtLatitude(CLLocationDegrees lat)
{
	return POINTS_PER_METER*cos((M_PI/180.0)*lat);
}

CLLocationDistance MKMetersPerMapPointAtLatitude(CLLocationDegrees lat)
{
	return 1.0/MKMapPointsPerMeterAtLatitude(lat);		
}

BOOL MKMapRectContainsPoint(MKMapRect rect, MKMapPoint point)
{
	if(point.x < rect.origin.x || point.x > rect.origin.x+rect.size.width) return NO;
	if(point.y < rect.origin.y || point.y > rect.origin.y+rect.size.height) return NO;
	return YES;
}

BOOL MKMapRectContainsRect(MKMapRect r1, MKMapRect r2)
{ // r1 contains all corner points of r2
	if(r2.origin.x < r1.origin.x || r2.origin.x+r2.size.width > r1.origin.x+r1.size.width) return NO;
	if(r2.origin.y < r1.origin.y || r2.origin.y+r2.size.height > r1.origin.y+r1.size.height) return NO;
	return YES;
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

MKMapRect MKMapRectIntersection(MKMapRect r1, MKMapRect r2)
{
	MKMapRect r;
	r.origin.x=MAX(r1.origin.x, r2.origin.x);
	r.origin.y=MAX(r1.origin.y, r2.origin.y);
	r.size.width=MIN(r1.origin.x+r1.size.width, r2.origin.x+r2.size.width)-r.origin.x;
	if(r.size.width < 0.0) r.size.width=0.0;	// no intersection
	r.size.height=MIN(r1.origin.y+r1.size.height, r2.origin.y+r2.size.height)-r.origin.y;
	if(r.size.height < 0.0) r.size.height=0.0;	// no intersection
	return r;	
}

BOOL MKMapRectIntersectsRect(MKMapRect r1, MKMapRect r2)
{
	if(r1.origin.x+r1.size.width < r2.origin.x)	return NO;
	if(r2.origin.x+r2.size.width < r1.origin.x) return NO;
	if(r1.origin.y+r1.size.height < r2.origin.y) return NO;
	if(r2.origin.y+r2.size.height < r1.origin.y) return NO;
	return YES;
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

BOOL MKMapRectSpans180thMeridian(MKMapRect rect)
{
	return MKMapRectGetMinX(rect) < 0 || MKMapRectGetMaxX(rect) > MKMapWidth;
}

MKMapRect MKMapRectUnion(MKMapRect r1, MKMapRect r2)
{
	MKMapRect r;
	if(MKMapRectIsEmpty(r1)) return r2;
	if(MKMapRectIsEmpty(r2)) return r1;
	r.origin.x=MIN(r1.origin.x, r2.origin.x);
	r.origin.y=MIN(r1.origin.y, r2.origin.y);
	r.size.width=MAX(r1.origin.x+r1.size.width, r2.origin.x+r2.size.width)-r.origin.x;
	r.size.height=MAX(r1.origin.y+r1.size.height, r2.origin.y+r2.size.height)-r.origin.y;
	return r;	
}

BOOL MKMapSizeEqualToSize(MKMapSize r1, MKMapSize r2)
{
	return r1.width == r2.width && r1.height == r2.height;
}

MKMapSize MKMapSizeMake(double w, double h)
{
	return (MKMapSize) { w, h };
}

NSString *MKStringFromMapPoint(MKMapPoint point) { return [NSString stringWithFormat:@"{ %lg (%.1lf%%), %lg (%.1lf%%) }", point.x, 100*point.x/MKMapWidth, point.y, 100*point.y/MKMapHeight]; }
NSString *MKStringFromMapRect(MKMapRect rect) { return [NSString stringWithFormat:@"{ %@, %@ }", MKStringFromMapPoint(rect.origin), MKStringFromMapSize(rect.size)]; }
NSString *MKStringFromMapSize(MKMapSize size) { return [NSString stringWithFormat:@"{ %lg, %lg }", size.width, size.height]; }

#if TODO

void MKMapRectDivide(MKMapRect rect, MKMapRect *slice, MKMapRect *remainder, double amount, CGRectEdge edge);
{
	
}

MKMapRect MKMapRectRemainder(MKMapRect rect);
{
	For a rectangle that lies on the 180th meridian, this function isolates the portion that lies outside the boundary, wraps it to the opposite side of the map, and returns that rectangle.
}

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

#endif

// EOF
