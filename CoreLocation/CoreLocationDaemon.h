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
- (void) registerManager:(byref CLLocationManager *) m;
- (void) unregisterManager:(byref CLLocationManager *) m;
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
- (void) _parseNMEA183:(NSData *) line;	// process data fragment
- (void) _dataReceived:(NSNotification *) n;

@end
