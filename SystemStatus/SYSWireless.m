/* 
 Wireless card (GPRS/WLAN) driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

/*
 On Linux, pcmcia/lan drivers are reading from certain config files.
 They can be modified on a general level through the Network and WLAN settings.
 Some changes should be made through this system interface (esp. wirlessAttach:password:).
 
 read/write/update file
	/home/etc/pcmcia/wlan-ng.opts
 
 example:
	mySTEP1,*,*,*)
	INFO="Wireless LAN - TCP/IP"
	WLAN_ENABLE=y
	dot11PrivacyInvoked=false
	dot11WEPDefaultKeyID=0
	PRIV_KEY128=false
	dot11WEPDefaultKey0=
	dot11WEPDefaultKey1=    
	dot11WEPDefaultKey2=
	dot11WEPDefaultKey3=
	IS_ADHOC=y
	AuthType=opensystem
	DesiredSSID="1"
	SSID=$DesiredSSID
	CHANNEL=11
	BCNINT=100
	BASICRATES="2 4"
	OPRATES="2 4 11 22"
	;;
 mySTEP2,*,*,*)
	INFO="I"
	WLAN_ENABLE=y
	dot11PrivacyInvoked=true
	dot11WEPDefaultKeyID=0
	PRIV_KEY128=false
	dot11WEPDefaultKey0=49:49:49:49:49
	dot11WEPDefaultKey1=49:49:49:49:49
	dot11WEPDefaultKey2=49:49:49:49:49
	dot11WEPDefaultKey3=49:49:49:49:49
	IS_ADHOC=n
	AuthType=opensystem
	DesiredSSID=""
	;;
 
 and in /home/etc/pcmcia/network.opts:
	 mySTEP1,*,*,*)
	 INFO="Wireless LAN - TCP/IP"
	 BOOTP=n
	 DHCP=n
	 start_fn () { return; }
	 stop_fn () { return; }
	 IPADDR=192.168.0.201
	 GATEWAY=
	 IF_PORT=
	 DHCP_HOSTNAME=
	 NETWORK=
	 DOMAIN=
	 SEARCH=
	 MOUNTS=
	 MTU=
	 NO_CHECK=
	 NO_FUSER=
	 DNS_1=                  
	 DNS_2=
	 DNS_3=
	 ;;
	 mySTEP2,*,*,*)
	 INFO="I"
	 BOOTP=n
	 DHCP=n
	 start_fn () { return; }
	 stop_fn () { return; }
	 IPADDR=123.22.55.99
	 GATEWAY=
	 IF_PORT=
	 DHCP_HOSTNAME=
	 NETWORK=
	 DOMAIN=
	 SEARCH=
	 MOUNTS=
	 MTU=
	 NO_CHECK=
	 NO_FUSER=
	 DNS_1=11.22.33.44
	 DNS_2=
	 DNS_3=
	 ;;
 
 */ 

#import <SystemStatus/SYSWireless.h>

#include <net/if_arp.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <arpa/inet.h>
#ifdef __mySTEP__
#include <linux/wireless.h>
#endif

NSString *SYSWirelessRingingNotification=@"SYSWirelessRingingNotification";					// incoming call - notification data is calling line ID
NSString *SYSWirelessBusyNotification=@"SYSWirelessBusyNotification";						// other side is busy
NSString *SYSWirelessEstablishedNotification=@"SYSWirelessEstablishedNotification";			// call established
NSString *SYSWirelessHangupNotification=@"SYSWirelessHangupNotification";					// call was ended (by either side)
NSString *SYSWirelessSignalStrengthChangedNotification=@"SYSWirelessSignalStrengthChangedNotification";		// signal strength changed considerably
NSString *SYSWirelessAttachedNotification=@"SYSWirelessAttachedNotification";				// attached to new network (detached if current network is nil)
NSString *SYSWirelessDetachedNotification=@"SYSWirelessDetachedNotification";				// attached to new network (detached if current network is nil)
NSString *SYSWirelessMessageNotification=@"SYSWirelessMessageNotification";					// message received
NSString *SYSWirelessResumedNotification=@"SYSWirelessResumedNotification";					// interface powered down
NSString *SYSWirelessSuspendedNotification=@"SYSWirelessSuspendedNotification";				// interface powered up
NSString *SYSWirelessInsertedNotification=@"SYSWirelessInsertedNotification";				// interface inserted
NSString *SYSWirelessEjectedNotification=@"SYSWirelessEjectedNotification";					// interface ejected

