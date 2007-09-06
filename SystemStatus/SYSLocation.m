/* 
GPS driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <SystemStatus/SYSLocation.h>
#import <SystemStatus/SYSDevice.h>
#include <signal.h>

// a GPS card is accessed through the serial_cs.o driver module

/*
 from http://www.baumbach-web.de/prog_psinmea.html
 
 Baudrate	4800
 Bits		8 (Bit 7 is 0)
 Stopbits	1 or 2
 Parity		none
 Handshake	none
 
 Communication is by datablocks beginning with '$' and ending with CR/LF
 e.g. $GPRMC,154232,A,2758.612,N,08210.515,W,085.4,084.4,230394,003.1,W*43<CR><LF>
 
 line ::= '*' address { ',' data } [ '*' hex-xor-checksum ] '\r\n'
 address ::= 'GP' char char char |
 'P' m m m { char } |
 'CCGPQ'
 data ::= { char }
 
 e.g.
 Standard GPS data:
 
 $CCGPQ,GGA<CR><LF> should return
 $--GGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh<CR><LF>
 
 UTC Time&Date:
 $CCGPQ,ZDA<CR><LF>
 $--ZDA,hhmmss.ss,xx,xx,xxxx,xx,xx*hh<CR><LF>
 
 NMEA codes of Billionton CFGPS:
 
 WASS Mode Disable
 $PSRF108,00*02
 
 WASS Mode Enable
 $PSRF108,01*03
 
 Power Save Mode Disable
 $PSRF107,0,1000,1000*3D
 
 Power Save Mode Enable
 $PSRF107,0,400,1000*08
 
 Cold Start
 $PSRF104,0,0,0,96000,237759,1946,12,4*1D
 
 Warm Start
 $PSRF104,0,0,0,96000,237759,922,12,2*28
 
 Hot Start
 $PSRF104,0,0,0,96000,237759,922,12,1*2B
 
 Typical data stream:
 
 $GPGSA,A,1,,,,,,,,,,,,,50.0,50.0,50.0*05  -- satellite info
 
 $GPRMC,000214.991,V,36000.0000,N,72000.0000,E,,,270102,,*24  -- minimum recommended navigation info (this is mainly used by SYSLocation)
 
 $GPGGA,000215.990,36000.0000,N,72000.0000,E,0,00,50.0,0.0,M,,M,,0000*40  -- more location info (e.g. altitude above geoid)
 
 $GPGSA,A,1,,,,,,,,,,,,,50.0,50.0,50.0*05  -- satellite info
 
 $GPRMC,000215.990,V,36000.0000,N,72000.0000,E,,,270102,,*24  -- minimum recommended navigation info
 
 $GPGGA,000216.990,36000.0000,N,72000.0000,E,0,00,50.0,0.0,M,,M,,0000*43
 
 $GPGSA,A,1,,,,,,,,,,,,,50.0,50.0,50.0*05  -- satellite info
 
 $GPGSV,1,1,01,01,00,000,*49  -- satellites in view
 
 Satellite Info:
 
	1 2 3                        14 15  16  17  18
	| | |                         |  |   |   |   |
 $--GSA,a,a,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x.x,x.x,x.x*hh<CR><LF>
 
 Field Number: 
 1) Selection mode
 2) Mode
 3) ID of 1st satellite used for fix
 4) ID of 2nd satellite used for fix
 ...
 14) ID of 12th satellite used for fix
 15) PDOP in meters
 16) HDOP in meters
 17) VDOP in meters
 18) checksum
 
 GSV - Satellites in view
 
	1 2 3 4 5 6 7     n
	| | | | | | |     |
 $--GSV,x,x,x,x,x,x,x,...*hh<CR><LF>
 
 Field Number: 
 1) total number of messages
 2) message number
 3) satellites in view
 4) satellite number
 5) elevation in degrees
 6) azimuth in degrees to true
 7) SNR in dB - or blank
 more satellite infos like 4)-7)
 n) checksum
 
 RMC - Recommended Minimum Navigation Information
 12
 1         2 3       4 5        6 7   8   9    10  11|
 |         | |       | |        | |   |   |    |   | |
 $--RMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,xxxx,x.x,a*hh<CR><LF>
 
 Field Number: 
 1) UTC Time
 2) Status, V = Navigation receiver warning
 3) Latitude
 4) N or S
 5) Longitude
 6) E or W
 7) Speed over ground, knots
 8) Track made good, degrees true
 9) Date, ddmmyy
 10) Magnetic Variation, degrees
 11) E or W
 12) Checksum
 
 GGA - Global Positioning System Fix Data
 Time, Position and fix related data fora GPS receiver.
 
 11
 1         2       3 4        5 6 7  8   9  10 |  12 13  14   15
 |         |       | |        | | |  |   |   | |   | |   |    |
 $--GGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh<CR><LF>
 
 Field Number: 
 1) Universal Time Coordinated (UTC)
 2) Latitude
 3) N or S (North or South)
 4) Longitude
 5) E or W (East or West)
 6) GPS Quality Indicator,
 0 - fix not available,
 1 - GPS fix,
 2 - Differential GPS fix
 7) Number of satellites in view, 00 - 12
 8) Horizontal Dilution of precision
 9) Antenna Altitude above/below mean-sea-level (geoid) 
 10) Units of antenna altitude, meters
 11) Geoidal separation, the difference between the WGS-84 earth
 ellipsoid and mean-sea-level (geoid), "-" means mean-sea-level
 below ellipsoid
 12) Units of geoidal separation, meters
 13) Age of differential GPS data, time in seconds since last SC104
 type 1 or 9 update, null field when DGPS is not used
 14) Differential reference station ID, 0000-1023
 15) Checksum
 
 */

