/* 
 PCCard driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004-2007
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/SYSDevice.h>

/*
  running /sbin/cardctl 0 status/ident/config is better than using ioctl() although slower it is accessible from
  user space. Cardctl may be setuid.
  
  Example:
  
# cardctl ident
  Socket 0:
  product info: "GPRS Modem", "", "", ""
  manfid: 0x0279, 0x950b
  function: 2 (serial)
  Socket 1:
  no product info available
# cardctl status
  Socket 0:
  3.3V 16-bit PC Card
  function 0: [ready]
  Socket 1:
  no card
# cardctl config
  Socket 0:
  Vcc 3.3V  Vpp1 3.3V  Vpp2 3.3V
  Socket 1:
  not configured
  
  
  Alternative to read /var/lib/pcmcia/stab just list the devices + drivers (which is not available through cardctl)
  
  stab(5) format
  
  Lines consist of a series of  tab-separated  fields.   The
  first field is the socket number.  The second field is the
  device class, which identifies which script in /etc/pcmcia
  is  used to configure or shut down this device.  The third
  field is the driver name.  The fourth  field  is  used  to
  number  devices  when  a  single  card has several devices
  associated with the same driver.  The fifth field  is  the
  device  name, and the final two fields are major and minor
  device numbers for this device, if appropriate.
  
  Example:
  
  Socket 0: Serial or Modem
  0       serial  serial_cs       0       ttyS3   4       67
  Socket 1: empty
  
  */
 
 // for SD-Card:
 //  /etc/sdcontrol insert/eject (is a shell script)
 //
 //  check if /mnt/card has directory or only 1 file 'Not Available'
 //  or check mount table
 
 /* line values to decode
 (stab)
 Socket 0: Serial or Modem
 0	serial	serial_cs	0	ttyS3	4	67
 Socket 0: D-Link DCF-660W  11Mbps 802.11b WLAN Card
 0       wlan-ng prism2_cs       0       eth0
 Socket 0: ATA/IDE Fixed Disk
 0       ide     ide_cs  0       hda     3       0
 Socket 1: empty
 (ident)
 Socket 0:
 product info: "GPRS Modem", "", "", ""
 manfid: 0x0279, 0x950b
 function: 2 (serial)
 product info: "SanDisk Corporation", "Wireless LAN Card", ""
 manfid: 0xd601, 0x0005
 function: 6 (network)
 no product info available
 product info: "SunDisk", "SDP", "5/3 0.6"
 manfid: 0x0045, 0x0401
 function: 4 (fixed disk)
 (status)
 3.3V 16-bit PC Card [suspended]
 3.3V 16-bit PC Card
 function 0: [ready], [bat dead], [bat low]
 no card
 (config)
 Vcc 0.0V  Vpp1 0.0V  Vpp2 0.0V
 Vcc 3.3V  Vpp1 0.0V  Vpp2 0.0V
 interface type is "memory and I/O"
 irq 35 [exclusive] [level]
 Speaker output is enabled
 function 0:
 config base 0x00f8
 option 0x41 status 0x08 pin 0x00 copy 0x00
 option 0x41
 io 0xc56703f8-0xc5670407 [8bit]
 io 0xc5670000-0xc567000f [auto]
 not configured
*/ 

NSString *SYSDeviceShouldLockNotification=@"SYSDeviceShouldLockNotification";	// first pass to lock
NSString *SYSDeviceInsertedNotification=@"SYSDeviceInsertedNotification";		// device is inserted
NSString *SYSDeviceEjectedNotification=@"SYSDeviceEjectedNotification";		// device is ejected
NSString *SYSDeviceSuspendedNotification=@"SYSDeviceSuspendedNotification";	// device is activated
NSString *SYSDeviceResumedNotification=@"SYSDeviceResumedNotification";		// device is deactivated

@implementation SYSDevice

static NSMutableArray *cards;	// current list of cards

