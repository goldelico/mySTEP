//
//  CLGeocoder.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 07.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLGeocoder.h"
#import "CLPlacemark.h"

@implementation CLGeocoder

- (void) cancelGeocode;
{
	if(connection)
		[connection cancel];
	[connection release];
	connection=nil;
}

- (void) dealloc
{
	[self cancelGeocode];
	[handler release];
	[super dealloc];
}

- (BOOL) isGeocoding;
{
	return connection != nil;
}

/* uses Nomintamin: http://wiki.openstreetmap.org/wiki/Nominatim
 * http://nominatim.openstreetmap.org/search?q=135+pilkington+avenue,+birmingham&format=json&polygon=1&addressdetails=1
 * http://nominatim.openstreetmap.org/reverse?format=xml&lat=52.5487429714954&lon=-1.81602098644987&zoom=18&addressdetails=1
 * http://open.mapquestapi.com/nominatim/v1/search
 */

- (void) reverseGeocodeLocation:(CLLocation *) location completionHandler:(CLGeocodeCompletionHandler) h;
{ 
	if(!connection)
		{ // build query and start
			handler=[h retain];
			// use reverse geocoding api:
			// read resulting property list
			// make asynchronous fetch and report result through [handler performSelectorWithObject:andObject:]
		}
}

- (void) geocodeAddressString:(NSString *) address inRegion:(CLRegion *)region completionHandler:(CLGeocodeCompletionHandler) h;
{
	if(!connection)
		{ // build query and start
			NSError *error=nil;
			CLPlacemark *placemark=nil;
			NSDictionary *dict=nil;
			handler=[h retain];
			if(region)
				{
				// add region to query
				}
			address=[address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			address=[address stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
			if(address)
				{ // try to load
					// FIXME: encode blanks as + and + as %25 etc.
					NSString *url=[NSString stringWithFormat:@"http://geocoding.cloudmade.com/%@/geocoding/v2/find.plist?query=%@", @"8ee2a50541944fb9bcedded5165f09d9", address];
					// make asynchronous fetch and report result through [handler performSelectorWithObject:andObject:]
					dict=[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:url]];
					// FIXME: do something with the result
#if 1
					NSLog(@"dict=%@", dict);
#endif				 
				}
			if(!dict)
				error=[NSError errorWithDomain:@"GeoCoder" code:0 userInfo:dict];
			else
				{
				CLLocationCoordinate2D coord;
				NSMutableDictionary *addr=[NSMutableDictionary dictionaryWithCapacity:10];
				// get values from query result
				// if everything is ok:
				placemark=[[[CLPlacemark alloc] initWithCoordinate:coord addressDictionary:addr] autorelease];
				}
			[h performSelectorWithObject:placemark andObject:error];
		}
}

- (void) geocodeAddressString:(NSString *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	[self geocodeAddressString:address inRegion:nil completionHandler:h];
}

- (void) geocodeAddressDictionary:(NSDictionary *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	NSMutableString *str=[NSMutableString stringWithCapacity:50];
	// add components from address as in ABAddress book (if defined)
	// example:
	[str appendFormat:@"133 Fleet street, London, UK"];
	
	[self geocodeAddressString:str completionHandler:h];
}

@end