// a GPRS card is accessed through the serial_cs.o driver module
// by GSM 07.07 AT commands

#if 0
#define GPRS_SET_PIN(PIN)			"at+cpin=\"#PIN#\""
#define GPRS_DIAL_VOICE(NUMBER)		"at d "#NUMBER#";"
#define GPRS_DIAL_DATA(NUMBER)		"at d "#NUMBER""
#define GPRS_HANGUP(NUMBER)			"at+chup"
#define GPRS_SET_NETWORK(NETWORK)   "at+CGDCONT=1,'IP', '#NETWORK#'"
#define GPRS_GET_NETWORK			"at+cops?"
#define GPRS_GET_ALL_NETWORKS		"at+cops=?"
#define GPRS_GET_SIGNAL_QUALITY		"at+csq=?"
#endif

@implementation SYSWireless

// this is a linux-wlan-ng wrapper
// for more info, please look at
// http://www.linux-wlan.com/linux-wlan/
// the API is defined in "linux/wireless.h"
// examples how to use the ioctl() mechanism can be found in the sources of "kismet"

#if 0
- (BOOL) accept;			// accept incoming call (returns NO when ringing ended before accept was called)
- (void) hangup;			// hang up/abort incoming call
- (BOOL) inCall;			// currently in call state
#endif

+ (SYSWireless *) sharedWireless;
{
	static SYSWireless *w;
	if(!w) 
		w=[[self alloc] init];
	return w; 
}

#if OLD
// this should be called every now and then to check if we should notify wireless signal strength changes

- (void) _deviceUpdateNotification:(NSNotification *) n;
{ // that updates the devices table
	NSEnumerator *en=[[n object] objectEnumerator];
	SYSDevice *wlanCard=nil, *gprsCard=nil, *device;
	while((device=[en nextObject]))
		{
		if([device isInserted])
			{
#if 0
			NSLog(@"device found:");
			NSLog(@" Manufacturer=%@", [device deviceManufacturer]);
			NSLog(@" Name=%@", [device deviceName]);
			NSLog(@" Driver=%@", [device deviceDriver]);
#endif
			// Audiovox RTM 8000 - returns bogus card identification
			// Eagletech GSM/GPRS CF+ (FCC ID: MSQAGC100) - does the same
			if([[device deviceManufacturer] isEqualToString:@"GPRS Modem"])
				gprsCard=device;	// found!
			// any wlan-ng based WiFi card
			else if([[device deviceDriver] isEqualToString:@"wlan-ng"])
				wlanCard=device;	// found!
			}
		}
#if 0
	NSLog(@"wlan=%@", wlanCard);
	NSLog(@"gprs=%@", gprsCard);
#endif
	if(wlan != wlanCard)
		{
		if((wlan=wlanCard))
			{
			NSLog(@"WLAN plugged in"); // plugged in -> initialize
			}
		else
			{
			[self wirelessDetach];
#if 0
			NSLog(@"WLAN pulled out"); // if pulled out -> detach
#endif
			}
		}
	if(gprs != gprsCard)
		{
		if((gprs=gprsCard))
			{
			NSLog(@"GPRS plugged in"); // plugged in -> initialize
			// we should have serial_vcc_cs.o installed
			// modprobe serial_vcc_cs should return 0
			// Step 3 edit the file /etc/pcmcia/serial.opts and set:
				
			// SERIAL_OPTS="uart 16550A" 
			}
		else
			{
			[self wirelessDetach];
#if 0
			NSLog(@"GPRS pulled out"); // if pulled out -> detach
#endif
			}
		}
#if 1
	{
		static float lastSignalStrength;
		float signal=[self wirelessSignalStrength];
		if(fabs(signal-lastSignalStrength) > 0.2)
			{ // needs to notify
			lastSignalStrength=signal;
			[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessSignalStrengthChangedNotification object:self];
			}
	}
#endif
}

