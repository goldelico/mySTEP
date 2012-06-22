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
#import "CLRegion.h"

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

/* uses Nominatim: http://wiki.openstreetmap.org/wiki/Nominatim
 * http://nominatim.openstreetmap.org/search?q=135+pilkington+avenue,+birmingham&format=json&polygon=1&addressdetails=1
 * http://nominatim.openstreetmap.org/reverse?format=xml&lat=52.5487429714954&lon=-1.81602098644987&zoom=18&addressdetails=1
 * http://open.mapquestapi.com/nominatim/v1/search
 *
 * we use XML format (and NSXMLDocument) since JSON (although a little simpler to transform) is only available on MacOS X 10.7 or later
 */

- (void) reverseGeocodeLocation:(CLLocation *) location completionHandler:(CLGeocodeCompletionHandler) h;
{ 
	if(!connection)
		{ // build query and start
			NSString *url;
			NSXMLDocument *xml;
			CLPlacemark *placemark=nil;
			NSError *error=nil;
			CLLocationCoordinate2D pos=[location coordinate];
			handler=[h retain];
			// zoom=18 gives street address
			url=[NSString stringWithFormat:@"http://nominatim.openstreetmap.org/reverse?format=xml&zoom=18&addressdetails=1&lat=%lg&lon=%lg", pos.latitude, pos.longitude];
#if 1
			NSLog(@"url=%@", url);
#endif
			xml=[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:url] options:0 error:&error];
#if 1
			NSLog(@"xml=%@", xml);
#endif
			if(xml)
				{
				CLLocationCoordinate2D coord;
				NSMutableDictionary *addr=[NSMutableDictionary dictionaryWithCapacity:10];
				// get values from query result
				// if everything is ok:
				placemark=[[[CLPlacemark alloc] initWithCoordinate:coord addressDictionary:addr] autorelease];
				[h performWithObject:[NSArray arrayWithObject:placemark] withObject:error];
				[xml release];
				}
		}
}

- (void) geocodeAddressString:(NSString *) address inRegion:(CLRegion *)region completionHandler:(CLGeocodeCompletionHandler) h;
{
	if(!connection)
		{ // build query and start
			NSMutableArray *placemarks=[NSMutableArray arrayWithCapacity:10];
			NSError *error=nil;
			handler=[h retain];
			address=[address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			address=[address stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
			address=[address stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];	// fixme: what happens with "abc%20" -> "abd%2520"
			if(address)
				{ // try to load
					// restrict to region bounding box
					NSString *url=[NSString stringWithFormat:@"http://nominatim.openstreetmap.org/search?format=xml&limit=50&polygon=0&addressdetails=1&q=%@", address];
					NSXMLDocument *xml;
					NSXMLElement *e;
					NSEnumerator *en;
					if(region)
						{ // add region to query
						CLLocationCoordinate2D center=[region center];
						CLLocationDistance radius=[region radius];
						// viewboxlbrt=<left>,<bottom>,<right>,<top>
						url=[url stringByAppendingFormat:@"&viewboxlbrt=%lg,%lg,%lg,%lg&bounded=1", center.longitude-radius, center.latitude-radius, center.longitude+radius, center.latitude+radius];
						}
#if 1
					NSLog(@"url=%@", url);
#endif
					xml=[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:url] options:0 error:&error];
#if 1
					NSLog(@"xml=%@", xml);
#endif
					/*
					 <searchresults ...>
					 <place ...>
					 <city>...</city>
					 <village>...</village>
					 <road>...</road>
					 </place>
					 </searchresults>
					 */
					e=[xml rootElement];	// <searchresults>
					en=[[e elementsForName:@"place"] objectEnumerator];
					while((e=[en nextObject]))
						{ // next <place> element
							CLLocationCoordinate2D coord;
							NSMutableDictionary *addr=[NSMutableDictionary dictionaryWithCapacity:10];
							NSEnumerator *a=[[e children] objectEnumerator];
							NSXMLElement *sub;
							coord.longitude=[[[e attributeForName:@"lon"] stringValue] doubleValue];
							coord.latitude=[[[e attributeForName:@"lat"] stringValue] doubleValue];
							while((sub=[a nextObject]))
								{
								NSString *type=[sub name];
								if([type isEqualToString:@"country"]) [addr setObject:[sub stringValue] forKey:@"Country"];
								else if([type isEqualToString:@"city"]) [addr setObject:[sub stringValue] forKey:@"City"];
								else if([type isEqualToString:@"road"]) [addr setObject:[sub stringValue] forKey:@"Street"];
#if 1
								else
									NSLog(@"unprocessed: %@", type);
#endif
								/*
								 state
								 country
								 country_code
								 village
								 county
								 state_district
								 place
								 postcode
								 suburb
								 information
								 */
								}
#if 1
							NSLog(@"addr=%@", addr);
#endif
							[placemarks addObject:[[[CLPlacemark alloc] initWithCoordinate:coord addressDictionary:addr] autorelease]];							
						}
					[xml release];
				}
			else
				error=[NSError errorWithDomain:@"GeoCoder" code:0 userInfo:nil];	// invalid search string
			[h performWithObject:placemarks withObject:error];
			[h release];
		}
}

- (void) geocodeAddressString:(NSString *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	[self geocodeAddressString:address inRegion:nil completionHandler:h];
}

- (void) geocodeAddressDictionary:(NSDictionary *) dict completionHandler:(CLGeocodeCompletionHandler) h;
{
	NSMutableString *str=[NSMutableString stringWithCapacity:50];
	/* example
     NSDictionary *locationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
	 @"San Francisco", kABPersonAddressCityKey,
	 @"United States", kABPersonAddressCountryKey,
	 @"us", kABPersonAddressCountryCodeKey,
	 @"1398 Haight Street", kABPersonAddressStreetKey,
	 @"94117", kABPersonAddressZIPKey,
	 nil];
	 */
	if([[dict objectForKey:@"Street"] length] > 0)
		[str appendFormat:@", %@", [dict objectForKey:@"Street"]];
	if([[dict objectForKey:@"City"] length] > 0)
		[str appendFormat:@", %@", [dict objectForKey:@"City"]];
	if([[dict objectForKey:@"Country"] length] > 0)
		[str appendFormat:@", %@", [dict objectForKey:@"Country"]];
	[self geocodeAddressString:[str stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]] completionHandler:h];
}

@end

