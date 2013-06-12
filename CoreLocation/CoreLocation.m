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

@implementation CLLocation

- (CLLocationDistance) altitude; { return altitude; }
- (CLLocationCoordinate2D) coordinate; { return coordinate; }
- (CLLocationDirection) course; { return course; }
- (CLLocationAccuracy) horizontalAccuracy; { return horizontalAccuracy; }
- (CLLocationSpeed) speed; { return speed; }
- (NSDate *) timestamp; { return timestamp; }
- (CLLocationAccuracy) verticalAccuracy; { return verticalAccuracy; }

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%lg, %lg> +/- %lgm (speed %lg kph / heading %lg) @ %@",
			coordinate.latitude, coordinate.longitude,
			horizontalAccuracy,
			speed,
			course,
			timestamp];
}

- (CLLocationDistance) distanceFromLocation:(const CLLocation *) loc;
{
	if(!loc)
		return FLT_MAX;
	// Großkreisentfernung berechnen
	return -1.0;
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

#if OLD
@interface CLLocationManager (GPSNMEA)
+ (void) registerManager:(CLLocationManager *) m;
+ (void) unregisterManager:(CLLocationManager *) m;
+ (void) _processNMEA183:(NSString *) line;	// process complete line
+ (void) _parseNMEA183:(NSData *) line;	// process data fragment
+ (void) _dataReceived:(NSNotification *) n;
@end

static CLLocation *newLocation;
static CLHeading *newHeading;
#endif

@implementation CLLocationManager

// FIXME: there must be multiple delegates - one for each remote connection!

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

- (CLHeading *) heading;
{
	return nil;
}

- (CLLocation *) location;
{
	return nil;
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
				[self release];
				return nil;
				}
#if 1
			NSLog(@"daemon launched");
#endif
			// FIXME: run the loop or wait otherwise
			sleep(2);	// wait a little for the server to start
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
				{ // not available - launch server process
					NSLog(@"no response from %@", SERVER_ID);
					[self release];
					return nil;
				}
			[_server setProtocolForProxy:@protocol(CoreLocationDaemonProtocol)];
#if 1
			NSLog(@"initialized");
#endif
			// FIXME: maybe we should block until we get the first fix
		}
	return self;
}

#if OLD
- (id) init
{
	NSLog(@"init");
	if((self=[super init]))
		{
		NSString *portName=NSStringFromClass([self class]);
		NSPort *server=[NSMessagePort port];	// create a new port where we try to vend our-self
		NSConnection *connection;
		int i;
		for(i=0; i<2; i++)
			{ // the first attempt to register the port may fail in case of a stale port
#if 1
			NSLog(@"try: %d %@", i, self);
#endif
			if(![[NSMessagePortNameServer sharedInstance] registerPort:server name:portName])
				{ // failed to register - a server is already running - become client
					id client;
#if 1
					NSLog(@"failed to register as %@", portName);
#endif
					NS_DURING
						connection=[NSConnection connectionWithRegisteredName:portName host:nil];
						NSLog(@"self1 %@", self);
						[connection setReplyTimeout:5.0];
						NSLog(@"self2 %@", self);
						client=(id)[connection rootProxy];
						NSLog(@"self3 %@", self);
					NS_HANDLER	// if the port was stale, retry to become server
						NSLog(@"could not connect %@ try again", portName);
						continue;	// try again
					NS_ENDHANDLER
#if 1
					NSLog(@"CLLocationManager client initialized: %@", portName, self);
#endif
					[self release];
					return client;	// return the rootProxy
				}
			else
				{
#if 1
				NSLog(@"registered %@", server);
#endif
				connection=[NSConnection connectionWithReceivePort:server sendPort:nil];
				[connection setRootObject:self];	// vend our own services
#if 0	// TEST if second registration fails
				server=[NSMessagePort port];	// make another one
				if(![[NSMessagePortNameServer sharedInstance] registerPort:server name:/*@"other"*/portName])	// try again on same name
					NSLog(@"failed");	// registering the same name again should fail!
				else
					NSLog(@"succeeded");
#endif
#if 1
				NSLog(@"%@ server initialized: %@", portName, self);
#endif
				return self;	// return the local handler
				}
			}
		}
	[self release];
	return nil;	// finally failed to initialize (neither as server nor as client)
}
#endif

