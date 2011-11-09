//
//  CLExtensions.m
//  myNavigator
//
//  Created by H. Nikolaus Schaller on 08.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef __mySTEP__

#import "CLExtensions.h"

@implementation CLRegion

- (CLLocationCoordinate2D) center; { return center; }
- (NSString *) identifier; { return identifier; }
- (CLLocationDistance) radius; { return radius; }

- (BOOL) containsCoordinate:(CLLocationCoordinate2D) coordinate;
{
	return NO;
}

- (void) dealloc;
{
	[identifier release];
	[super dealloc];
}

- (id) initCircularRegionWithCenter:(CLLocationCoordinate2D) cent radius:(CLLocationDistance) rad identifier:(NSString *) ident;
{
	if((self=[super init]))
		{
		center=cent;
		radius=rad;
		identifier=[ident retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	CLRegion *c=[CLRegion alloc];
	if(c)
		{
		c->center=center;
		c->radius=radius;
		c->identifier=[identifier retain];
		}
	return c;
}

- (id) initWithCoder:(NSCoder *) coder
{
	//	self=[super initWithCoder:coder];
	if(self)
		{
		// decode keyed values
		}
	return self;	
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	//	[super encodeWithCoder:coder];
	// encode keyed values
}

@end

@implementation CLHeading

// init...

- (CLLocationDirection) headingAccuracy; { return headingAccuracy; }
- (CLLocationDirection) magneticHeading; { return magneticHeading; }
- (NSDate *) timestamp; { return timestamp; }
- (CLLocationDirection) trueHeading; { return trueHeading; }
- (CLHeadingComponentValue) x; { return x; }
- (CLHeadingComponentValue) y; { return y; }
- (CLHeadingComponentValue) z; { return z; }

- (void) dealloc
{
	[timestamp release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"magneticHeading %.lf trueHeading %.lf accuracy %.lf x %.lf y %.lf z %.lf a %.lf @ %@",
			magneticHeading, trueHeading, headingAccuracy,
			x, y, z,
			headingAccuracy, timestamp];
}

- (id) copyWithZone:(NSZone *) zone
{
	CLHeading *c=[CLHeading alloc];
	if(c)
		{
		c->headingAccuracy=headingAccuracy;
		c->magneticHeading=magneticHeading;
		c->trueHeading=trueHeading;
		c->x=x;
		c->y=y;
		c->z=z;
		c->timestamp=[timestamp retain];
		}
	return c;
}

- (id) initWithCoder:(NSCoder *) coder
{
	//	self=[super initWithCoder:coder];
	if(self)
		{
		// decode keyed values
		}
	return self;	
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	//	[super encodeWithCoder:coder];
	// encode keyed values
}

@end

@implementation CLPlacemark

// for a description see http://www.icodeblog.com/2009/12/22/introduction-to-mapkit-in-iphone-os-3-0-part-2/

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
- (NSString *) locality; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) subLocality; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) administrativeArea; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) subAdministrativeArea; { return [addressDictionary objectForKey:@"SubAdministrativeArea"]; }
- (NSString *) postalCode; { return [addressDictionary objectForKey:@"ZIP"]; }
- (NSString *) country; { return [addressDictionary objectForKey:@"Country"]; }
- (NSString *) countryCode; { return [addressDictionary objectForKey:@"CountryCode"]; }

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord addressDictionary:(NSDictionary *) addr;
{
	if((self=[super init]))
		{
		coordinate=coord;
		addressDictionary=[addr retain];	// FIXME: or copy?
		}
	return self;
}

- (void) dealloc
{
	[addressDictionary release];
	[super dealloc];
}

@end

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

- (void) reverseGeocodeLocation:(CLLocation *) location completionHandler:(CLGeocodeCompletionHandler) h;
{ //	http://developers.cloudmade.com/wiki/geocoding-http-api/Documentation#Reverse-Geocoding-httpcm-redmine01-datas3amazonawscomfiles101117091610_icon_beta_orangepng
	if(!connection)
		{ // build query and start
			handler=[h retain];
			// use reverse geocoding api:
			// read resulting property list
			// make asynchronous fetch and report result through [handler performSelectorWithObject:andObject:]
		}
}

- (void) geocodeAddressString:(NSString *) address inRegion:(CLRegion *)region completionHandler:(CLGeocodeCompletionHandler) h;
{ // http://developers.cloudmade.com/projects/show/geocoding-http-api
	if(!connection)
		{ // build query and start
			handler=[h retain];
			if(region)
				{
				// add to query
				}
			// FIXME: encode blanks as + and + as %25 etc.
			NSString *url=[NSString stringWithFormat:@"http://geocoding.cloudmade.com/%@/geocoding/v2/find.plist?query=%@", @"8ee2a50541944fb9bcedded5165f09d9", address];
			// make asynchronous fetch and report result through [handler performSelectorWithObject:andObject:]
			NSDictionary *dict=[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:url]];
		}
}

- (void) geocodeAddressString:(NSString *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	[self geocodeAddressString:address inRegion:nil completionHandler:h];
}

- (void) geocodeAddressDictionary:(NSDictionary *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	NSMutableString *str=[NSMutableString stringWithCapacity:50];
	// add components from address (if defined)
	[str appendFormat:@"133 Fleet street, London, UK"];
	[self geocodeAddressString:str completionHandler:h];
}

@end

@implementation NSBlockHandler

- (id) initWithDelegate:(id) d action:(SEL) a
{
	if((self=[self init]))
		{
		delegate=d;
		action=a;
		}
	return self;
}

+ (NSBlockHandler *) handlerWithDelegate:(id) d action:(SEL) a;
{
	return [[[self alloc] initWithDelegate:d action:a] autorelease];
}

- (id) performSelector;
{
	return [delegate performSelector:action];
}

- (id) performSelectorWithObject:(id) obj;
{
	return [delegate performSelector:action withObject:obj];
}

- (id) performSelectorWithObject:(id) obj1 withObject:(id) obj2;
{
	return [delegate performSelector:action withObject:obj1 withObject:obj2];
}

@end

#endif

// EOF