NSString *SYSLocationInsertedNotification=@"SYSLocationInsertedNotification";	// device was inserted
NSString *SYSLocationEjectedNotification=@"SYSLocationEjectedNotification";		// device was ejected (or unplugged)
NSString *SYSLocationSuspendedNotification=@"SYSLocationSuspendedNotification";	// device was deactivated
NSString *SYSLocationResumedNotification=@"SYSLocationResumedNotification";		// device was activated
NSString *SYSLocationNMEA183Notification=@"SYSLocationNMEA183Notification";		// NMEA183 record was received

@implementation SYSLocation

+ (SYSLocation *) sharedLocation;
{
	static SYSLocation *l;
	if(!l) 
		l=[[self alloc] init];
	return l; 
}

- (NSArray *) _parseNMEA183:(NSData *) line;
{
	NSString *s=[[[NSString alloc] initWithData:line encoding:NSASCIIStringEncoding] autorelease];
#if 0
	NSLog(@"data=%@", line);
	NSLog(@"string=%@", s);
#endif
	if(![s hasPrefix:@"$"])
		return nil;	// invalid start
	if(![s hasSuffix:@"\n"])
		return nil;	// invalid end
	if([s characterAtIndex:[s length]-4] == '*')
		{ // assume *hh\n
		  // extract hh
		s=[s substringWithRange:NSMakeRange(1, [s length]-5)];	// get relevant parts - strip off *hh
																// get bytes and calculate checksum
		}
	else
		s=[s substringWithRange:NSMakeRange(1, [s length]-2)];	// get relevant parts - no checksum
#if 0
	NSLog(@"string=%@", s);
#endif
	return [s componentsSeparatedByString:@","];
}

