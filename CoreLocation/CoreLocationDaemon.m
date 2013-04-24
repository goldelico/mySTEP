//
//  CoreLocationDaemon.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 18.09.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CoreLocationDaemon.h"


int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	CoreLocationDaemon *d=[CoreLocationDaemon new];	// create daemon
    NSConnection *theConnection=[NSConnection new];
#if 1
    NSLog(@"Creating connection for %@...", SERVER_ID);
#endif
    [theConnection setRootObject:d];
    if([theConnection registerName:SERVER_ID] == NO)
		{
		NSLog(@"Failed to register name %@\n", SERVER_ID);
		return 1;
		}	
	// process events
#if 1
    NSLog(@"Running the loop...");
#endif
	[[NSRunLoop currentRunLoop] run];	// run until all input sources have been removed (after GPS is shut down)
#if 1
    NSLog(@"Exiting daemon for %@", SERVER_ID);
#endif
	[d release];
    [pool release];
    return 0;	
}

@implementation CoreLocationDaemon

// special code for the W2SG0004 on the GTA04 board

static int startW2SG;

- (NSString *) _device
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

- (void) _didNotStart
{ // timeout - try to retrigger
#if 1
	NSLog(@"did not yet receive NMEA");
#endif
	if(startW2SG == 3)
		{ // permanent problem
			NSError *error=[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil];
			NSEnumerator *e=[managers objectEnumerator];
			// FIXME: define a formal prototol (e.g. -delegate) so that we don't need to ask the client for method signatures!
			CLLocationManager *m;
			NSLog(@"GPS receiver not working");
			while((m=[e nextObject]))
				{ // notify all CLLocationManager instances
					id <CLLocationManagerDelegate> delegate;
					NS_DURING
						delegate=[m delegate];
						if([delegate respondsToSelector:@selector(locationManager:didFailWithError:)])
							[delegate locationManager:m didFailWithError:error];
					NS_HANDLER
						[self unregisterManager:m]; // communication failure
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

- (void) registerManager:(CLLocationManager *) m
{
#if 1
	NSLog(@"Daemon: registerManager: %@", m);
#endif
//	NSAssert([m isKindOfClass:[CLLocationManager class]], @"register CLLocationManagers only");
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
			NSLog(@"power on GPS");
			system("echo 2800000 >/sys/devices/platform/reg-virt-consumer.5/max_microvolts && echo 2800000 >/sys/devices/platform/reg-virt-consumer.5/min_microvolts");
			[self performSelector:@selector(_didNotStart) withObject:nil afterDelay:5.0];	// times out if we did not receive NMEA records
			return;
		}
#if 1
	else
		NSLog(@"already running");
#endif
	if([managers indexOfObjectIdenticalTo:m] != NSNotFound)
		return;	// already started
	[managers addObject:m];
}

- (void) unregisterManager:(CLLocationManager *) m
{
#if 1
	NSLog(@"Daemon unregisterManager: %@", m);
#endif
	NSAssert([m isKindOfClass:[CLLocationManager class]], @"register CLLocationManagers only");
	[managers removeObjectIdenticalTo:m];
	if(managers && [managers count] == 0)
		{ // was last consumer; stop GPS receiver and daemon
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
			NSLog(@"power off GPS");
			system("echo 0 >/sys/devices/platform/reg-virt-consumer.5/max_microvolts && echo 0 >/sys/devices/platform/reg-virt-consumer.5/min_microvolts");
			exit(0);	// last client has unregistered
		}
}

- (void) _processNMEA183:(NSString *) line;
{ // process NMEA183 record (components separated by ",")
	NSArray *a=[line componentsSeparatedByString:@","];
	NSString *cmd=[a objectAtIndex:0];
	CLLocation *oldLocation=[[newLocation copy] autorelease];	// save a copy
	BOOL didUpdateLocation=NO;
	BOOL didUpdateHeading=NO;
	NSEnumerator *e;
	CLLocationManager *m;
#if 1
	NSLog(@"_processNMEA183: %@", line);
#endif
#if 0
	NSLog(@"managers: %@", managers);
#endif
	e=[managers objectEnumerator];
	while((m=[e nextObject]))
		{ // notify all CLLocationManager instances
			id <CLLocationManagerDelegate> delegate;
			NS_DURING
#if 0
			NSLog(@"manager: %@", m);
#endif
			delegate=[m delegate];
				[(NSObject *) delegate locationManager:m didReceiveNMEA:line];
			NS_HANDLER
				[self unregisterManager:m]; // communication failure
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
		{ // SIRF message
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
					id <CLLocationManagerDelegate> delegate;
					// check for desiredAccuracy
					// check for distanceFilter
					NS_DURING
						delegate=[m delegate];
						if(didUpdateLocation && [delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
							[delegate locationManager:m didUpdateToLocation:newLocation fromLocation:oldLocation];
						if(didUpdateHeading && [delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)])
							[delegate locationManager:m didUpdateHeading:newHeading];
					NS_HANDLER
						[self unregisterManager:m]; // communication failure
					NS_ENDHANDLER
				}
		}
}

- (void) _parseNMEA183:(NSData *) line;
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
			NSLog(@"NMEA: %@", s);
#endif
			[self _processNMEA183:s];
		}
#if 0
	NSLog(@"string=%@", s);
#endif
	[lastChunk release];
	lastChunk=[[lines lastObject] retain];
}

- (void) _dataReceived:(NSNotification *) n;
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
