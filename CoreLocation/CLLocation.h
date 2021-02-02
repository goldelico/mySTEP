//
//  CLLocation.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef double CLLocationAccuracy;
typedef double CLLocationDegrees;
typedef double CLLocationDirection;
typedef double CLLocationSpeed;

typedef struct _CLLocationCoordinate2D
{
	CLLocationDegrees latitude;		// positive values are north or aequator
	CLLocationDegrees longitude;	// positive values are east of Greenwich
} CLLocationCoordinate2D;

extern const CLLocationCoordinate2D kCLLocationCoordinate2DInvalid;
extern BOOL CLLocationCoordinate2DIsValid(CLLocationCoordinate2D loc);

#import <CoreLocation/CLLocationManager.h>	// defines CLLocationDistance

@interface CLLocation : NSObject <NSCopying, NSCoding>
{
@public	// well, this should not be @public but is the easiest way to allow the CLLocationManager to insert data received from GPS
	CLLocationCoordinate2D coordinate;
	CLLocationDistance altitude;
	CLLocationAccuracy horizontalAccuracy;
	CLLocationAccuracy verticalAccuracy;
	CLLocationDirection course;
	CLLocationSpeed speed;
	NSDate *timestamp;
}

- (CLLocationDistance) altitude;
- (CLLocationCoordinate2D) coordinate;
- (CLLocationDirection) course;
- (CLLocationAccuracy) horizontalAccuracy;
- (CLLocationSpeed) speed;
- (NSDate *) timestamp;
- (CLLocationAccuracy) verticalAccuracy;

- (NSString *) description;

- (CLLocationDistance) distanceFromLocation:(const CLLocation *) loc;

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord
				 altitude:(CLLocationDistance) alt
	   horizontalAccuracy:(CLLocationAccuracy) hacc
		 verticalAccuracy:(CLLocationAccuracy) vacc
				timestamp:(NSDate *) time;

- (id) initWithLatitude:(CLLocationDegrees) lat longitude:(CLLocationDegrees) lng;

@end