- (void) _processNMEA183:(NSArray *) a;
{ // process NMEA183 string
	NSString *cmd=[a objectAtIndex:0];
#if 0
	NSLog(@"a=%@", a);
#endif
	if(!cmd)
		return;	// no command processed
	else if([cmd isEqualToString:@"GPRMC"])
		{ // minimum recommended navigation info (this is mainly used by SYSLocation)
		noSatellite=![[a objectAtIndex:2] isEqualToString:@"A"];	// A=Ok, V=receiver warning
		if(!noSatellite)
			{ // update time and timestamp
			NSString *ts=[NSString stringWithFormat:@"%@:%@", [a objectAtIndex:9], [a objectAtIndex:1]];
			unsigned int h, m, s;
			[time release];
			time=[NSCalendarDate dateWithString:ts calendarFormat:@"%d%m%y:%H%M%S.%F"];
			[time retain];				// keep alive
			[timeStamp autorelease];	// release previous one
			timeStamp=[NSDate date];	// now
			[timeStamp retain];			// keep alive
			sscanf([[a objectAtIndex:3] cString], "%2u%2u.%u", &h, &m, &s);
			gpsData.location.latitude=h+(m/60.0)+(s/3600.0);
			if([[a objectAtIndex:4] isEqualToString:@"S"])
				gpsData.location.latitude= -gpsData.location.latitude;
			sscanf([[a objectAtIndex:3] cString], "%3u%2u.%u", &h, &m, &s);
			gpsData.location.longitude=h+(m/60.0)+(s/3600.0);
			if([[a objectAtIndex:4] isEqualToString:@"E"])
				gpsData.location.longitude= -gpsData.location.longitude;
			gpsData.speed=[[a objectAtIndex:7] doubleValue]*(1852.0/3600.0);	// convert to m/s
			gpsData.direction=[[a objectAtIndex:8] doubleValue];
#if 1
			NSLog(@"ddmmyy=%@", [a objectAtIndex:9]);
			NSLog(@"hhmmss.sss=%@", [a objectAtIndex:1]);	// hhmmss.sss
			NSLog(@"ts=%@ -> %@", ts, time);	// satellite time
			NSLog(@"lat=%@ %@", [a objectAtIndex:3], [a objectAtIndex:4]);	// llmm.ssssN
			NSLog(@"long=%@ %@", [a objectAtIndex:5], [a objectAtIndex:6]);	// lllmm.ssssE
			NSLog(@"knots=%@", [a objectAtIndex:7]);
			NSLog(@"deg=%@", [a objectAtIndex:8]);
			// we should convert polar coords (knots,deg) into rectangular coords and smooth velocity with a time constant > 10 seconds
			// we can also reduce the time constant for higher speed
#endif
			}
		}
	else if([cmd isEqualToString:@"GPGSA"])
		{ // satellite info
		
		}
	else if([cmd isEqualToString:@"GPGSV"])
		{ // satellites in view (might have several messages for full list)
		numVisibleSatellites=[[a objectAtIndex:3] intValue];
#if 1
		NSLog(@"#S visible=%d", numVisibleSatellites);
#endif
		}
	else if([cmd isEqualToString:@"GPGGA"])
		{ // more location info (e.g. altitude above geoid)
		numSatellites=[[a objectAtIndex:7] intValue];	// # satellites being received
#if 1
		NSLog(@"#S received=%d", numSatellites);
#endif
		if(!noSatellite)
			{ // update
			precision=[[a objectAtIndex:8] floatValue];
			gpsData.location.height=[[a objectAtIndex:9] doubleValue];
#if 1
			NSLog(@"Q=%@", [a objectAtIndex:6]);	// quality
			NSLog(@"Hdil=%@", [a objectAtIndex:8]);	// horizontal dilution = precision?
			NSLog(@"Alt=%@%@", [a objectAtIndex:9], [a objectAtIndex:10]);	// altitude + units (meters)
#endif
			}
		}
}

- (void) _dataReceived:(NSNotification *) n;
{
	NSData *d;
	NSArray *cmd;
#if 0
	NSLog(@"_dataReceived %@", n);
#endif
	d=[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	// do we need to splice together data junks?
	cmd=[self _parseNMEA183:d];	// parse data as line
	if(cmd)
		{
		[self _processNMEA183:cmd];	// update internal data
		[[NSNotificationCenter defaultCenter] postNotificationName:SYSLocationNMEA183Notification object:cmd];	// notify any listener
		}
	[file readInBackgroundAndNotify];	// and trigger more notifications
}

- (void) deviceShouldLock:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Location: deviceShouldLock %@", dev);
#endif
	if(![dev isLocked] && [[dev deviceManufacturer] isEqualToString:@"CFGPS"])	// Billionton CFGPS - returns bogus card identification
		{
#if 1
		NSLog(@"GPS card found: %@", dev);
#endif
		gps=dev;
		[dev lock:YES];	// found and grab!
		[[NSNotificationCenter defaultCenter] postNotificationName:SYSLocationInsertedNotification object:self];	// notify any listener
		[dev resume];	// and enable
		}
}

- (void) deviceEjected:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Location: deviceEjected %@", dev);
#endif
	if(dev != gps)
		return;	// ignore
	gps=nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSLocationEjectedNotification object:self];	// notify any listener
}

#if 0
void sigstop(void)
{
	fprintf(stderr, "received SIGSTOP\n");
	// we probably should close/release file here
}
#endif

- (void) deviceResumed:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Location: deviceResumed %@", dev);
#endif
	if(dev != gps)
		return;	// ignore
	noSatellite=YES;	// GPS must convince us first that there is one...
	file=[[dev open:@"sane -parity 4800 -cstopb cread -opost"] retain];	// open serial device with 4800 baud
	if(!file)
		{
		NSLog(@"was not able to open device file %@", dev);
		return;
		}
	// we might send some commands here to set up the data format
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_dataReceived:)
												 name:NSFileHandleReadCompletionNotification 
											   object:file];	// make us see notifications
#if 1
	NSLog(@"waiting for data on %@", [dev devicePath]);
#endif
	[file readInBackgroundAndNotify];	// and trigger notifications
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSLocationResumedNotification object:self];	// notify any listener
}

- (void) deviceSuspended:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Location: deviceSuspended %@", dev);
#endif
	if(dev != gps)
		return;	// ignore
	if(file)
		{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSFileHandleReadCompletionNotification
													  object:file];	// don't observe any more
		[file closeFile];
#if 1
		NSLog(@"Location: file closed");
