//
//  CoreLocation.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <AppKit/NSApplication.h>	// for NSEventTrackingRunLoopMode
#import "CoreLocationDaemon.h"

NSString *const kCLErrorDomain=@"CLErrorDomain";
const CLLocationCoordinate2D kCLLocationCoordinate2DInvalid = { NAN, NAN };

@implementation CLLocation

- (CLLocationDistance) altitude; { return altitude; }
- (CLLocationCoordinate2D) coordinate; { return coordinate; }
- (CLLocationDirection) course; { return course; }
- (CLLocationAccuracy) horizontalAccuracy; { return horizontalAccuracy; }
- (CLLocationSpeed) speed; { return speed; }
- (NSDate *) timestamp; { return timestamp; }
- (CLLocationAccuracy) verticalAccuracy; { return verticalAccuracy; }

- (BOOL) isEqual:(id)object
{
	if(((CLLocation *)object) -> altitude != altitude) return NO;
	if(((CLLocation *)object) -> coordinate.latitude != coordinate.latitude) return NO;
	if(((CLLocation *)object) -> coordinate.longitude != coordinate.longitude) return NO;
	if(((CLLocation *)object) -> course != course) return NO;
	if(((CLLocation *)object) -> horizontalAccuracy != horizontalAccuracy) return NO;
	if(((CLLocation *)object) -> speed != speed) return NO;
	if(((CLLocation *)object) -> verticalAccuracy != verticalAccuracy) return NO;
	return [((CLLocation *)object) ->timestamp isEqual:timestamp];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%lg, %lg> +/- %lgm (speed %lg kph / heading %lg) @ %@",
			coordinate.latitude, coordinate.longitude,
			horizontalAccuracy,
			speed,
			course,
			timestamp];
}

/* there should be a unit test example like http://studyswift.blogspot.de/2016/07/cllocationdistance-distance-between-two.html */
- (CLLocationDistance) distanceFromLocation:(const CLLocation *) loc;
{
	CLLocationCoordinate2D b=[loc coordinate];
	if(!loc)
		return FLT_MAX;
	/* use WGS84 average */
	return 6371000.8*acos(sin(coordinate.latitude)*sin(b.latitude) + cos(coordinate.latitude)*cos(b.latitude)*cos(b.longitude-coordinate.longitude));
}

- (void) dealloc
{
	[timestamp release];
	[super dealloc];
}

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord
				 altitude:(CLLocationDistance) alt
	   horizontalAccuracy:(CLLocationAccuracy) hacc
		 verticalAccuracy:(CLLocationAccuracy) vacc
				timestamp:(NSDate *) time;
{
	if(self = [super init])
		{
		altitude=alt;
		coordinate=coord;
		course=0.0;
		horizontalAccuracy=hacc;
		speed=0.0;
		verticalAccuracy=vacc;
		timestamp=[time retain];
		}
	return self;
}

- (id) initWithLatitude:(CLLocationDegrees) lat longitude:(CLLocationDegrees) lng;
{
	return [self initWithCoordinate:(CLLocationCoordinate2D) { lat, lng }
						   altitude:0.0		// sea level
				 horizontalAccuracy:0.0		// exact
				   verticalAccuracy:-1.0	// unknown
						  timestamp:[NSDate date]];	// now
}

- (id) copyWithZone:(NSZone *) zone
{
	CLLocation *c=[CLLocation alloc];
	if(c)
		{
		c->altitude=altitude;
		c->coordinate=coordinate;
		c->course=course;
		c->horizontalAccuracy=horizontalAccuracy;
		c->speed=speed;
		c->verticalAccuracy=verticalAccuracy;
		c->timestamp=[timestamp retain];
		}
	return c;
}

- (id) initWithCoder:(NSCoder *) coder
{
//	self=[super initWithCoder:coder];
	if(self)
		{
		// decode keyed values
		}
	return self;	
}

- (void) encodeWithCoder:(NSCoder *) coder
{
//	[super encodeWithCoder:coder];
	// encode keyed values
}

@end

@implementation CLLocationManager

- (id <CLLocationManagerDelegate>) delegate; { return delegate; }
- (CLLocationAccuracy) desiredAccuracy; { return desiredAccuracy; }
- (CLLocationDistance) distanceFilter; { return distanceFilter; }
//- (CLHeading *) heading; { return newHeading; }
- (CLLocationDegrees) headingFilter; { return headingFilter; }
// FIXME: ask UIDevice? No: this variable indicates how the delegate wants to get the heading reported
- (CLDeviceOrientation) headingOrientation; { return headingOrientation; }
//- (CLLocation *) location; { return newLocation; }
- (CLLocationDistance) maximumRegionMonitoringDistance; { return maximumRegionMonitoringDistance; }
- (NSSet *) monitoredRegions; { return [[NSUserDefaults standardUserDefaults] objectForKey:@"_CoreLocationManagerRegions"]; }	// persistent by application (!)
- (NSString *) purpose; { return purpose; }

