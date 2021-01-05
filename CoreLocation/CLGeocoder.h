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

@protocol CLGeocodeCompletionHandler <NSObject>	// mySTEP extension
- (void) placemarks:(NSArray *) placemarks error:(NSError *) error;
@end

// should be typedef void (^CLGeocodeCompletionHandler)(NSArray *placemark, NSError *error);
typedef id <CLGeocodeCompletionHandler> CLGeocodeCompletionHandler;

@interface CLGeocoder : NSObject
{
	NSURLConnection *connection;
	CLGeocodeCompletionHandler handler;
}

- (BOOL) isGeocoding;
- (void) cancelGeocode;
- (void) geocodeAddressDictionary:(NSDictionary *) address completionHandler:(CLGeocodeCompletionHandler) handler;
- (void) geocodeAddressString:(NSString *) address completionHandler:(CLGeocodeCompletionHandler) handler;
- (void) geocodeAddressString:(NSString *) address inRegion:(CLRegion *)region completionHandler:(CLGeocodeCompletionHandler) handler;
- (void) reverseGeocodeLocation:(CLLocation *) location completionHandler:(CLGeocodeCompletionHandler) handler;

@end
