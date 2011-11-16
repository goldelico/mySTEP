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

// const CLLocationCoordinate2D kCLLocationCoordinate2DInvalid = { NAN, NAN };

typedef struct _CLLocationCoordinate2D
{
	CLLocationDegrees latitude;
	CLLocationDegrees longitude;
} CLLocationCoordinate2D;

#import <CoreLocation/CLLocationManager.h>	// defines CLLocationDistance

@interface CLLocation : NSObject <NSCopying, NSCoding>
{
@public	// well, this should not be but is the easiest way to allow the CLLocationManager to insert data received from GPS
	CLLocationCoordinate2D coordinate;
	CLLocationDistance altitude;
	CLLocationAccuracy horizontalAccuracy;
	CLLocationAccuracy verticalAccuracy;
	CLLocationDirection course;
	CLLocationSpeed speed;
	NSDate *timestamp;
	int numSatellites;
	int numVisibleSatellites;
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

/* extensions */

typedef enum _CLLocationSource
{
	CLLocationSourceUnknown		= 0,
	CLLocationSourceGPS			= 1<<0,
	CLLocationSourceGLONASS		= 1<<1,
	CLLocationSourceGALILEO		= 1<<2,
	CLLocationSourceWLAN		= 1<<3,
	CLLocationSourceWWAN		= 1<<4,
	CLLocationSourceInertial	= 1<<5,
	CLLocationSourceExternalAnt	= 1<<15,
} CLLocationSource;

- (CLLocationSource) source;
- (int) numberOfReceivedSatellites;
- (int) numberOfVisibleSatellites;

@end
