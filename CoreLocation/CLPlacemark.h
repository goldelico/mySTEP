//
//  CLPlacemark.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 07.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@interface CLPlacemark : NSObject
{
	CLLocationCoordinate2D coordinate;
	NSDictionary *addressDictionary;	
}

- (NSDictionary *) addressDictionary;
- (CLLocationCoordinate2D) coordinate;
- (NSString *) thoroughfare;
- (NSString *) subThoroughfare;
- (NSString *) locality;
- (NSString *) subLocality;
- (NSString *) administrativeArea;
- (NSString *) subAdministrativeArea;
- (NSString *) postalCode;
- (NSString *) country;
- (NSString *) countryCode;

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord addressDictionary:(NSDictionary *) addr;

@end

// EOF
