//
//  CLGeocoder.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 07.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@class CLRegion, CLLocation;

#ifndef __mySTEP__
@interface NSBlockHandler : NSObject;	// mySTEP extension
- (void) performWithObject:(id) obj withObject:(id) obj;
@end
#endif

// typedef void (^CLGeocodeCompletionHandler)(NSArray *placemark, NSError *error);
typedef NSBlockHandler *CLGeocodeCompletionHandler;

@interface CLGeocoder : NSObject
{
	NSURLConnection *connection;
	NSBlockHandler *handler;
}

- (BOOL) isGeocoding;
- (void) cancelGeocode;
- (void) geocodeAddressDictionary:(NSDictionary *) address completionHandler:(CLGeocodeCompletionHandler) handler;
- (void) geocodeAddressString:(NSString *) address completionHandler:(CLGeocodeCompletionHandler) handler;
- (void) geocodeAddressString:(NSString *) address inRegion:(CLRegion *)region completionHandler:(CLGeocodeCompletionHandler) handler;
- (void) reverseGeocodeLocation:(CLLocation *) location completionHandler:(CLGeocodeCompletionHandler) handler;

@end
