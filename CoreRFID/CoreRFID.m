//
//  CRTag.m
//  CRTag
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreRFID/CoreRFID.h>

@implementation CRTag

- (NSString *) tagUID; {
	return tagUID;
}
- (NSString *) description; {
	return [self tagUID];
}

- (NSData *) readAt:(NSUInteger) block; {
	return [CRTagManager readBlockForTag:self at:(NSUInteger) block];	
}

- (BOOL) write:(NSData *) data at:(NSUInteger) block; {
	return [CRTagManager writeBlockForTag:self at:(NSUInteger) block data:(NSData *) data];	
}

- (id) initWithUID:(NSString *) uid;
{
	if((self=[super init]))
		{
		tagUID=[uid retain];
		}
	return self;
}

- (void) dealloc
{
	[tagUID release];
	[super dealloc];
}

#if 0


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

#endif

- (id) copyWithZone:(NSZone *) zone
{
	CRTag *c=[CRTag alloc];
	if(c)
		{
/*		c->altitude=altitude;
		c->coordinate=coordinate;
		c->course=course;
		c->horizontalAccuracy=horizontalAccuracy;
		c->speed=speed;
		c->verticalAccuracy=verticalAccuracy;
		c->timestamp=[timestamp retain];
*/		}
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

@implementation CRTagManager

- (id <CRTagManagerDelegate>) delegate; { return delegate; }
- (void) setDelegate:(id <CRTagManagerDelegate>) d; { delegate=d; }

- (NSArray *) tags; {
	return [CRTagManager tags];
}

- (NSString *) readerUID; {
	return [CRTagManager readerUID];
}

- (id) init
{
	if((self=[super init]))
		{
		}
	return self;
}

- (void) dealloc
{
	[self stopMonitoringTags];
	[super dealloc];
}

- (void) startMonitoringTags;
{
	[CRTagManager registerManager:self];
}

- (void) stopMonitoringTags;
{
	[CRTagManager unregisterManager:self];
}

@end

// RFID USB key

@implementation CRTagManager (Serialport)

// this should be a system-wide service i.e. access through DO!

// here, we handle a Ubisys 13.56 MHz RFID USB CDC/ACM USB-key

static NSMutableArray *managers;	// list of all managers
static NSMutableDictionary *tags;	// keyed by UID
static NSFileHandle *file;
static NSString *lastChunk;

+ (NSArray *) tags; {
	return [tags allValues];
}

+ (NSString *) readerUID; {
	return @"Reader S/N";
}

+ (void) _writeCommand:(NSString *) str
{
#if 1
	NSLog(@"RFID w: %@", str);
#endif
	str=[str stringByAppendingString:@"\r"];
	[file writeData:[str dataUsingEncoding:NSASCIIStringEncoding]];	
}

+ (void) registerManager:(CRTagManager *) m
{
	if(!managers)
		{ // set up RFID receiver and wait for first fix
			NSString *dev=[[NSUserDefaults standardUserDefaults] stringForKey:@"RFIDReaderSerialDevice"];	// e.g. /dev/ttyACM0 or /dev/cu.usbmodem1d11
			if(!dev)
				{ // set some default
#if __mySTEP__
				dev=@"/dev/rfid";	// Linux: serial interface for USB receiver
#else
				dev=@"/dev/cu.usbmodem1d11";	// MacOS X: serial interface for USB receiver
#endif
				}			
			file=[[NSFileHandle fileHandleForUpdatingAtPath:dev] retain];
			if(!file)
				{
				NSLog(@"was not able to open device file %@", dev);
				// create an error object!
				[[m delegate] tagManager:m didFailWithError:nil];
				return;
				}
			managers=[[NSMutableArray arrayWithObject:m] retain];
			tags=[[NSMutableDictionary alloc] initWithCapacity:10];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(_dataReceived:)
														 name:NSFileHandleReadCompletionNotification 
													   object:file];	// make us see notifications
#if 1
			NSLog(@"waiting for data on %@", dev);
#endif
			[file readInBackgroundAndNotify];	// and trigger notifications
			// state=0;
			[self _writeCommand:@"ATE0"];
			[self _writeCommand:@"ATI"];
			[self _writeCommand:@"AT+RF1"];
			[self _writeCommand:@"AT+SCAN2"];
			[self _writeCommand:@"AT+I"];
			[self _writeCommand:@"AT+S"];
			return;
		}
	if([managers indexOfObjectIdenticalTo:m] != NSNotFound)
		return;	// already started
	[managers addObject:m];
}

+ (void) unregisterManager:(CRTagManager *) m
{
	[managers removeObjectIdenticalTo:m];
	if([managers count] == 0)
		{ // stop receiveer
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSFileHandleReadCompletionNotification
														  object:file];	// don't observe any more
			[self _writeCommand:@"AT+RF=0"];	// power down
			// could loop and wait for AT+RF? return 0...
			[file closeFile];
#if 1
			NSLog(@"RFID: file closed");
#endif
			[file release];
			[tags release];
			tags=nil;
			[managers release];
			managers=nil;
		}
}

+ (void) _processLine:(NSString *) line
{
#if 1
	NSLog(@"RFID r: %@", line);
#endif
	// check for state and divert response
	// notify changes in tag list
	// e.g.:
	// SCAN:+UID=E00401001C2017BD,+RSSI=0/2
	// SCAN:-UID=E0022C1395900204
	// ubisys 13.56MHz RFID (CDC) 1.08 Apr  7 2010
	// S/N 0000000000
	// +UID=E00401001C2017BD,+RSSI=0/2
	// +UID=E00401001C2017BD,DSFID=00,AFI=00,BC=28,BS=4,IC=01
	// OK
	// ERROR
	if([line hasPrefix:@"SCAN:+UID"])
		{ // tag added
			NSString *uid=[[[line substringFromIndex:10] componentsSeparatedByString:@","] objectAtIndex:0];
			CRTag *tag=[tags objectForKey:uid];
			if(!tag)
				{ // not yet known
				NSEnumerator *e=[managers objectEnumerator];
				CRTagManager *m;
				tag=[[CRTag alloc] initWithUID:uid];
				[tags setObject:tag forKey:uid];
				[tag release];
				while((m=[e nextObject]))
					[[m delegate] tagManager:m didFindTag:tag];
				}
#if 1
			NSLog(@"found %@: %@", uid, tag); 
#endif
			// update RSI
		}
	else if([line hasPrefix:@"SCAN:-UID"])
		{ // tag added
			NSString *uid=[[[line substringFromIndex:10] componentsSeparatedByString:@","] objectAtIndex:0];
			CRTag *tag=[tags objectForKey:uid];
#if 1
			NSLog(@"lost %@: %@", uid, tag); 
#endif
			if(tag)
				{
				NSEnumerator *e=[managers objectEnumerator];
				CRTagManager *m;
				[tag retain];
				[tags removeObjectForKey:uid];
				while((m=[e nextObject]))
					[[m delegate] tagManager:m didLooseTag:tag];
				[tag release];
				}
		}
}

+ (void) _processData:(NSData *) line;
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
			[self _processLine:s];
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
	[self _processData:[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]];	// parse data as line
	[[n object] readInBackgroundAndNotify];	// and trigger more notifications
}

@end
