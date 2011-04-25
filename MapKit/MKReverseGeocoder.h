//
//  MKReverseGeocoder.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class MKReverseGeocoder;
@class MKPlacemark;

@protocol MKReverseGeocoderDelegate <NSObject>
- (void) reverseGeocoder:(MKReverseGeocoder *) coder didFindPlacemark:(MKPlacemark *) placemark;
- (void) reverseGeocoder:(MKReverseGeocoder *) coder didFailWithError:(NSError *) error;
@end

// FIXME: is there also a non-reverse geocoder? I.e. one that searches by Name and also returns matching placemarks?
// NOTE: we could add that one to the API by providing multiple placemarks and a "done" call to didFindPlacemark
// NOTE: we should also provide a reference location to search in the vicinity only

@interface MKReverseGeocoder : NSObject
{
	CLLocationCoordinate2D coordinate;
	id <MKReverseGeocoderDelegate> delegate;
	MKPlacemark *placemark;
	BOOL querying;
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
