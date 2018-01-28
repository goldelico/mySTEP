//
//  CoreLocationDaemon.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 18.09.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

#define SERVER_ID @"com.Quantum-STEP.CoreLocation.CoreLocationDaemon"

@protocol CoreLocationDaemonProtocol
/* register a client */
- (void) registerManager:(byref CLLocationManager *) m;
- (void) unregisterManager:(byref CLLocationManager *) m;
/* ask some capabilities */
- (BOOL) headingAvailable;
- (BOOL) locationServicesEnabled;
- (BOOL) regionMonitoringAvailable;
- (BOOL) regionMonitoringEnabled;
- (BOOL) significantLocationChangeMonitoringAvailable;
/* ask some global status */
- (CLLocationSource) source;
- (int) numberOfReceivedSatellites;
- (int) numberOfReliableSatellites;
- (int) numberOfVisibleSatellites;
- (bycopy NSDate *) satelliteTime;
- (bycopy NSArray *) satelliteInfo;	// NSDictionaries with strings
/* interface to WLAN/WWAN system */
- (void) WLANseen:(NSString *) bssid;
- (void) WWANseen:(NSString *) cellid;
@end

@interface CoreLocationDaemon : NSObject <CoreLocationDaemonProtocol>
{
	NSMutableArray *managers;	// list of all managers
	NSString *lastChunk;
	NSFileHandle *file;
	NSArray *modes;
	CLLocation *newLocation;
	CLHeading *newHeading;
	int numReliableSatellites;
	int numVisibleSatellites;
	NSDate *satelliteTime;
	NSMutableArray *satelliteInfo;
}

- (NSString *) _device;
- (void) _didNotStart;
- (void) _processNMEA183:(NSString *) line;	// process complete line
- (void) _processRawData:(NSData *) data;	// process data fragment
- (void) _dataReceived:(NSNotification *) n;


@end
