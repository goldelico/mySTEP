//
//  MKCircle.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKShape.h>
#import <CoreLocation/CoreLocation.h>

@interface MKCircle : MKShape <MKOverlay>
{
	/* @property (nonatomic, readonly) MKMapRect boundingMapRect; */
	/* @property (nonatomic, readonly) */ CLLocationCoordinate2D coordinate;
	/* @property (nonatomic, readonly) */ CLLocationDistance radius;
}

+ (MKCircle *) circleWithCenterCoordinate:(CLLocationCoordinate2D) coord radius:(CLLocationDistance) radius;
+ (MKCircle *) circleWithMapRect:(MKMapRect) mapRect;	// longest side determines the radius

- (MKMapRect) boundingMapRect;
- (CLLocationCoordinate2D) coordinate;
- (CLLocationDistance) radius;

@end

// EOF
