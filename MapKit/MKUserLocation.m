//
//  MKUserLocation.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MapKit.h>

@implementation MKUserLocation

// FIXME: how do we know our MKMapView?
// e.g. make the MKMapView the delegate and forward these messages

- (void) locationManager:(CLLocationManager *) mngr didFailWithError:(NSError *) err;
{
	// [mapView delegate] mapView:mapView didFailToLocateUserWithError:err];
}

- (void) locationManager:(CLLocationManager *) mngr didUpdateToLocation:(CLLocation *) newloc fromLocation:(CLLocation *) old;
{
	[location release];
	location=[newloc retain];
	// make us redraw - what is the protocol how a MKAnnotation can notify changes? KVO?
	// [[mapview delegate] mapView:mapView didUpdateUserLocation:self]
#if 1
//	NSLog(@"old location: %@", old);
	NSLog(@"new location: %@", newloc);
	// prints e.g. new location: <+48.01499810, +11.58788030> +/- 161.00m (speed 0.00 mps / course -1.00) @ 2011-04-22 11:01:22 +0200
#endif
}

- (id) init
{
	if((self=[super init]))
		{
		manager=[CLLocationManager new];
		[manager setDelegate:(id <CLLocationManagerDelegate>) self];
		[manager startUpdatingLocation];
		}
	return self;
}

- (void) dealloc
{
	[manager stopUpdatingLocation];
	[manager setDelegate:nil];
	[manager release];
	[subtitle release];
	[title release];
	[super dealloc];	
}

- (CLLocationCoordinate2D) coordinate; { return [location coordinate]; }
- (void) setCoordinate:(CLLocationCoordinate2D) pos; { return; }	// ignore
- (NSString *) subtitle; { return subtitle; }
- (NSString *) title; { return title; }

- (CLLocation *) location; { return location; }
- (BOOL) isUpdating; { return YES; }
- (void) setSubtitle:(NSString *) str; { [subtitle autorelease]; subtitle=[str retain]; }
- (void) setTitle:(NSString *) str; { [title autorelease]; title=[str retain]; }

- (NSString *) description;
{
	CLLocationCoordinate2D l=[location coordinate];
	return [NSString stringWithFormat:@"MKUserLocation (%lf %lf)", l.latitude, l.longitude];
}

@end

// EOF