#endif

- (void) _dataReceived:(NSNotification *) n;
{
	NSData *d;
#if 1
	NSLog(@"_dataReceived %@", n);
#endif
	d=[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	// do we need to splice together data junks?
	[file readInBackgroundAndNotify];	// and trigger more notifications
}

// lock only if it is not really removable (i.e. builtin but indicated here)

- (void) deviceShouldLock:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Wireless: deviceShouldLock %@", dev);
#endif
	if(![dev isLocked])
		{ // try wireless cards if not already locked by somebody else
		if([[dev deviceManufacturer] isEqualToString:@"GPRS Modem"])	// Audiovox RTM 8000 - returns bogus card identification
			{
#if 1
			NSLog(@"GPRS card found: %@", dev);
#endif
			gprs=dev;
			[dev lock:YES];	// found and grab!
			}
		else if([[dev deviceDriver] isEqualToString:@"wlan-ng"])		// any wlan-ng based WiFi card
			{
#if 1
			NSLog(@"WLAN card found: %@", dev);
#endif
			wlan=dev;
			[dev lock:YES];	// found and grab!
			}
		}
}

- (void) deviceInserted:(NSNotification *) n;
	{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Wireless: deviceInserted %@", dev);
#endif
	if(dev != wlan && dev != gprs)
		return;	// someone else
	if(!(wlan && gprs))	// not if both
		[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessInsertedNotification object:self];	// first one was inserted
}

- (void) deviceEjected:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Wireless: deviceEjected %@", dev);
#endif
	if(dev != wlan && dev != gprs)
		return;	// someone else
	if(dev == wlan)
		wlan=nil;
	else
		gprs=nil;
	if(!wlan && !gprs)
		[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessEjectedNotification object:self];	// all are now ejected...
}

- (void) deviceSuspended:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Wireless: deviceSuspended %@", dev);
#endif
	if(dev != wlan && dev != gprs)
		return;	// someone else
	if(dev == wlan)
		{
		}
	else
		{ // suspend GPRS modem
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
		}
	// send notification if both are suspended now
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessSuspendedNotification object:self];
}

- (void) deviceResumed:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"Wireless: deviceResumed %@", dev);
#endif
	if(dev != wlan && dev != gprs)
		return;	// someone else
	if(dev == wlan)
		{
		// do any additional initialization
		}
	else
		{ // GPRS modem card
//		system("/sbin/setserial -g /dev/modem");
		system([[NSString stringWithFormat:@"/sbin/setserial %@ uart 16550a", [dev devicePath]] cString]);	// just be sure
//		system("/sbin/setserial -g /dev/modem");
		file=[[dev open:@"sane -parity 38400 -cstopb cread -opost"] retain];	// open serial device
		if(!file)
			{
			NSLog(@"was not able to open device file %@", dev);
			return;
			}
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_dataReceived:)
													 name:NSFileHandleReadCompletionNotification 
												   object:file];	// make us see notifications
																	//	[file setNonBlocking:YES];
#if 1
		NSLog(@"waiting for data on %@", [dev devicePath]);