#endif
		[file release];
#if 1
		NSLog(@"Location: file released");
#endif
		file=nil;
		}
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSLocationSuspendedNotification object:self];	// notify any listener
}

- (id) init;
{
	self=[super init];
	if(self)
		{
		[SYSDevice addObserver:self];	// make me observe devices
		}
	return self;
}

- (void) dealloc;
{
	[SYSDevice removeObserver:self];	// remove me as observer
	[file release];
	[time release];
	[timeStamp release];
	[super dealloc];
}

- (BOOL) isAvailable;
{ // a location device is available
	return gps != nil;
}

- (BOOL) isValid;
{
	if(!gps || noSatellite || !timeStamp || [timeStamp timeIntervalSinceNow] < -10.0)
		return NO;	// no GPS, or last timestamp is more than 10 seconds old -> we have lost connection
	return YES;
}

- (GeoMovement) geoMovement; { return gpsData; }
- (unsigned) numberOfSatellites; { return numSatellites; }		// number of satellites with reception
- (unsigned) numberOfVisibleSatellites;  { return numVisibleSatellites; }	// number of satellites in view
- (float) precision; { return precision; }
- (GeoLocation) geoLocation; { return gpsData.location; }
- (double) locationLongitude; { return gpsData.location.longitude; }	// in degrees
- (double) locationLatitude; { return gpsData.location.latitude; }		// in degrees
- (double) locationHeight; { return gpsData.location.height; }			// height in m above NN
- (double) locationSpeed; { return gpsData.speed; }				// speed in m/s over surface
- (double) locationDirection; { return gpsData.direction; }		// compass direction in degrees
- (double) locationAscentSpeed;	{ return gpsData.ascent; }		// speed in m/s of ascent/descent
- (double) locationElevation; { return gpsData.elevation; }		// elevaton angle in degrees
- (double) locationOrientation; { return 0.0; }					// horizontal orientation of device (compass)

- (NSDate *) locationTime;
{
	if(timeStamp)
		return [time addTimeInterval:-[timeStamp timeIntervalSinceNow]];		// adjust
	return [NSDate date];	// use local time
}

// access built-in geo database

#define GEO_DB_FILE @"/System/Library/Sys.bundle/Contents/Resources/GeoDB"

- (NSDictionary *) geoDataForLocation:(GeoLocation) location;
{ // ask Geodatabase for nearest geo-location
	return nil;
}

- (GeoLocation) geoLocationForData:(NSDictionary *) pattern;
{ // search for location by pattern
	static GeoLocation loc;
	return loc;
}

#define deg2rad(P) (P*(3.14159265357989/180.0))

- (double) distanceBetween:(GeoLocation) p1 and:(GeoLocation) p2;
{ // great circle distance + hypotenuse of height difference
	/*
	 Based on description at: http://www.rainerstumpe.de/HTML/body_kurse3.html
	 
	 Die Fahrt soll von Porto in Portugal (φPorto = 41° 09' 28,0'' N = 41,1578°, λPorto = 008° 38' W = -8,6333° 
										   südliche Breiten und westliche Längen werden negativ angegeben)
	 nach Port of Spain auf Trinidad (φPoS = 0° 40' 19,9'' N = 0,6722°, λPorto = 061° 32' W = -61,5333°) gehen.
	 Die Entfernung c beträgt
	 cos c = sin φPorto · sin φPoS + cos φPorto · cos φPoS · cos (λPorto - λPoS)
	 = sin 41,1578° · sin 0,6722° + cos 41,1578° · cos 0,6722° · cos (-8,6333° - (-61,5333°)) =
	 = 0,6581·0,01173 + 0,7529·0,9999·0,6032 = 0,007719 + 0,4541 = 0,4618.
	 c = 62,5° = 3749' = 3749 sm.
	 
	 */
	
	double lat1=deg2rad(p1.latitude);
	double lat2=deg2rad(p2.latitude);
	double cosc = sin(lat1)*sin(lat2) + cos(lat1)*cos(lat2)*cos(deg2rad(p1.longitude-p2.longitude));
	double c=acos(cosc);				// angle on great circle (0..PI)
	double hh=p1.height-p2.height;		// height difference
										// FIXME: improve precision of this constant
	c*=3600000.0*(p1.height+p2.height);		// convert angle to sector of earth circumference at average height
											// FIXME: we should calculate some circular distance between the points
	c=sqrt(c*c+hh*hh);	// add hypotenuse
	return c;
}

- (float) routeBetween:(GeoLocation) p1 and:(GeoLocation) p2;
{ // determine north-pointing angle for navigate from p1 to p2 on shortest distance
	return 0.0;
}

@end