//
//  CoreLocation.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

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
	return [NSString stringWithFormat:@"<%.lf, %.lf> +/- %.lfm (speed %.lf kph / heading %.lf) @ %@",
			coordinate.latitude, coordinate.longitude,
			horizontalAccuracy,
			speed,
			course,
			timestamp];
}

- (CLLocationDistance) distanceFromLocation:(const CLLocation *) loc;
{
	// Großkreis berechnen
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
	return [NSString stringWithFormat:@"magneticHeading %.lf trueHeading %.lf accuracy %.lf x %.lf y %.lf z %.lf @ %@",
			magneticHeading, trueHeading, headingAccuracy,
			x, y, z,
			headingAccuracy];
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

@implementation CLLocationManager

- (id <CLLocationManagerDelegate>) delegate; { return delegate; }
- (CLLocationAccuracy) desiredAccuracy; { return desiredAccuracy; }
- (CLLocationDistance) distanceFilter; { return distanceFilter; }
- (CLHeading *) heading; { return heading; }
- (CLLocationDegrees) headingFilter; { return headingFilter; }
- (CLDeviceOrientation) headingOrientation; { return headingOrientation; }
- (CLLocation *) location; { return location; }
- (CLLocationDistance) maximumRegionMonitoringDistance; { return maximumRegionMonitoringDistance; }
- (NSSet *) monitoredRegions; { return [[NSUserDefaults standardUserDefaults] objectForKey:@"_CoreLocationManagerRegions"]; }	// persistent by application (!)
- (NSString *) purpose; { return purpose; }

- (void) setDelegate:(id <CLLocationManagerDelegate>) d; { delegate=d; }
- (void) setDesiredAccuracy:(CLLocationAccuracy) acc; { desiredAccuracy=acc; }
- (void) setDistanceFilter:(CLLocationDistance) filter; { distanceFilter=filter; }
- (void) setHeadingFilter:(CLLocationDegrees) filter; { headingFilter=filter; }
- (void) setHeadingOrientation:(CLDeviceOrientation) orient; { headingOrientation=orient; }
- (void) setPurpose:(NSString *) string; { [purpose autorelease]; purpose=[string copy]; }

+ (BOOL) headingAvailable; {
	return NO;
}

+ (BOOL) locationServicesEnabled {
	return YES;
}

+ (BOOL) regionMonitoringAvailable {
	return NO;
}

+ (BOOL) regionMonitoringEnabled { // system setting
	return NO;
}

+ (BOOL) significantLocationChangeMonitoringAvailable { // system setting
	return NO;
}

- (id) init
{
	if((self=[super init]))
		{
		heading=[CLHeading new];
		location=[CLLocation new];
		}
	return self;
}

- (void) dealloc
{
	[self stopMonitoringSignificantLocationChanges];
	[self stopUpdatingHeading];
	[self stopUpdatingLocation];
	[heading release];
	[location release];
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

// we should  integrate sensor data from GPS, barometric Altimeter, Gyroscope, Accelerometer, and Compass 
// though a Kalman-Bucy filter

// private methods to handle NMEA data from a serial interface

@implementation CLLocationManager (GPSNMEA)

// this should be a system-wide service i.e. access through DO!

// FIXME: send location updates
// FIXME: send heading updates

static NSMutableArray *managers;	// list of all managers
static CLLocation *oldLocation;		// previous location
static NSString *lastChunk;
static int numSatellites;
static int numVisibleSatellites;
static BOOL noSatellite;
static NSFileHandle *file;

+ (void) registerManager:(CLLocationManager *) m
{
	if(![self locationServicesEnabled])
		return;	// ignore
	if(!managers)
		{ // set up GPS receiver and wait for first fix
			NSString *dev=@"/dev/cu.BT-348_GPS-Serialport-1";	//serial interface for NMEA receiver
			// use /dev/ttyS2 on Openmoko Beagle Hybrid
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
			[file readInBackgroundAndNotify];	// and trigger notifications
			return;
		}
	if([managers indexOfObjectIdenticalTo:m] != NSNotFound)
		return;	// already started
	[managers addObject:m];
}

+ (void) unregisterManager:(CLLocationManager *) m
{
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
			[oldLocation release];
			oldLocation=nil;
		}
}

+ (void) _processNMEA183:(NSString *) line;
{ // process NMEA183 record (components separated by ",")
	NSArray *a=[line componentsSeparatedByString:@","];
	NSString *cmd=[a objectAtIndex:0];
	CLLocation *newLocation=nil;
#if 0
	NSLog(@"a=%@", a);
#endif
	if([cmd isEqualToString:@"$GPRMC"])
		{ // minimum recommended navigation info (this is mainly used by SYSLocation)
			noSatellite=![[a objectAtIndex:2] isEqualToString:@"A"];	// A=Ok, V=receiver warning
			if(!noSatellite)
				{ // update time and timestamp
					NSString *ts=[NSString stringWithFormat:@"%@:%@", [a objectAtIndex:9], [a objectAtIndex:1]];
					float pos;
					int deg;
#if 0
					NSDate *time=nil;	// satellite time...
					[time release];
					time=[NSCalendarDate dateWithString:ts calendarFormat:@"%d%m%y:%H%M%S.%F"];	// parse
					time=[NSDate dateWithTimeIntervalSinceReferenceDate:[time timeIntervalSinceReferenceDate]];	// remove formatting
					[time retain];				// keep alive
#endif
					newLocation=[CLLocation new];
					newLocation->timestamp=[NSDate new];		// now (as seen by system time)
					// if enabled we could sync the clock...
					//   sudo(@"date -u '%@'", [c description]);
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
					// speed precision - only if 4 sats and more and speed > 10 km/h?
					// should we also update the heading object?
#if 1
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
				numSatellites=0;
		}
	else if([cmd isEqualToString:@"$GPGSA"])
		{ // satellite info
			
		}
	else if([cmd isEqualToString:@"$GPGSV"])
		{ // satellites in view (might have several messages for full list)
			numVisibleSatellites=[[a objectAtIndex:3] intValue];
#if 1
			NSLog(@"#S visible=%d", numVisibleSatellites);
#endif
			// we could parse the info into a NSArray or NSDictionary (indexed by Sat#)
		}
	else if([cmd isEqualToString:@"$GPGGA"])
		{ // more location info (e.g. altitude above geoid)
			numSatellites=[[a objectAtIndex:7] intValue];	// # satellites being received
#if 1
			NSLog(@"#S received=%d", numSatellites);
#endif
			if(!noSatellite)
				{ // update
					newLocation=[CLLocation new];
					// Hm... we must collect several records until we notify the delegates!!!
					newLocation->horizontalAccuracy=[[a objectAtIndex:8] floatValue];
					// check for altitude units
					newLocation->altitude=[[a objectAtIndex:9] floatValue];
					newLocation->verticalAccuracy=10.0;					
#if 1
					NSLog(@"Q=%@", [a objectAtIndex:6]);	// quality
					NSLog(@"Hdil=%@", [a objectAtIndex:8]);	// horizontal dilution = precision?
					NSLog(@"Alt=%@%@", [a objectAtIndex:9], [a objectAtIndex:10]);	// altitude + units (meters)
#endif
				}
			else
				{
					newLocation->horizontalAccuracy=-1.0;
					newLocation->verticalAccuracy=-1.0;					
				}
		}
	else
		{
#if 1
		NSLog(@"unrecognized %@", cmd);
#endif
		return;	// unrecognized command
		}
	if(!noSatellite)
		{
		CLLocationManager *m;
		NSEnumerator *e=[managers objectEnumerator];
		while((m=[e nextObject]))
			{ // notify all CLLocationManager instances
			// check for desiredAccuracy
			// check for distanceFilter
				[[m delegate] locationManager:self didUpdateToLocation:newLocation fromLocation:oldLocation];
			}
		}
	[oldLocation release];
	oldLocation=newLocation;	// was freshly allocated
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
				}
//			[[NSNotificationCenter defaultCenter] postNotificationName:SYSLocationNMEA183Notification object:s];	// notify any listener
#if 1
			NSLog(@"NEMA: %@", s);
#endif
			[self _processNMEA183:s];
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
	[self _parseNMEA183:[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]];	// parse data as line
	[[n object] readInBackgroundAndNotify];	// and trigger more notifications
}

@end
