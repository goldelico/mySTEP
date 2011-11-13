//
//  CLHeading.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

typedef double CLHeadingComponentValue;	// in uTesla

@interface CLHeading : NSObject <NSCopying, NSCoding>
{
@public	// well, this should not be but is the easiest way to allow the CLLocationManager to insert data received from GPS
	CLLocationDirection headingAccuracy;
	CLLocationDirection magneticHeading;
	CLLocationDirection trueHeading;
	CLHeadingComponentValue x;
	CLHeadingComponentValue y;
	CLHeadingComponentValue z;
	NSDate *timestamp;
}

- (CLLocationDirection) headingAccuracy;
- (CLLocationDirection) magneticHeading;
- (NSDate *) timestamp;
- (CLLocationDirection) trueHeading;
- (CLHeadingComponentValue) x;
- (CLHeadingComponentValue) y;
- (CLHeadingComponentValue) z;

- (NSString *) description;

@end