/* create entries like:
{
    Empty = Serial;
    devid = 0x950b;
    driver = Vpp1;
    driverclass = 0.0V;
    function = 2;
    function2 = (serial);
    interface = Vpp2;
    manfid = 0x0279,;
    socket = 0;
    suspended = 1;
},
{
    Empty = empty;
    socket = 1;
}
*/

static int intValue(NSString *str)
{ // return -1 if not a valid decimal
	unichar c;
	if([str length] == 0)
		return -1; // no
	c=[str characterAtIndex:0];
	if(c >= '0' && c <= '9')
		return [str intValue];
	return -1;  // no
}

+ (void) _updateCardStatus;
{ // update cards list and status
	FILE *stab;
	char line[256];
	int sock=0;
	int func;
	NSMutableDictionary *s=nil; // current socket entry
	NSEnumerator *e;
	SYSDevice *card;
	NSNotificationCenter *n=[NSNotificationCenter defaultCenter];
	[self deviceList];   // initialize if required
	if(system("[ -r /var/lib/pcmcia/stab ] && [ -x /sbin/cardctl ]") != 0)
		{ // can't read
		NSLog(@"can't read /var/lib/pcmcia/stab or execute /sbin/cardctl");
		[self updateDeviceList:NO];	// don't update any more
		return;	// don't try again
		}
	// pipe everything we can find out to the FILE * - we will fiddle out by detecting the format
#if 0
	stab=popen("echo 'cat /var/lib/pcmcia/stab && /sbin/cardctl ident && /sbin/cardctl status && /sbin/cardctl config'", "r");  // open subprocess
#else
	stab=popen("cat /var/lib/pcmcia/stab && /sbin/cardctl ident && /sbin/cardctl status && /sbin/cardctl config", "r");  // open subprocess
#endif
	if(!stab)
		{ // can't read
		NSLog(@"can't read device status");
		return;
		}
	while(fgets(line, sizeof(line)-1, stab))
		{
		char *c0, *c1, *c;
		NSMutableArray *args=[NSMutableArray arrayWithCapacity:10];
		NSString *arg0, *arg1, *arg2;
		int argc;
		line[sizeof(line)-1]=0;	// cut off
//		NSLog(@"line=%s", line);
		c=line;
		while(*c)
			{
			while(*c == ' ' || *c == '\t' || *c == '\n')
				c++;	// skip
			if(*c == 0)
				break;
			c0=c;
			if(*c == '"')
				{ // quoted argument
				c0=++c;
				while(*c && *c != '"')
					c++;
				c1=c;
				if(*c)
					c++;	// skip closing quote
				}
			else if(*c == '[')
				{ // brackeded argument
				while(*c && *c != ']')
					c++;
				if(*c)
					c++;	// skip closing ]
				c1=c;	// but include
				}
			else if(*c == '(')
				{ // braced argument
				while(*c && *c != ')')
					c++;
				if(*c)
					c++;	// skip closing )
				c1=c;	// but include
				}
			else if(*c == ':' || *c == ',')
				c1=++c;	// take : and , as a separate arguments
			else
				{ // standard unquoted argument
				while(*c && *c != ' ' && *c != '\t' && *c != '\n' && *c != ':' && *c != ',')
					c++;
				c1=c;
				}
//			NSLog(@"c0=%08x c1=%08x str=%@", c0, c1, [NSString stringWithCString:c0 length:c1-c0]);
			[args addObject:[NSString stringWithCString:c0 length:c1-c0]];
			}
//		NSLog(@"args=%@", args);
		if(!(argc=[args count]))
			continue;   // empty line...
		arg0=[args objectAtIndex:0];
		arg1=argc > 1?[args objectAtIndex:1]:nil;
		arg2=argc > 2?[args objectAtIndex:2]:nil;
		if([arg0 isEqualToString:@"Socket"] && [arg2 isEqualToString:@":"])
			{ // Socket %d:
			sock=[arg1 intValue];
			if(sock < 0 || sock > 9)
				continue;  // some error
//			NSLog(@"Socket %d", sock);
			while(sock >= [cards count])
				[cards addObject:[[[self alloc] init] autorelease]];   // add new entries to card's table
			s=(NSMutableDictionary *) [[cards objectAtIndex:sock] deviceInfo];   // reference current socket entry
			[s setObject:arg1 forKey:@"socket"];
			// might extract other info from "Socket %d: type"
			if(argc >= 4)
				[s setObject:[args objectAtIndex:3] forKey:@"Empty"];   // @"empty" or something else
			continue;
			}
		if(argc >= 5 && intValue(arg0) == sock)
			{ // stab entry: %d ...
			[s setObject:arg1 forKey:@"driverclass"];  // wlan-ng, serial, ide etc.
			[s setObject:arg2 forKey:@"driver"];  // prism_cs, serial_cs, ide_cs etc.
			[s setObject:[args objectAtIndex:4] forKey:@"interface"];  // eth0, ttyS3,hda
			continue;
			}
		if(argc == 5 && [arg0 isEqualToString:@"manfid"] && [arg1 isEqualToString:@":"])
			{ // manfid: 0xxx, 0yyy
			[s setObject:arg2 forKey:@"manfid"];
			[s setObject:[args objectAtIndex:4] forKey:@"devid"];
			continue;
			}
		if(argc >= 4 && [arg0 isEqualToString:@"function"] && [arg1 isEqualToString:@":"])
			{ // function: (serial), (fixed disk)
			 // function: 4 (fixed disk)
			[s setObject:arg2 forKey:@"function"];
			[s setObject:[args objectAtIndex:3] forKey:@"function2"];
			continue;
			}
		if([arg0 isEqualToString:@"function"] && [arg2 isEqualToString:@":"])
			{ // function %d: [ready], [bat dead], [bat low]
			func=[arg1 intValue];
#if 0
			NSLog(@"line=%s\nargs=%@", line, args);
#endif
			if(argc >= 4)
				[s setObject:[args objectAtIndex:3] forKey:@"ready"];  // store [ready] value etc.
			continue;
			}
		if(argc >= 6 && [arg0 isEqualToString:@"product"] && [arg1 isEqualToString:@"info"] && [arg2 isEqualToString:@":"])
			{ // product info: "info1", "info2", ...
			[s setObject:[args objectAtIndex:3] forKey:@"Manufacturer"];
			[s setObject:[args objectAtIndex:5] forKey:@"Devicetype"];
			// ignore others if present
			continue;
			}
		if(argc == 4 && [arg0 isEqualToString:@"no"] && [arg1 isEqualToString:@"product"] && [arg2 isEqualToString:@"info"])
			{ // no product info available
			[s removeObjectForKey:@"Manufacturer"];
			[s removeObjectForKey:@"Devicetype"];
			[s removeObjectForKey:@"manfid"];
			[s removeObjectForKey:@"devid"];
			[s removeObjectForKey:@"function"];
			[s removeObjectForKey:@"function2"];
			[s removeObjectForKey:@"driverclass"];
			[s removeObjectForKey:@"driver"];
			[s removeObjectForKey:@"interface"];
			[s removeObjectForKey:@"suspended"];
			[s removeObjectForKey:@"ready"];
			continue;
			}
		if(argc == 2 && [arg0 isEqualToString:@"no"] && [arg1 isEqualToString:@"card"])
			{ // no card
			[s setObject:@"1" forKey:@"suspended"];	// "no card" is also suspended
			[s removeObjectForKey:@"function"];
			continue;
			}
		if([arg2 isEqualToString:@"PC"] && [[args objectAtIndex:3] isEqualToString:@"Card"])
			{ // x.xV yy-bit PC Card [suspended]
			// could save voltage&bits
#if 0
			NSLog(@"line=%s", line);
#endif
			if(argc > 4 && [[args objectAtIndex:4] isEqualToString:@"[suspended]"])
				[s setObject:@"1" forKey:@"suspended"];
			else
				[s setObject:@"0" forKey:@"suspended"];	// not suspended!
			continue;
			}
		if(argc == 2 && [arg0 isEqualToString:@"not"] && [arg1 isEqualToString:@"configured"])
			continue;
		// this should be an NSDictionary with keys to ignore!
		if([arg0 isEqualToString:@"Vcc"])
			continue;
		if([arg0 isEqualToString:@"function"])
			continue;
		if([arg0 isEqualToString:@"config"])
			continue;
		if([arg0 isEqualToString:@"option"])
			continue;
		if([arg0 isEqualToString:@"interface"])
			continue;
		if([arg0 isEqualToString:@"irq"])
			continue;
		if([arg0 isEqualToString:@"io"])
			continue;
		if([arg0 isEqualToString:@"Speaker"])
			continue;
		NSLog(@"SYSDevice not handled: %@", args);
		}
	pclose(stab);
	/****
		process
			/proc/mounts
		for mounted CF and SD memory cards
		****/
#if 0
	NSLog(@"notify everybody %@", cards);
#endif
	e=[cards objectEnumerator];
	while((card=[e nextObject]))
		{ // check if we need to send notifications for changes
		NS_DURING
			if(!card->wasInserted && [card isInserted])
				{
				card->wasInserted=YES;
				[n postNotificationName:SYSDeviceShouldLockNotification object:card];	// first pass - allows to lock device
				[n postNotificationName:SYSDeviceInsertedNotification object:card];		// second pass - allows to ignore otherwise locked devices
				}
			if(!card->wasSuspended && [card isSuspended]) card->wasSuspended=YES, [n postNotificationName:SYSDeviceSuspendedNotification object:card];
			if(card->wasSuspended && ![card isSuspended]) card->wasSuspended=NO, [n postNotificationName:SYSDeviceResumedNotification object:card];
			// EJECT should better notify with previous data!
			if(card->wasInserted && ![card isInserted]) card->wasInserted=NO, card->locked=NO, [n postNotificationName:SYSDeviceEjectedNotification object:card];
		NS_HANDLER
			;;	// ignore exceptions
		NS_ENDHANDLER
		}
//	[self performSelector:_cmd withObject:nil afterDelay:3.7];	// and finally try to update approx. every 4 seconds
}

