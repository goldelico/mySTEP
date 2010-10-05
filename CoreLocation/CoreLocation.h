//
//  CoreLocation.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

// FIXME: --> CLLocation.h

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

@interface CLLocation : NSObject <NSCopying, NSCoding>

@end

// FIXME: ---> CLLocationManager

typedef double CLLocationDistance;

@interface CLLocationManager : NSObject

@end

/* there are also:

 CLError.h
 CLErrorDomain.h
 CLHeading.h

*/
