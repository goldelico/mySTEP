//
//  CLLocationManager.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef double CLLocationDistance;

#import <CoreLocation/CLLocation.h>

typedef enum _CLDeviceOrientation
{
	CLDeviceOrientationUnknown = 0,
	CLDeviceOrientationPortrait,
	CLDeviceOrientationPortraitUpsideDown,
	CLDeviceOrientationLandscapeLeft,
	CLDeviceOrientationLandscapeRight,
	CLDeviceOrientationFaceUp,
	CLDeviceOrientationFaceDown
} CLDeviceOrientation;

@protocol CLLocationManagerDelegate;
@class CLLocation;
@class CLHeading;
@class CLRegion;

@interface CLLocationManager : NSObject
{
	CLLocationAccuracy desiredAccuracy;
	CLLocationDistance distanceFilter;
	CLLocationDegrees headingFilter;
	CLDeviceOrientation headingOrientation;
	CLLocationDistance maximumRegionMonitoringDistance;
	id <CLLocationManagerDelegate> delegate;
	CLLocation *location;
	CLHeading *heading;
	// NSSet *monitoredRegions;	// persistent by application (!) i.e. we may store in UserDefaults
	NSString *purpose;
}

- (id <CLLocationManagerDelegate>) delegate;
- (CLLocationAccuracy) desiredAccuracy;
- (CLLocationDistance) distanceFilter;
- (CLHeading *) heading;
- (CLLocationDegrees) headingFilter;
- (CLDeviceOrientation) headingOrientation;
- (CLLocation *) location;
- (CLLocationDistance) maximumRegionMonitoringDistance;
- (NSSet *) monitoredRegions;	// persistent by application (!)
- (NSString *) purpose;

- (void) setDelegate:(id <CLLocationManagerDelegate>) d;
- (void) setDesiredAccuracy:(CLLocationAccuracy) acc;
- (void) setDistanceFilter:(CLLocationDistance) filter;
- (void) setHeadingFilter:(CLLocationDegrees) filter;
- (void) setHeadingOrientation:(CLDeviceOrientation) orient;
- (void) setPurpose:(NSString *) string;

+ (BOOL) headingAvailable;
+ (BOOL) locationServicesEnabled;
+ (BOOL) regionMonitoringAvailable;
+ (BOOL) regionMonitoringEnabled;	// system setting
+ (BOOL) significantLocationChangeMonitoringAvailable;	// system setting

- (void) dismissHeadingCalibrationDisplay;
- (void) startMonitoringForRegion:(CLRegion *) region desiredAccuracy:(CLLocationAccuracy) accuracy;
- (void) startMonitoringSignificantLocationChanges;
- (void) startUpdatingHeading;
- (void) startUpdatingLocation;
- (void) stopMonitoringForRegion:(CLRegion *) region;
- (void) stopMonitoringSignificantLocationChanges;
- (void) stopUpdatingHeading;
- (void) stopUpdatingLocation;

@end
