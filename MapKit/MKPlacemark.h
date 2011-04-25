//
//  MKPlacemark.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

@interface MKPlacemark : NSObject <MKAnnotation>
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
