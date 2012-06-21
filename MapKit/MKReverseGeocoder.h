//
//  MKReverseGeocoder.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#ifndef __mySTEP__
#import <MapKit/CLExtensions.h>
#endif

@class MKReverseGeocoder;
@class MKPlacemark;

@protocol MKReverseGeocoderDelegate <NSObject>
- (void) reverseGeocoder:(MKReverseGeocoder *) coder didFindPlacemark:(MKPlacemark *) placemark;
- (void) reverseGeocoder:(MKReverseGeocoder *) coder didFailWithError:(NSError *) error;
@end

// Now, there is also a reverse and forward geocoder in CoreLocation with different API

@interface MKReverseGeocoder : NSObject
{
	CLLocationCoordinate2D coordinate;
	id <MKReverseGeocoderDelegate> delegate;
	MKPlacemark *placemark;
	CLGeocoder *geocoder;
}

- (void) cancel;
- (CLLocationCoordinate2D) coordinate;
- (id <MKReverseGeocoderDelegate>) delegate;
- (id) initWithCoordinate:(CLLocationCoordinate2D) coord;
- (BOOL) isQuerying;
- (MKPlacemark *) placemark;
- (void) start;

@end

// EOF