- (void) dealloc
{
	[purpose release];
	[_server release];
	[self stopMonitoringSignificantLocationChanges];
	[self stopUpdatingHeading];
	[self stopUpdatingLocation];
	[super dealloc];
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
	NSLog(@"_server=%@", _server);
	NSLog(@"manager=%@", self);
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
	NS_DURING	// protect against communication problems
	NS_VALUERETURN([(CoreLocationDaemon *) _server satelliteInfo], NSArray *);
	NS_HANDLER
	NSLog(@"Exception during satelliteInfo: %@", localException);
	NS_ENDHANDLER
	return nil;
}

@end

#if OLD

// we should  integrate sensor data from GPS, barometric Altimeter, Gyroscope, Accelerometer, and Compass 
// though a Kalman-Bucy filter

// private methods to handle NMEA data from a serial interface

@implementation CLLocationManager (GPSNMEA)

// this should be a system-wide service i.e. access through DO!
// the first user process launches the service which stops itself if the last
// user process stops

// FIXME: send heading updates

// FIXME: make this iVars?
static NSMutableArray *managers;	// list of all managers
static NSString *lastChunk;
static NSFileHandle *file;
static NSArray *modes;

// special code for the W2SG0004 on the GTA04 board

static int startW2SG;

+ (NSString *) _device
{ // get this from some *system wide* user default
	NSString *dev=[[NSUserDefaults standardUserDefaults] stringForKey:@"NMEAGPSSerialDevice"];	// e.g. /dev/ttyO1 or /dev/cu.usbmodem1d11
	if(!dev)
		{
#ifdef __mySTEP__
		dev=@"/dev/ttyO1";	// Linux: serial interface for USB receiver
#else
		dev=@"/dev/cu.BT-348_GPS-Serialport-1";	// Mac OS X: serial interface for NMEA receiver
#endif
		}
	return dev;
}

+ (void) _didNotStart
{ // timeout - try to retrigger
#if 1
	NSLog(@"did not yet receive NMEA");
#endif
	if(startW2SG == 3)
		{ // permanent problem
			NSError *error=[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil];
			NSEnumerator *e=[managers objectEnumerator];
			CLLocationManager *m;
			NSLog(@"GPS receiver not working");
			while((m=[e nextObject]))
				{ // notify all CLLocationManager instances
					id <CLLocationManagerDelegate> delegate=[m delegate];
					NS_DURING
					if([delegate respondsToSelector:@selector(locationManager:didFailWithError:)])
						[delegate locationManager:m didFailWithError:error];
					NS_HANDLER
					; // ignore
					NS_ENDHANDLER
				}
			return;	// trigger again if manager is re-registered
		}
#ifdef __mySTEP__
	// GTA04-specific!
	system([[NSString stringWithFormat:@"echo 0 >/sys/devices/virtual/gpio/gpio145/value; echo 1 >/sys/devices/virtual/gpio/gpio145/value; stty 9600 <%@", [self _device]] UTF8String]);	// give a start/stop impulse and set up interface
#endif
	[self performSelector:_cmd withObject:nil afterDelay:++startW2SG > 4?30.0:5.0];	// we did not (yet) receive NMEA records
}

+ (void) registerManager:(CLLocationManager *) m
{
#if 1
	NSLog(@"registerManager: %@", m);
#endif
	if(![self locationServicesEnabled])
		return;	// ignore
	/*
	 * check if permanently enabled
	 * otherwise ask user
	 */
	if(!managers)
		{ // set up GPS receiver and wait for first fix
			NSString *dev=[self _device];
#if 1
			NSLog(@"Start reading NMEA on device file %@", dev);
#endif	
			file=[[NSFileHandle fileHandleForReadingAtPath:dev] retain];
			if(!file)
				{
				NSLog(@"was not able to open device file %@", dev);
				// create an error object!
				[[m delegate] locationManager:m didFailWithError:nil];
				return;
				}
			managers=[[NSMutableArray arrayWithObject:m] retain];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(_dataReceived:)
														 name:NSFileHandleReadCompletionNotification 
													   object:file];	// make us see notifications
#if 1
			NSLog(@"waiting for data on %@", dev);
#endif
			modes=[[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil] retain];
			[file readInBackgroundAndNotifyForModes:modes];	// and trigger notifications
			startW2SG=0;
			// power on GPS receiver and antenna
			system("echo 2800000 >/sys/devices/platform/reg-virt-consumer.5/max_microvolts && echo 2800000 >/sys/devices/platform/reg-virt-consumer.5/min_microvolts");
			[self performSelector:@selector(_didNotStart) withObject:nil afterDelay:5.0];	// times out if we did not receive NMEA records
			return;
		}
	if([managers indexOfObjectIdenticalTo:m] != NSNotFound)
		return;	// already started
	[managers addObject:m];
}

