//
//  CLLocationManagerDelegate.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLHeading;
@class CLLocation;
@class CLLocationManager;
@class CLRegion;

@protocol CLLocationManagerDelegate <NSObject>

- (void) locationManager:(CLLocationManager *) mngr didEnterRegion:(CLRegion *) region;
- (void) locationManager:(CLLocationManager *) mngr didExitRegion:(CLRegion *) region;
- (void) locationManager:(CLLocationManager *) mngr didFailWithError:(NSError *) err;
- (void) locationManager:(CLLocationManager *) mngr didUpdateHeading:(CLHeading *) head;
- (void) locationManager:(CLLocationManager *) mngr didUpdateToLocation:(CLLocation *) newloc fromLocation:(CLLocation *) old;
- (void) locationManager:(CLLocationManager *) mngr monitoringDidFailForRegion:(CLRegion *) region withError:(NSError *) err;
- (BOOL) locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *) mngr;

@end