#define OBSERVE_(o, notif_name) \
if ([o respondsToSelector:@selector(device##notif_name:)]) \
		[n addObserver:o \
			  selector:@selector(device##notif_name:) \
				  name:SYSDevice##notif_name##Notification \
				object:nil]

static int observers;

+ (void) addObserver:(id) object;
{
	NSNotificationCenter *n=[NSNotificationCenter defaultCenter];
#if 1
	NSLog(@"SYSDevice observer %@ added", object);
#endif
	OBSERVE_(object, ShouldLock);	// first pass
	OBSERVE_(object, Inserted);
	OBSERVE_(object, Ejected);
	OBSERVE_(object, Resumed);
	OBSERVE_(object, Suspended);
	observers++;
	[self updateDeviceList:observers > 0];	// start only if there are any obserers
	}

+ (void) removeObserver:(id) object;
	{
#if 1
	NSLog(@"SYSDevice observer %@ removed", object);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:object];
	if(observers > 0)
		observers--;
}

+ (NSArray *) deviceList;
{ // array of all currently known devices
	if(!cards)
		cards=[[NSMutableArray arrayWithCapacity:5] retain];
	return cards;
}

+ (void) updateDeviceList:(BOOL) flag;   // enable/disable device polling loop - default is NO
{
	static BOOL status=NO;
	static NSTimer *timer;
	if(status == flag)
		return; // don't change
	if(!(status=flag))
		[timer release], timer=nil;		// disabled
	else
		{
#if 1
		NSLog(@"updateDeviceList enabled");
#endif
		timer=[[NSTimer scheduledTimerWithTimeInterval:4.0
												target:self
											  selector:@selector(_updateCardStatus)
											  userInfo:nil
											   repeats:YES] retain];
		}
}

+ (SYSDevice *) deviceByIndex:(unsigned) index;
{
	return [[self deviceList] objectAtIndex:index];
}

- (id) init;
{
	self=[super init];
	if(self)
		{
		deviceInfo=[[NSMutableDictionary dictionaryWithCapacity:10] retain];
		// wasInserted=NO;	
		wasSuspended=YES;	// slot starts as suspended
		}
	return self;
}

- (void) dealloc;
{
	[deviceInfo release];
	[super dealloc];
}

- (BOOL) isLocked; { return locked; }
- (void) lock:(BOOL) flag; { locked=flag; }

- (NSString *) description;
{
	return [NSString stringWithFormat:@"Type=%@ Manuf=%@ Name=%@ Driver=%@ Path=%@%@%@%@", 
		[self deviceType],
		[self deviceManufacturer],
		[self deviceName],
		[self deviceDriver],
		[self devicePath],
		[self isInserted]?@" inserted":@"",
		[self isSuspended]?@" suspended":@"",
		[self isReady]?@" ready":@"",
		[self isLocked]?@" locked":@"",
		[self isRemovable]?@" removable":@""
		];
}

- (NSDictionary *) deviceInfo; { return deviceInfo; }
- (NSString *) deviceManufacturer; { return [deviceInfo objectForKey:@"Manufacturer"]; }
- (NSString *) deviceName; { return [deviceInfo objectForKey:@"Devicetype"]; }
- (NSString *) deviceDriver; { return [deviceInfo objectForKey:@"driverclass"]; }
- (NSString *) devicePath; { return [NSString stringWithFormat:@"/dev/%@", [deviceInfo objectForKey:@"interface"]]; } // /dev path
- (NSString *) mountPath; { return nil; } // /mnt path - if available
- (NSString *) deviceType; { return @"PCMCIA"; }	// device type: PCMCIA, SD, USB, IDE, ...

- (BOOL) isRemovable;
{
	// FIXME - we should probably detect by mount point or driver
	if([[deviceInfo objectForKey:@"Manufacturer"] isEqualToString:@"HITACHI"] && [[deviceInfo objectForKey:@"Devicetype"] isEqualToString:@"microdrive"])
		return NO;	// Zaurus SL-C3x00 builtin microdrive
	return YES;
}

- (BOOL) _cardCmd:(NSString *) cmd;
{
	NSString *c;
	// FIXME: get card command from our device description database
	if([[self deviceType] isEqualToString:@"PCMCIA"])
		c=[NSString stringWithFormat:@"/sbin/cardctl %@ %@", cmd, [deviceInfo objectForKey:@"socket"]];
	else if([[self deviceType] isEqualToString:@"SD"])
		c=[NSString stringWithFormat:@"/etc/sdcontrol %@ %@", cmd, [deviceInfo objectForKey:@"socket"]];
	else
		return NO;
#if 1
	NSLog(@"%@", c);
#endif
	return system([c cString]) == 0;
}

- (BOOL) eject;
{
	return [self isRemovable] && [self _cardCmd:@"eject"];
}

- (BOOL) insert;
{
	return [self isRemovable] && [self _cardCmd:@"insert"];
}

- (BOOL) suspend; { return [self isSuspended] || [self _cardCmd:@"suspend"]; }
- (BOOL) resume; { return ![self isSuspended] || [self _cardCmd:@"resume"]; }
- (BOOL) isSuspended; { return [[deviceInfo objectForKey:@"suspended"] intValue] != 0; }	// entry exists and is true
- (BOOL) isInserted; { return [deviceInfo objectForKey:@"manfid"] != nil; }
- (BOOL) isReady; { return [[deviceInfo objectForKey:@"ready"] isEqualToString:@"[ready]"]; }

- (NSFileHandle *) open:(NSString *) stty;
{ 
	if([self isInserted] && [self isReady] && ![self isSuspended])
		{
		NSFileHandle *fh;
		fh=[NSFileHandle fileHandleForUpdatingAtPath:[self devicePath]];
		if(!fh)
			{
			NSLog(@"Device open: can't open %@", [self devicePath]);
			return nil;
			}
		if(stty)
			system([[NSString stringWithFormat:@"stty %@ <%@", stty, [self devicePath]] cString]);	// try to change
		return fh;
		}
	return nil; // can't access
}

@end