//
//  CoreLocation.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <AppKit/NSApplication.h>	// for NSEventTrackingRunLoopMode

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

@implementation CLRegion

- (CLLocationCoordinate2D) center; { return center; }
- (NSString *) identifier; { return identifier; }
- (CLLocationDistance) radius; { return radius; }

- (BOOL) containsCoordinate:(CLLocationCoordinate2D) coordinate;
{
	return NO;
}

- (void) dealloc;
{
	[identifier release];
	[super dealloc];
}

- (id) initCircularRegionWithCenter:(CLLocationCoordinate2D) cent radius:(CLLocationDistance) rad identifier:(NSString *) ident;
{
	if((self=[super init]))
		{
		center=cent;
		radius=rad;
		identifier=[ident retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	CLRegion *c=[CLRegion alloc];
	if(c)
		{
		c->center=center;
		c->radius=radius;
		c->identifier=[identifier retain];
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

@implementation CLHeading

// init...

- (CLLocationDirection) headingAccuracy; { return headingAccuracy; }
- (CLLocationDirection) magneticHeading; { return magneticHeading; }
- (NSDate *) timestamp; { return timestamp; }
- (CLLocationDirection) trueHeading; { return trueHeading; }
- (CLHeadingComponentValue) x; { return x; }
- (CLHeadingComponentValue) y; { return y; }
- (CLHeadingComponentValue) z; { return z; }

- (void) dealloc
{
	[timestamp release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"magneticHeading %lg trueHeading %lg accuracy %lg x %lg y %lg z %lg a %lg @ %@",
			magneticHeading, trueHeading, headingAccuracy,
			x, y, z,
			headingAccuracy, timestamp];
}

- (id) copyWithZone:(NSZone *) zone
{
	CLHeading *c=[CLHeading alloc];
	if(c)
		{
		c->headingAccuracy=headingAccuracy;
		c->magneticHeading=magneticHeading;
		c->trueHeading=trueHeading;
		c->x=x;
		c->y=y;
		c->z=z;
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

@interface CLLocationManager (GPSNMEA)
+ (void) registerManager:(CLLocationManager *) m;
+ (void) unregisterManager:(CLLocationManager *) m;
+ (void) _processNMEA183:(NSString *) line;	// process complete line
+ (void) _parseNMEA183:(NSData *) line;	// process data fragment
+ (void) _dataReceived:(NSNotification *) n;
@end

static CLLocation *newLocation;
static CLHeading *newHeading;

@implementation CLLocationManager

- (id <CLLocationManagerDelegate>) delegate; { return delegate; }
- (CLLocationAccuracy) desiredAccuracy; { return desiredAccuracy; }
- (CLLocationDistance) distanceFilter; { return distanceFilter; }
- (CLHeading *) heading; { return newHeading; }
- (CLLocationDegrees) headingFilter; { return headingFilter; }
// FIXME: ask UIDevice? No: this variable indicates how the delegate wants to get the heading reported
- (CLDeviceOrientation) headingOrientation; { return headingOrientation; }
- (CLLocation *) location; { return newLocation; }
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
	// if we have a compass
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

- (id) init
{
	NSLog(@"init");
	if((self=[super init]))
		{
		}
	return self;
}

- (void) dealloc
{
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
	// if first call or not permanently enabled, ask user in a nonmodal window "<App> wants to use your current location"
	// there is a checkbox to disable this message (probably stored in the User Defaults of the current process?)
	// it also asks for command line tools (w/o Info.plist!)
	// postpone the registration until user confirms
	[CLLocationManager registerManager:self];
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
	[CLLocationManager unregisterManager:self];
}

@end

static int numReliableSatellites;
static int numVisibleSatellites;
static NSDate *satelliteTime;
static NSMutableArray *satelliteInfo;

@implementation CLLocationManager (Extensions)

+ (int) numberOfReceivedSatellites;
{ // count all satellites with SNR > 0
	NSEnumerator *e=[satelliteInfo objectEnumerator];
	NSDictionary *s;
	int numReceivedSatellites=0;
	while((s=[e nextObject]))
		if([[s objectForKey:@"SNR"] intValue] > 0)
			numReceivedSatellites++;
	return numReceivedSatellites;
}

+ (int) numberOfReliableSatellites;
{
	return numReliableSatellites;	
}

+ (int) numberOfVisibleSatellites;
{
	return numVisibleSatellites;
}

+ (CLLocationSource) source;
{
	// this is very GTA04 specific
	if([[NSString stringWithContentsOfFile:@"/sys/devices/virtual/gpio/gpio144/value"] boolValue])
		return CLLocationSourceGPS | CLLocationSourceExternalAnt;
	return CLLocationSourceGPS;
}

+ (NSDate *) satelliteTime
{
	return satelliteTime;
}

+ (NSArray *) satelliteInfo
{
	return satelliteInfo;
}

+ (void) WLANseen:(NSString *) bssid;
{
	
}

+ (void) WWANseen:(NSString *) cellid;
{
	
}

@end

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
	system("echo 0 >/sys/devices/virtual/gpio/gpio145/value; echo 1 >/sys/devices/virtual/gpio/gpio145/value; stty 9600 </dev/ttyO1");	// give a start/stop impulse
	[self performSelector:_cmd withObject:nil afterDelay:++startW2SG > 4?30.0:5.0];	// we did not receive NMEA records
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
			// get this from some *system wide* user default
			NSString *dev=[[NSUserDefaults standardUserDefaults] stringForKey:@"NMEAGPSSerialDevice"];	// e.g. /dev/ttyO1 or /dev/cu.usbmodem1d11
			if(!dev)
				{
#ifdef __mySTEP__
				dev=@"/dev/ttyO1";	// Linux: serial interface for USB receiver
#else
				dev=@"/dev/cu.BT-348_GPS-Serialport-1";	// Mac OS X: serial interface for NMEA receiver
#endif
				}
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
	if([managers count] == 0)
		{ // stop GPS receiveer
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSFileHandleReadCompletionNotification
														  object:file];	// don't observe any more
			[file closeFile];
#if 1
			NSLog(@"Location: file closed");
#endif
			[file release];
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
	if(!newLocation)
		newLocation=[CLLocation new];
#if 0
	NSLog(@"a=%@", a);
#endif
	// we may add some more info to this notification!
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CLLocation.NMEA183" object:self userInfo:[NSDictionary dictionaryWithObject:line forKey:@"CLLocation.NMEA183.String"]];
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
			NSEnumerator *e=[satelliteInfo objectEnumerator];
			NSMutableDictionary *d;
			int i;
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
		NSEnumerator *e;
		CLLocationManager *m;
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
#if 1
			NSLog(@"NEMA: %@", s);
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

@implementation CLPlacemark

// for a description see http://www.icodeblog.com/2009/12/22/introduction-to-mapkit-in-iphone-os-3-0-part-2/

- (NSDictionary *) addressDictionary; { return addressDictionary; }

- (CLLocationCoordinate2D) coordinate; { return coordinate; }

- (void) setCoordinate:(CLLocationCoordinate2D) pos;
{ // checkme: does this method exist?
	coordinate=pos;
}

- (NSString *) subtitle;
{
	return @"Subtitle";	
}

- (NSString *) title;
{
	return @"Placemmark";
}

- (NSString *) thoroughfare; { return [addressDictionary objectForKey:@"Throughfare"]; }
- (NSString *) subThoroughfare; { return [addressDictionary objectForKey:@"SubThroughfare"]; }
- (NSString *) locality; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) subLocality; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) administrativeArea; { return [addressDictionary objectForKey:@"?"]; }
- (NSString *) subAdministrativeArea; { return [addressDictionary objectForKey:@"SubAdministrativeArea"]; }
- (NSString *) postalCode; { return [addressDictionary objectForKey:@"ZIP"]; }
- (NSString *) country; { return [addressDictionary objectForKey:@"Country"]; }
- (NSString *) countryCode; { return [addressDictionary objectForKey:@"CountryCode"]; }

- (id) initWithPlacemark:(CLPlacemark *) placemark;
{ // just copy...
	return [self initWithCoordinate:[placemark coordinate] addressDictionary:[placemark addressDictionary]];
}

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord addressDictionary:(NSDictionary *) addr;
{
	if((self=[super init]))
		{
		coordinate=coord;
		addressDictionary=[addr retain];	// FIXME: or copy?
		}
	return self;
}

- (void) dealloc
{
	[addressDictionary release];
	[super dealloc];
}

@end

@implementation CLGeocoder

- (void) cancelGeocode;
{
	if(connection)
		[connection cancel];
	[connection release];
	connection=nil;
}

- (void) dealloc
{
	[self cancelGeocode];
	[handler release];
	[super dealloc];
}

- (BOOL) isGeocoding;
{
	return connection != nil;
}

- (void) reverseGeocodeLocation:(CLLocation *) location completionHandler:(CLGeocodeCompletionHandler) h;
{ //	http://developers.cloudmade.com/wiki/geocoding-http-api/Documentation#Reverse-Geocoding-httpcm-redmine01-datas3amazonawscomfiles101117091610_icon_beta_orangepng
	if(!connection)
		{ // build query and start
			handler=[h retain];
			// use reverse geocoding api:
			// read resulting property list
			// make asynchronous fetch and report result through [handler performSelectorWithObject:andObject:]
		}
}

- (void) geocodeAddressString:(NSString *) address inRegion:(CLRegion *)region completionHandler:(CLGeocodeCompletionHandler) h;
{ // http://developers.cloudmade.com/projects/show/geocoding-http-api
	if(!connection)
		{ // build query and start
			handler=[h retain];
			if(region)
				{
				// add to query
				}
			// FIXME: encode blanks as + and + as %25 etc.
			NSString *url=[NSString stringWithFormat:@"http://geocoding.cloudmade.com/%@/geocoding/v2/find.plist?query=%@", @"8ee2a50541944fb9bcedded5165f09d9", address];
			// make asynchronous fetch and report result through [handler performSelectorWithObject:andObject:]
			NSDictionary *dict=[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:url]];
		}
}

- (void) geocodeAddressString:(NSString *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	[self geocodeAddressString:address inRegion:nil completionHandler:h];
}

- (void) geocodeAddressDictionary:(NSDictionary *) address completionHandler:(CLGeocodeCompletionHandler) h;
{
	NSMutableString *str=[NSMutableString stringWithCapacity:50];
	// add components from address (if defined)
	[str appendFormat:@"133 Fleet street, London, UK"];
	[self geocodeAddressString:str completionHandler:h];
}

@end

// EOF