#endif
		[file readInBackgroundAndNotify];	// and trigger notifications
		[file writeData:[@"ATE0\n" dataUsingEncoding:NSASCIIStringEncoding]];	// don't echo what I send!
		// make modem send LF only
		[file writeData:[@"ATI0I1I2\n" dataUsingEncoding:NSASCIIStringEncoding]];
		}
	// only if first one?
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessResumedNotification object:self];
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
	[wlan lock:NO];		// just be sure...
	[gprs lock:NO];
	[SYSDevice removeObserver:self];	// remove me as observer
	[super dealloc];
}

#define OBSERVE_(o, notif_name) \
if ([o respondsToSelector:@selector(wireless##notif_name:)]) \
[n addObserver:o \
	  selector:@selector(wireless##notif_name:) \
		  name:SYSWireless##notif_name##Notification \
		object:nil]

- (void) addObserver:(id) delegate;
{
	NSNotificationCenter *n=[NSNotificationCenter defaultCenter];
#if 1
	NSLog(@"SYSWireless observer %@ added", delegate);
#endif
	OBSERVE_(delegate, Ringing);
	OBSERVE_(delegate, Busy);
	OBSERVE_(delegate, Established);
	OBSERVE_(delegate, Hangup);
	OBSERVE_(delegate, SignalStrengthChanged);
	OBSERVE_(delegate, Attached);
	OBSERVE_(delegate, Detached);
	OBSERVE_(delegate, Message);
	OBSERVE_(delegate, Suspended);
	OBSERVE_(delegate, Resumed);
	OBSERVE_(delegate, Inserted);
	OBSERVE_(delegate, Ejected);
}

- (void) removeObserver:(id) delegate;
{
#if 1
	NSLog(@"SYSWireless observer %@ removed", delegate);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:delegate];
}

- (BOOL) wirelessCanDial;			// current network supports dialling (i.e. GSM or VoWLAN/VoIP)
{
	return gprs != nil;
}

- (BOOL) wirelessDial:(NSString *) number;
{ // dial/call that number; YES if it was a valid number
#if 1
	NSLog(@"dial: %@", number);
#endif
	if(!gprs)
		return NO;  // can't dial
	return NO;
}

- (BOOL) wirelessAccept;
{ // accept incoming call
#if 1
	NSLog(@"accept");
#endif
	inCall=YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessEstablishedNotification object:self];
	return YES;
}

- (void) wirelessHangup;
{ // hang up
#if 1
	NSLog(@"hangup");
#endif
	inCall=NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessHangupNotification object:self];
}

- (BOOL) wirelessInCall;
{ // get call status
	return inCall;
}

- (float) wirelessSignalStrength;
{ // relative signal strength of current network
	return [self wirelessSignalStrengthOfNetwork:current];
}

- (float) wirelessSignalStrengthOfNetwork:(NSString *) name;
{ // relative signal strength of specified network
	return [self wirelessSignalStrengthOfNetwork:name andNoise:NULL];
}

- (float) wirelessSignalStrengthOfNetwork:(NSString *) name andNoise:(float *) noise;
{ // relative signal strength and noise of specified network
#if 1	// first fake functionality
	extern long time(long *);
	float signal=((time(NULL) / 20)%5)/4.0;	// change every 20 seconds in 5 levels
	return signal;
#endif

#if OLD
    struct iwreq wreq;
    struct iw_range range;
    struct iw_statistics stats;
    char buffer[2*sizeof(range)];
	strncpy(wreq.ifr_name, ifname, IFNAMSIZ);
    memset(buffer, 0, sizeof(buffer));
    memset(&wreq, 0, sizeof(wreq));
    wreq.u.data.pointer=(caddr_t) buffer;
    wreq.u.data.length=sizeof(buffer);
    wreq.u.data.flags=0;
	if(ioctl(sock, SIOCGIWRANGE, &wreq) < 0)
		{
		NSLog(@"SYSWireless wirelessSignalStrengthOfNetwork: ioctl(SIOCGIWRANGE) failed (%s)", strerror(errno));
		return -1.0; // could not determine
		}
    memcpy((char *) &range, buffer, sizeof(range));
    wreq.u.data.pointer=(caddr_t) &stats;
    wreq.u.data.length=0;
    wreq.u.data.flags=1;     // clear updated flag
#if 0  // SIOCGIWSTATS missing on Zaurus Linux Header...
	if(ioctl(sock, SIOCGIWSTATS, &wreq) < 0)
		{
		NSLog(@"SYSWireless wirelessSignalStrengthOfNetwork: ioctl(SIOCGIWSTATS) failed (%s)", strerror(errno));
		return nil; // could not determine
		}
    if(stats.qual.level <= range.max_qual.level)
#endif
		return -1.0;
	if(noise)
		*noise=(stats.qual.noise-256)/255.0;	// bring to range 0...1
	return (stats.qual.level-256)/255.0;	// bring to range 0...1
#endif
}

- (NSString *) wirelessNetwork;
{ // current network - nil if none available (e.g. no interface)
	return @"D2";
#if OLD
    char essid[IW_ESSID_MAX_SIZE+1];
    struct iwreq wreq;
	strncpy(wreq.ifr_name, ifname, IFNAMSIZ);
    wreq.u.essid.pointer=(caddr_t) essid;
    wreq.u.essid.length=sizeof(essid);
    wreq.u.essid.flags=0;
	if(ioctl(sock, SIOCGIWESSID, &wreq) < 0)
		{
		NSLog(@"SYSWireless wirelessNetwork: ioctl(SIOCGIWESSID) failed (%s)", strerror(errno));
		return nil; // could not determine
		}
	return [NSString stringWithCString:(const char *) wreq.u.essid.pointer
								length:MIN(IW_ESSID_MAX_SIZE, wreq.u.essid.length)+1];
#endif
}

- (NSString *) wirelessBestNetwork;
{ // currently best network - nil if none available
	return [[self wirelessNetworks] objectAtIndex:0];
}

- (BOOL) wirelessAttach:(NSString *) network password:(NSString *) key;
{ // try to attach to specified network - nil means best one - stay with current if attachment fails
	[wlan resume];
	[gprs resume];	// whatever is installed
	if(!key)
		key=@"";	// empty key
	if(!network)
		network=[self wirelessBestNetwork];
#if 1
	NSLog(@"attach to network '%@' with passcode '%@'", network, key);
#endif
	current=[network copy];
	// set ESSID and WEP passcode (if enabled)
	// or set PIN
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessAttachedNotification object:self];
	return YES;
}