- (void) setDelegate:(id <CLLocationManagerDelegate>) d; { delegate=d; }
- (void) setDesiredAccuracy:(CLLocationAccuracy) acc; { desiredAccuracy=acc; }
- (void) setDistanceFilter:(CLLocationDistance) filter; { distanceFilter=filter; }
- (void) setHeadingFilter:(CLLocationDegrees) filter; { headingFilter=filter; }
- (void) setHeadingOrientation:(CLDeviceOrientation) orient; { headingOrientation=orient; }
- (void) setPurpose:(NSString *) string; { [purpose autorelease]; purpose=[string copy]; }

+ (CLAuthorizationStatus) authorizationStatus;	// if this application is allowed
{
	return kCLAuthorizationStatusAuthorized;
}

+ (BOOL) headingAvailable;
{
	// how can we find out?
	// if we have a compass...
	return NO;
}

+ (BOOL) locationServicesEnabled
{
	return YES;
}

+ (BOOL) regionMonitoringAvailable
{
	return NO;
}

+ (BOOL) regionMonitoringEnabled
{ // system setting
	return NO;
}

+ (BOOL) significantLocationChangeMonitoringAvailable
{ // system setting
	return NO;
}

- (void) didUpdateHeading:(CLHeading *) newHeading;
{
	// FIXME: we could filter real changes

	[heading autorelease];
	heading=[newHeading retain];
	[delegate locationManager:self didUpdateHeading:newHeading];
}

- (void) didUpdateToLocation:(CLLocation *) newLocation;
{
	CLLocation *oldLocation=location;

	// FIXME: we could filter real changes

	[location autorelease];
	location=[newLocation retain];
#if 0
	NSLog(@"didUpdateToLocation: %@ -> %@", delegate, newLocation);
#endif
	[delegate locationManager:self didUpdateToLocation:newLocation fromLocation:oldLocation];
}

- (CLHeading *) heading;
{
	return heading;
}

- (CLLocation *) location;
{
	return location;
}

- (id) init;
{
	NSBundle *b=[NSBundle bundleForClass:[self class]];	// our bundle where the daemon sits in the resources
	NSString *path=[b pathForResource:@"CoreLocationDaemon" ofType:@"app"];
	NS_DURING
#if 1
		NSLog(@"Bundle: %@", b);
		NSLog(@"Trying to connect to server %@ @ %@", SERVER_ID, path);
#endif
		_server=[[NSConnection rootProxyForConnectionWithRegisteredName:SERVER_ID host:nil] retain];	// look up on local host only
	NS_HANDLER
#if 1
		NSLog(@"Exception: %@", localException);
#endif
	NS_ENDHANDLER
	if(!_server)
		{ // not available - launch server process and try again
#if 1
			NSLog(@"no contact to daemon; try to launch process");
#endif
			if(![[NSWorkspace sharedWorkspace]
#if __mySTEP__
				 launchAppWithBundleIdentifier:path
#else
				 launchAppWithBundleIdentifier:SERVER_ID
#endif
			 options:NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAndHide | NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:nil
			 launchIdentifier:NULL])
				{
				NSLog(@"could not launch %@", SERVER_ID);
#if 1
				// Hack until we have the daemon running...
				static CoreLocationDaemon *_sharedDaemon;
				if(!_sharedDaemon)
					_sharedDaemon=[[CoreLocationDaemon alloc] init];	// add a local daemon object but share for all CLLocation instances
				_server=_sharedDaemon;
				NSLog(@"server = %@", _server);
				return self;
#endif
				[self release];
				return nil;
				}
#if 1
			NSLog(@"daemon launched");
#endif
			// FIXME: run the loop or wait otherwise
			sleep(2);	// wait a little for the server process to start
#if 1
			NSLog(@"try to contact");
#endif
			NS_DURING
				_server=[[NSConnection rootProxyForConnectionWithRegisteredName:SERVER_ID 
																		   host:nil] retain];	// try again
			NS_HANDLER
#if 1
				NSLog(@"Exception: %@", localException);
#endif
			NS_ENDHANDLER
			if(!_server)
				{ // not available although we tried to launch server process
					NSLog(@"no response from %@", SERVER_ID);
#if 1
					// Hack until we have the daemon running...
					static CoreLocationDaemon *_sharedDaemon;
					if(!_sharedDaemon)
						_sharedDaemon=[[CoreLocationDaemon alloc] init];	// add a local daemon object but share for all CLLocation instances
					_server=_sharedDaemon;
					NSLog(@"server = %@", _server);
					return self;
#endif
				}
			[_server setProtocolForProxy:@protocol(CoreLocationDaemonProtocol)];
#if 1
			NSLog(@"initialized");
#endif
			// FIXME: maybe we should block until we get the first fix
		}
	return self;
}

