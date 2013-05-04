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

typedef enum _CLAuthorizationStatus
{
	kCLAuthorizationStatusNotDetermined = 0,
	kCLAuthorizationStatusRestricted,
	kCLAuthorizationStatusDenied,
	kCLAuthorizationStatusAuthorized
} CLAuthorizationStatus;

@protocol CLLocationManagerDelegate;
@class CLLocation;
@class CLHeading;
@class CLRegion;

@interface CLLocationManager : NSObject
{
	id _server;
//	@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;
	CLLocationAccuracy desiredAccuracy;
//	@property(assign, nonatomic) CLLocationDistance distanceFilter;
	CLLocationDistance distanceFilter;
//	@property(assign, nonatomic) CLLocationDegrees headingFilter;
	CLLocationDegrees headingFilter;
//	@property(assign, nonatomic) CLDeviceOrientation headingOrientation;
	CLDeviceOrientation headingOrientation;
//	@property(readonly, nonatomic) CLLocationDistance maximumRegionMonitoringDistance;
	CLLocationDistance maximumRegionMonitoringDistance;
// @property(assign, nonatomic) id<CLLocationManagerDelegate> delegate;
	id <CLLocationManagerDelegate> delegate;
//	@property(readonly, nonatomic) CLLocation *location;
//	CLLocation *location;
//	@property(readonly, nonatomic) CLHeading *heading;
//	CLHeading *heading;
//	@property(readonly, nonatomic) NSSet *monitoredRegions;
	// NSSet *monitoredRegions;	// persistent by application (!) i.e. we may store in UserDefaults
//	@property(copy, nonatomic) NSString *purpose;
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

+ (CLAuthorizationStatus) authorizationStatus;	// if this application is allowed
+ (BOOL) headingAvailable;
+ (BOOL) locationServicesEnabled;	// if this device can determine location
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

@interface CLLocationManager (Extensions)

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
- (int) numberOfReliableSatellites;
- (int) numberOfVisibleSatellites;
- (bycopy NSDate *) satelliteTime;
- (bycopy NSArray *) satelliteInfo;	// NSDictionaries with strings

@end
