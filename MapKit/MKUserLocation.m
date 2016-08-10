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
	NSLog(@"MKUserLocation locationManager:didUpdateToLocation:");
	[location release];
	location=[newloc retain];
	// make us redraw - what is the protocol how a MKAnnotation can notify the MKMapView about changes?
	// a) KVO?
	// b) does a MKAnnotation know its MKAnnotationView? Apparently no.
	// c) does (each) MKMapView have a timer to check for changes in [annotation coordinate]?
	// d) is there a global +[MKMapView _viewForAnnotation:] table with all visible annotations to find out the superview (MKMapView)?
	// anyways we have to call:
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
		NSLog(@"MKUserLocation init");
		manager=[CLLocationManager new];
		NSLog(@"CLLocationManager=%@", manager);
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
	fprintf(stderr, "MKUserLocation description: location =%p\n", location);
	CLLocationCoordinate2D l; /*=[location coordinate]*/;
	fprintf(stderr, "MKUserLocation coordinate %lg %lg\n", l.latitude, l.longitude);
	str= [NSString stringWithFormat:@"MKUserLocation (%lg %lg)", l.latitude, l.longitude];
	fprintf(stderr, "MKUserLocation str=%s\n", [str UTF8String]);
	fprintf(stderr, " class=%s\n", [NSStringFromClass([str class]) UTF8String]);
	return str;
}

@end

// EOF