- (BOOL) wirelessAttachAsBaseStation:(NSString *) network channel:(int) channel options:(NSDictionary *) options;
{ // switch to base station mode
	if(!wlan)
		return NO;	// only for WLAN base station
	if(![network length])
		return NO;  // missing or empty name
	[wlan resume];
	// switch to base station mode
	// set channel
	// use options to define WEP key etc.
	current=[network retain];
	// this should be generated by the attached notification
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessAttachedNotification object:self];
	return YES;
}

- (BOOL) wirelessAttached;			// attached to network
{
	return [wlan isReady] || [gprs isReady];
}

- (void) wirelessDetach;
{ // detach from any network (and power off)
	[current release];
	[wlan suspend];
	[gprs suspend];	// whatever is installed
	[[NSNotificationCenter defaultCenter] postNotificationName:SYSWirelessDetachedNotification object:self];
}

- (void) wirelessEject;
{
	[wlan eject];
	[gprs eject];
}

- (NSArray *) wirelessNetworks;
{ // list of current active and recenly visited networks
	// merge with network list from interface
	return [NSArray arrayWithObjects:@"DSITRI-2", @"T-Mobile", @"Vodafone", @"Orange", nil];
}

- (BOOL) wirelessSendMessage:(NSString *) msg to:(NSString *) dest;
{ // send message
	if(gprs)
		{
		// create an SMS
		}
	return NO;
}

@end