- (void) dealloc
{
#if 1
	NSLog(@"CLLocationManager dealloc");
#endif
	[purpose release];
	[_server release];
	[self stopMonitoringSignificantLocationChanges];
	[self stopUpdatingHeading];
	[self stopUpdatingLocation];
	[super dealloc];
#if 1
	NSLog(@"CLLocationManager deallocated");
#endif
}

- (void) dismissHeadingCalibrationDisplay;
{
	
}

- (void) startMonitoringForRegion:(CLRegion *) region desiredAccuracy:(CLLocationAccuracy) accuracy;
{
	// add to user defaults
	// and start monitoring
}

- (void) startMonitoringSignificantLocationChanges;
{
	// check if we need calibration, ask user for enable, purpose is not nil etc.
}

- (void) startUpdatingHeading;
{
	// what makes the difference?
	// basically if we want to receive heading callbacks...
	// maybe we can store that in a iVar and have the location manager check what we want to receive
	// and we can switch on/off the compass
}

- (void) startUpdatingLocation;
{
	// FIXME: first call after being stopped should scan for a first location update
#if 0
	NSLog(@"startUpdatingLocation");
	NSLog(@"_server=%@", _server);
	NSLog(@"manager=%@", self);
#endif
	NS_DURING
		[_server registerManager:self];
	NS_HANDLER
		NSLog(@"could not startUpdatingLocation");
	NS_ENDHANDLER
}

- (void) stopMonitoringForRegion:(CLRegion *) region;
{
	
}

- (void) stopMonitoringSignificantLocationChanges;
{
	
}

- (void) stopUpdatingHeading;
{

}

- (void) stopUpdatingLocation;
{
	NS_DURING
		[_server unregisterManager:self];
	NS_HANDLER
		NSLog(@"could not stopUpdatingLocation");
	NS_ENDHANDLER
}

@end

@implementation CLLocationManager (Extensions)

- (int) numberOfReceivedSatellites;
{ // count all satellites with SNR > 0
	NS_DURING	// protect against communication problems
		NS_VALUERETURN([(CoreLocationDaemon *) _server numberOfReceivedSatellites], int);
	NS_HANDLER
		NSLog(@"Exception during numberOfReceivedSatellites: %@", localException);
	NS_ENDHANDLER
	return 0;
}

- (int) numberOfReliableSatellites;
{
	NS_DURING	// protect against communication problems
		NS_VALUERETURN([(CoreLocationDaemon *) _server numberOfReliableSatellites], int);
	NS_HANDLER
		NSLog(@"Exception during numberOfReliableSatellites: %@", localException);
	NS_ENDHANDLER
	return 0;
}

- (int) numberOfVisibleSatellites;
{
	NS_DURING	// protect against communication problems
		NS_VALUERETURN([(CoreLocationDaemon *) _server numberOfVisibleSatellites], int);
	NS_HANDLER
		NSLog(@"Exception during numberOfVisibleSatellites: %@", localException);
	NS_ENDHANDLER
	return 0;
}

- (CLLocationSource) source;
{
	NS_DURING	// protect against communication problems
		NS_VALUERETURN([(CoreLocationDaemon *) _server source], CLLocationSource);
	NS_HANDLER
		NSLog(@"Exception during source: %@", localException);
	NS_ENDHANDLER
	return CLLocationSourceUnknown;
}

- (NSDate *) satelliteTime
{
	NS_DURING	// protect against communication problems
		NS_VALUERETURN([(CoreLocationDaemon *) _server satelliteTime], NSDate *);
	NS_HANDLER
		NSLog(@"Exception during satelliteTime: %@", localException);
	NS_ENDHANDLER
	return nil;
}

- (NSArray *) satelliteInfo
{
#if 0
	NSLog(@"%@ satelliteInfo", self);
#endif
	NS_DURING	// protect against communication problems
		NS_VALUERETURN([(CoreLocationDaemon *) _server satelliteInfo], NSArray *);
	NS_HANDLER
		NSLog(@"Exception during satelliteInfo: %@", localException);
	NS_ENDHANDLER
	return nil;
}

@end

// FIXME: quite inefficient - this means that the daemon sends a DO message and we ignore it...
// i.e. we should control the daemon that we do (not) want to see this more than once

@implementation NSObject (CLLocationManagerDelegate)

- (void) locationManager:(CLLocationManager *) mngr didReceiveNMEA:(NSString *) str;
{ // default delegate method
	// [_server dontSendNMEAtoManager:mngr];
	return;
}

@end

// EOF
