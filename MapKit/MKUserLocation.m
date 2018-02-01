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

- (void) _setMapView:(MKMapView *) mapView;
{
	_mapView=mapView;
}

- (void) locationManager:(CLLocationManager *) mngr didFailWithError:(NSError *) err;
{
	[_mapView locationManager:mngr didFailWithError:err];
}

- (void) locationManager:(CLLocationManager *) mngr didUpdateToLocation:(CLLocation *) newloc fromLocation:(CLLocation *) old;
{
	NSLog(@"MKUserLocation did send locationManager:didUpdateToLocation:");
	[location release];
	location=[newloc retain];
#if 1
//	NSLog(@"old location: %@", old);
	NSLog(@"new location %@: %@", mngr, newloc);
	// prints e.g. new location: <+48.01499810, +11.58788030> +/- 161.00m (speed 0.00 mps / course -1.00) @ 2011-04-22 11:01:22 +0200
	// anyways we have to call:
#endif
	[_mapView locationManager:mngr didUpdateToLocation:newloc fromLocation:old];
}

- (void) locationManager:(CLLocationManager *) mngr didUpdateHeading:(CLHeading *) head;
{
	NSLog(@"MKUserLocation did send locationManager:didUpdateHeading:");
#if 1
	NSLog(@"new heading %@: %@", mngr, head);
#endif
	[_mapView locationManager:mngr didUpdateHeading:head];
}

- (id) init
{
	if((self=[super init]))
		{
#if 1
		NSLog(@"MKUserLocation init");
#endif
		manager=[CLLocationManager new];
#if 1
		NSLog(@"CLLocationManager=%@", manager);
#endif
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
- (CLLocationManager *) locationManager; { return manager; }
- (BOOL) isUpdating; { return YES; }
- (void) setSubtitle:(NSString *) str; { [subtitle autorelease]; subtitle=[str retain]; }
- (void) setTitle:(NSString *) str; { [title autorelease]; title=[str retain]; }

- (NSString *) description;
{
	NSString *str;
	// fprintf(stderr, "MKUserLocation description: location =%p\n", location);
	CLLocationCoordinate2D l; /*=[location coordinate]*/;
	// fprintf(stderr, "MKUserLocation coordinate %lg %lg\n", l.latitude, l.longitude);
	str= [NSString stringWithFormat:@"MKUserLocation (%lg %lg)", l.latitude, l.longitude];
	// fprintf(stderr, "MKUserLocation str=%s\n", [str UTF8String]);
	// fprintf(stderr, " class=%s\n", [NSStringFromClass([str class]) UTF8String]);
	return str;
}

@end

// EOF
