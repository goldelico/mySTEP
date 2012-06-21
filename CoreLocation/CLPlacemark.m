//
//  CLPlacemark.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 07.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLPlacemark.h"

@implementation CLPlacemark

// for a description see http://www.icodeblog.com/2009/12/22/introduction-to-mapkit-in-iphone-os-3-0-part-2/
// attribute names should be compatible to ABGlobals.h

- (NSDictionary *) addressDictionary; { return addressDictionary; }

- (CLLocationCoordinate2D) coordinate; { return coordinate; }

- (void) setCoordinate:(CLLocationCoordinate2D) pos;
{ // checkme: does this method exist?
	coordinate=pos;
}

- (NSString *) subtitle;
{
	return @"Subtitle";	
}

- (NSString *) title;
{
	return @"Placemmark";
}

- (NSString *) thoroughfare; { return [addressDictionary objectForKey:@"Throughfare"]; }
- (NSString *) subThoroughfare; { return [addressDictionary objectForKey:@"SubThroughfare"]; }
- (NSString *) locality; { return [addressDictionary objectForKey:@"City"]; }
- (NSString *) subLocality; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) administrativeArea; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) subAdministrativeArea; { return [addressDictionary objectForKey:@"SubAdministrativeArea"]; }
- (NSString *) postalCode; { return [addressDictionary objectForKey:@"ZIP"]; }
- (NSString *) country; { return [addressDictionary objectForKey:@"Country"]; }
- (NSString *) countryCode; { return [addressDictionary objectForKey:@"CountryCode"]; }

- (id) initWithPlacemark:(CLPlacemark *) placemark;
{ // just copy...
	return [self initWithCoordinate:[placemark coordinate] addressDictionary:[placemark addressDictionary]];
}

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord addressDictionary:(NSDictionary *) addr;
{
	if((self=[super init]))
		{
		coordinate=coord;
		addressDictionary=[addr copy];
		}
	return self;
}

- (void) dealloc
{
	[addressDictionary release];
	[super dealloc];
}

@end

// EOF