+ (void) unregisterManager:(CLLocationManager *) m
{
#if 1
	NSLog(@"unregisterManager: %@", m);
#endif
	[managers removeObjectIdenticalTo:m];
	if(managers && [managers count] == 0)
		{ // was last consumer; stop GPS receiveer
			[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel startup timer
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSFileHandleReadCompletionNotification
														  object:file];	// don't observe any more
			[file closeFile];
#if 1
			NSLog(@"Location: file closed");
#endif
			[file release];
			file=nil;
			[managers release];
			managers=nil;		
			[modes release];
			modes=nil;		
			[newLocation release];
			newLocation=nil;
			[newHeading release];
			newHeading=nil;
			[satelliteTime release];
			satelliteTime=nil;
			[satelliteInfo release];
			satelliteInfo=nil;
			// send a power down impulse
			// FIXME: must make sure that we really have started
			// power off antenna
			system("echo 0 >/sys/devices/platform/reg-virt-consumer.5/max_microvolts && echo 0 >/sys/devices/platform/reg-virt-consumer.5/min_microvolts");
		}
}

+ (void) _processNMEA183:(NSString *) line;
{ // process NMEA183 record (components separated by ",")
	NSArray *a=[line componentsSeparatedByString:@","];
	NSString *cmd=[a objectAtIndex:0];
	CLLocation *oldLocation=[[newLocation copy] autorelease];	// save a copy
	BOOL didUpdateLocation=NO;
	BOOL didUpdateHeading=NO;
	NSEnumerator *e;
	CLLocationManager *m;
	e=[managers objectEnumerator];
	while((m=[e nextObject]))
		{ // notify all CLLocationManager instances
			id <CLLocationManagerDelegate> delegate=[m delegate];
			NS_DURING
				[(NSObject *) delegate locationManager:m didReceiveNMEA:line];
			NS_HANDLER
				; // ignore
			NS_ENDHANDLER
		}
	if(!newLocation)
		newLocation=[CLLocation new];
#if 0
	NSLog(@"a=%@", a);
#endif
	[newLocation->timestamp release];
	newLocation->timestamp=[NSDate new];			// now (as seen by system time)
	if(newHeading)
		{
		[newHeading->timestamp release];
		newHeading->timestamp=[newLocation->timestamp retain];		// now (as seen by system time)
		}
	if([cmd isEqualToString:@"$GPRMC"])
		{ // minimum recommended navigation info (this is mainly used by CLLocation)
			NSString *ts=[NSString stringWithFormat:@"%@:%@", [a objectAtIndex:9], [a objectAtIndex:1]];	// combine fields
			[satelliteTime release];
			satelliteTime=[NSCalendarDate dateWithString:ts calendarFormat:@"%d%m%y:%H%M%S.%F"];	// parse
#if 0
			NSLog(@"ts=%@ -> time=%@", ts, satelliteTime);
#endif
			satelliteTime=[NSDate dateWithTimeIntervalSinceReferenceDate:[satelliteTime timeIntervalSinceReferenceDate]];	// remove formatting
			[satelliteTime retain];				// keep alive
			if([[a objectAtIndex:2] isEqualToString:@"A"])	// A=Active, V=Void
				{ // update data
					float pos;
					int deg;
					// if enabled we could sync the clock...
					//   sudo(@"date -u '%@'", [time description]);
					//   /sbin/hwclock --systohc
					pos=[[a objectAtIndex:3] floatValue];		// ddmm.mmmmm (degrees + minutes)
					deg=((int) pos)/100;
					newLocation->coordinate.latitude=deg+(pos-100.0*deg)/60.0;
					if([[a objectAtIndex:4] isEqualToString:@"S"])
						newLocation->coordinate.latitude= -newLocation->coordinate.latitude;
					pos=[[a objectAtIndex:5] floatValue];		// ddmm.mmmmm (degrees + minutes)
					deg=((int) pos)/100;
					newLocation->coordinate.longitude=deg+(pos-100.0*deg)/60.0;
					if([[a objectAtIndex:6] isEqualToString:@"E"])
						newLocation->coordinate.longitude= -newLocation->coordinate.longitude;
					newLocation->speed=[[a objectAtIndex:7] floatValue]*(1852.0/3600.0);	// convert knots (sea miles per hour) to m/s
					newLocation->course=[[a objectAtIndex:8] floatValue];
					didUpdateLocation=YES;
					if(!newHeading)
						newHeading=[CLHeading new];
					newHeading->trueHeading=newLocation->course;
					// and read the compass (if available)
					didUpdateHeading=YES;
#if 0
					NSLog(@"ddmmyy=%@", [a objectAtIndex:9]);
					NSLog(@"hhmmss.sss=%@", [a objectAtIndex:1]);	// hhmmss.sss
//					NSLog(@"ts=%@ -> %@", ts, time);	// satellite time
					NSLog(@"lat=%@ %@ -> %f", [a objectAtIndex:3], [a objectAtIndex:4], [newLocation coordinate].latitude);	// llmm.ssssN
					NSLog(@"long=%@ %@ -> %f", [a objectAtIndex:5], [a objectAtIndex:6], [newLocation coordinate].longitude);	// lllmm.ssssE
					NSLog(@"knots=%@", [a objectAtIndex:7]);
					NSLog(@"deg=%@", [a objectAtIndex:8]);
					// we should smooth velocity with a time constant > 10 seconds
					// we can also reduce the time constant for higher speed
#endif
				}
			else
				{
				newLocation->horizontalAccuracy=-1.0;
				newLocation->verticalAccuracy=-1.0;					
				didUpdateLocation=YES;
				}
		}
	else if([cmd isEqualToString:@"$GPGSA"])
		{ // satellite info
			NSMutableDictionary *d;
			int i;
			e=[satelliteInfo objectEnumerator];
			// check mode B for no fix, 2D fix, 3D to control verticalAccuracy
			if([[a objectAtIndex:16] length] > 0)
				{
				newLocation->horizontalAccuracy=[[a objectAtIndex:16] floatValue];		// HDOP horizontal precision
				newLocation->verticalAccuracy==[[a objectAtIndex:17] floatValue];		// VDOP vertical precision				
				didUpdateLocation=YES;
				}
			while((d=[e nextObject]))
				[d setObject:[NSNumber numberWithBool:NO] forKey:@"used"];	// clear
			for(i=0; i<12; i++)
				{ // check which satellites are used for a position fix
				int sat=[[a objectAtIndex:3+i] intValue];
				if(sat == 0) continue;
				e=[satelliteInfo objectEnumerator];
				while((d=[e nextObject]))
					{
					if([[d objectForKey:@"PRN"] intValue] == sat)
						{
						[d setObject:[NSNumber numberWithBool:YES] forKey:@"used"];	// used in position fix
						continue;	// found
						}
					}
				}
		}
	else if([cmd isEqualToString:@"$GPGSV"])
		{ // satellites in view (might need several messages to get a full list)
			int i;
			const int satPerRecord=4;	// there may be less records!
			const int entriesPerSat=4;
			int sat=satPerRecord*([[a objectAtIndex:2] intValue]-1);	// first satellite (index starting at 0 while NMEA starts at 1)
			numVisibleSatellites=[[a objectAtIndex:3] intValue];
			if(sat >= 0 && sat < numVisibleSatellites)
				{ // record is ok
					if(!satelliteInfo)
						satelliteInfo=[[NSMutableArray alloc] initWithCapacity:satPerRecord*numVisibleSatellites];
					else
						[satelliteInfo removeObjectsInRange:NSMakeRange(numVisibleSatellites, [satelliteInfo count]-numVisibleSatellites)];
					while([satelliteInfo count] < numVisibleSatellites)
						[satelliteInfo addObject:[NSMutableDictionary dictionaryWithCapacity:entriesPerSat]];	// create more entries
#if 0
					NSLog(@"#S visible=%d", numVisibleSatellites);
#endif
					for(i=0; i<satPerRecord && sat < numVisibleSatellites; i++)
						{ // 4 entries per satellite
							NSMutableDictionary *s=[satelliteInfo objectAtIndex:sat++];
							[s setObject:[a objectAtIndex:4+entriesPerSat*i] forKey:@"PRN"];
							[s setObject:[a objectAtIndex:5+entriesPerSat*i] forKey:@"elevation"];	// use intValue - 00-90 (can also be negative!)
							[s setObject:[a objectAtIndex:6+entriesPerSat*i] forKey:@"azimuth"];	// use intValue - 000-359
							[s setObject:[a objectAtIndex:7+entriesPerSat*i] forKey:@"SNR"];		// use intValue - can be @""
						}
				}
			else
				NSLog(@"bad NMEA: %@", line);
		}
	else if([cmd isEqualToString:@"$GPGGA"])
		{ // more location info (e.g. altitude above geoid)
			numReliableSatellites=[[a objectAtIndex:7] intValue];	// # satellites being received
#if 0
			NSLog(@"#S received=%d", numSatellites);
#endif
			// FIXME: reports 0 if we have no satellites
			if([[a objectAtIndex:8] length] > 0)
				{
				newLocation->horizontalAccuracy=[[a objectAtIndex:8] floatValue];
				// check for altitude units
				if(numReliableSatellites > 3)
					{
					newLocation->altitude=[[a objectAtIndex:9] floatValue];
					newLocation->verticalAccuracy=10.0;										
					}
				else
					newLocation->verticalAccuracy=-1.0;
#if 0
				NSLog(@"Q=%@", [a objectAtIndex:6]);	// quality
				NSLog(@"Hdil=%@", [a objectAtIndex:8]);	// horizontal dilution = precision?
				NSLog(@"Alt=%@%@", [a objectAtIndex:9], [a objectAtIndex:10]);	// altitude + units (meters)
				// calibrate/compare with Barometer data
#endif
				}
			didUpdateLocation=YES;
		}
	else if([cmd isEqualToString:@"$PSRFTXT"])
		{ // SIRF
		// ignore
		}
	else
		{
#if 1
		NSLog(@"unrecognized %@", cmd);
#endif
		}
	if(didUpdateLocation || didUpdateHeading)
		{ // notify interested delegates
		[newLocation->timestamp release];
		newLocation->timestamp=[NSDate new];			// now (as seen by system time)
		if(newHeading)
			{
			[newHeading->timestamp release];
			newHeading->timestamp=[newLocation->timestamp retain];		// now (as seen by system time)
			}
		e=[managers objectEnumerator];
		while((m=[e nextObject]))
			{ // notify all CLLocationManager instances
				id <CLLocationManagerDelegate> delegate=[m delegate];
				// check for desiredAccuracy
				// check for distanceFilter
				if(didUpdateLocation && [delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
					{
					NS_DURING
						[delegate locationManager:m didUpdateToLocation:newLocation fromLocation:oldLocation];
					NS_HANDLER
						; // ignore
					NS_ENDHANDLER
					}
				if(didUpdateHeading && [delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)])
					{
					NS_DURING
						[delegate locationManager:m didUpdateHeading:newHeading];
					NS_HANDLER
						; // ignore
					NS_ENDHANDLER
					}
			}
		}
}

+ (void) _parseNMEA183:(NSData *) line;
{ // we have received a new data block from the serial line
	NSString *s=[[[NSString alloc] initWithData:line encoding:NSASCIIStringEncoding] autorelease];
	NSArray *lines;
	int l;
#if 0
	NSLog(@"data=%@", line);
	NSLog(@"string=%@", s);
#endif
	if(lastChunk)
		s=[lastChunk stringByAppendingString:s];	// append to last chunk
	lines=[s componentsSeparatedByString:@"\n"];	// split into lines
	for(l=0; l<[lines count]-1; l++)
		{ // process lines except last chunk
			s=[[lines objectAtIndex:l] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
			if(![s hasPrefix:@"$"])
				continue;	// invalid start
			if([s characterAtIndex:[s length]-3] == '*')
				{ // assume *hh\n
					// extract hh and calculate/verify checksum
					s=[s substringWithRange:NSMakeRange(0, [s length]-3)];	// get relevant parts - strip off *hh
					// get bytes and calculate checksum
					// check checksum
				}
#if 0
			NSLog(@"NMEA: %@", s);
#endif
			NS_DURING	// protect against problems in delegates
				[self _processNMEA183:s];
			NS_HANDLER
				NSLog(@"Exception during _processNMEA183: %@", localException);
			NS_ENDHANDLER
		}
#if 0
	NSLog(@"string=%@", s);
#endif
	[lastChunk release];
	lastChunk=[[lines lastObject] retain];
}

+ (void) _dataReceived:(NSNotification *) n;
{
#if 0
	NSLog(@"_dataReceived %@", n);
#endif
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel startup timer
	[self _parseNMEA183:[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]];	// parse data as line
	[[n object] readInBackgroundAndNotifyForModes:modes];	// and trigger more notifications
	[self performSelector:@selector(_didNotStart) withObject:nil afterDelay:5.0];	// times out if we do not receive any further NMEA records
}

@end

#endif

// FIXME: quite inefficient - this means that the daemon sends a DO message and we ignore it...
// i.e. we should control the daemon that we do (not) want to see this more than once

@implementation NSObject (CLLocationManagerDelegate)

- (void) locationManager:(CLLocationManager *) mngr didReceiveNMEA:(NSString *) str;
{
	// [_server dontSendNMEAtoManager:mngr];
	return;
}

@end

// EOF
