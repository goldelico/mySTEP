//
//  CLPlacemark.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 07.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

// update to 10.8+ API

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@interface CLPlacemark : NSObject
{
	CLLocationCoordinate2D coordinate;
	NSDictionary *addressDictionary;	
}

- (NSDictionary *) addressDictionary;
- (CLLocationCoordinate2D) coordinate;
- (void) setCoordinate:(CLLocationCoordinate2D) pos;
- (NSString *) thoroughfare;		// street
- (NSString *) subThoroughfare;		// street number
- (NSString *) locality;			// city
- (NSString *) subLocality;			// city district
- (NSString *) administrativeArea;		// state
- (NSString *) subAdministrativeArea;	// county
- (NSString *) postalCode;
- (NSString *) country;				// country
- (NSString *) countryCode;			// ISO

- (id) initWithPlacemark:(CLPlacemark *) placemark;
- (id) initWithCoordinate:(CLLocationCoordinate2D) coord addressDictionary:(NSDictionary *) addr;

@end

// EOF
