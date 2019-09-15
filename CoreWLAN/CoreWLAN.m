//
//  CoreWLAN.m
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

/*
  Here is some API:
		http://developer.apple.com/library/mac/#documentation/Networking/Reference/CoreWLANFrameworkRef/
 
  Examples how to use this API, see e.g.
		http://dougt.org/wordpress/2009/09/usingcorewlan/
		http://lists.apple.com/archives/macnetworkprog/2009/Sep/msg00007.html
		Apple CoreWLANController
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSApplication.h>	// for event loop modes
#import <CoreWLAN/CoreWLAN.h>
#import <SecurityFoundation/SFAuthorization.h>

NSString * const kCWAssocKey8021XProfile=@"kCWAssocKey8021XProfile";
NSString * const kCWAssocKeyPassphrase=@"kCWAssocKeyPassphrase";
NSString * const kCWBSSIDDidChangeNotification=@"kCWBSSIDDidChangeNotification";
NSString * const kCWCountryCodeDidChangeNotification=@"kCWCountryCodeDidChangeNotification";
NSString * const kCWErrorDomain=@"kCWErrorDomain";
NSString * const kCWIBSSKeyChannel=@"kCWIBSSKeyChannel";
NSString * const kCWIBSSKeyPassphrase=@"kCWIBSSKeyPassphrase";
NSString * const kCWIBSSKeySSID=@"kCWIBSSKeySSID";
NSString * const kCWLinkDidChangeNotification=@"kCWLinkDidChangeNotification";
NSString * const kCWModeDidChangeNotification=@"kCWModeDidChangeNotification";
NSString * const kCWPowerDidChangeNotification=@"kCWPowerDidChangeNotification";
NSString * const kCWScanKeyBSSID=@"kCWScanKeyBSSID";
NSString * const kCWScanKeyDwellTime=@"kCWScanKeyDwellTime";
NSString * const kCWScanKeyMerge=@"kCWScanKeyMerge";
NSString * const kCWScanKeyRestTime=@"kCWScanKeyRestTime";
NSString * const kCWScanKeyScanType=@"kCWScanKeyScanType";
NSString * const kCWScanKeySSID=@"kCWScanKeySSID";
NSString * const kCWSSIDDidChangeNotification=@"kCWSSIDDidChangeNotification";

#if OLD
#if 0	// debugging
#define system(CMD) (printf("system: %s\n", (CMD)), 0)
#endif

extern int system(const char *cmd);
#endif

@interface CWInterface (Private)

#if OLD
+ (BOOL) _bluetoothIsActive;
+ (BOOL) _activateHardware:(BOOL) flag;
#endif

@end

@interface CWNetwork (Private)

- (id) _initWithAttributes:(NSArray *) attributes;

@end

// what is the difference to CWWirelessProfile ???

@implementation CW8021XProfile

+ (NSArray *) allUser8021XProfiles;
{ // all stored profiles for login user
	// where are they stored? In the UserDefaults?
	return nil;
}

+ (CW8021XProfile *) profile; { return [[self new] autorelease]; }

- (CW8021XProfile *) init;
{
	if((self=[super init]))
		{
		
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	CW8021XProfile *p=[CW8021XProfile allocWithZone:zone];
	p->_password=[_password copyWithZone:zone];
	p->_ssid=[_ssid copyWithZone:zone];
	p->_userDefinedName=[_userDefinedName copyWithZone:zone];
	p->_username=[_username copyWithZone:zone];
	p->_alwaysPromptForPassword=_alwaysPromptForPassword;
	return p;
}

- (void) dealloc
{
	[_password release];
	[_ssid release];
	[_userDefinedName release];
	[_username release];
	[super dealloc];
}

- (BOOL) isEqualToProfile:(CW8021XProfile *) profile; 
{
	return [_ssid isEqual:[profile ssid]]
	&& [_password isEqual:[profile password]]
	&& [_username isEqual:[profile username]]
	&& [_userDefinedName isEqual:[profile userDefinedName]]
	&& _alwaysPromptForPassword == [profile alwaysPromptForPassword];
}

- (BOOL) isEqual:(id) other;
{
	return [self isEqualToProfile:other];
}

- (NSUInteger) hash
{
	return [_ssid hash]
	+ [_password hash]
	+ [_username hash]
	+ [_userDefinedName hash]
	+ _alwaysPromptForPassword;
}

- (BOOL) alwaysPromptForPassword; { return _alwaysPromptForPassword; }
- (void) setAlwaysPromptForPassword:(BOOL) flag; { _alwaysPromptForPassword=flag; }

- (NSString *) password; { return _password; }
- (void) setPassword:(NSString *) str; { [_password autorelease]; _password=[str copy]; }
- (NSString *) ssid; { return _ssid; }
- (void) setSsid:(NSString *) str; { [_ssid autorelease]; _ssid=[str copy]; }
- (NSString *) userDefinedName; { return _userDefinedName; }
- (void) setUserDefinedName:(NSString *) name; { [_userDefinedName autorelease]; _userDefinedName=[name copy]; }
- (NSString *) username; { return _username; }
- (void) setUsername:(NSString *) name; { [_username autorelease]; _username=[name copy]; }

// initwithcoder and encode

@end

@implementation CWConfiguration

+ (CWConfiguration *) configuration; { return [[self new] autorelease]; }

- (CWConfiguration *) init;
{
	if((self=[super init]))
		{
		}
	return self;
}

// -copyWithZone // initWithCoder // encodeWithCoder

- (void) dealloc;
{
	[_preferredNetworks release];
	[_rememberedNetworks release];
	[super dealloc];
}

- (BOOL) isEqualToConfiguration:(CWConfiguration *) config;
{
	return [_preferredNetworks isEqualToArray:[config preferredNetworks]]
	&& [_rememberedNetworks isEqualToArray:[config rememberedNetworks]]
	&& 1 /* add remaining flags */;
}

- (BOOL) isEqual:(id) other;
{
	return [self isEqualToConfiguration:other];
}

- (NSUInteger) hash;
{
	return [_preferredNetworks hash]
	+ [_rememberedNetworks hash]
	+ _alwaysRememberNetworks*(1<<0)
	+ _disconnectOnLogout*(1<<1)
	+ _requireAdminForIBSSCreation*(1<<2)
	+ _requireAdminForNetworkChange*(1<<3)
	+ _requireAdminForPowerChange*(1<<4);
}

- (NSArray *) preferredNetworks; { return _preferredNetworks; }
- (void) setPreferredNetworks:(NSArray *) str;
{
	[_preferredNetworks autorelease];
	_preferredNetworks=[str copy];
	// should not contain duplicates
	// make sure that it remains a subset of _rememberedNetworks
}

- (NSArray *) rememberedNetworks; { return _rememberedNetworks; }
- (void) setRememberedNetworks:(NSArray *) str;
{
	[_rememberedNetworks autorelease];
	_rememberedNetworks=[str copy];
	// should not contain duplicates
	// make sure that it remains a superset of _rememberedNetworks
}

- (BOOL) alwaysRememberNetworks; { return _alwaysRememberNetworks; }
- (void) setAlwaysRememberNetworks:(BOOL) flag; { _alwaysRememberNetworks=flag; } 
- (BOOL) disconnectOnLogout; { return _disconnectOnLogout; }
- (void) setDiconnectOnLogout:(BOOL) flag; { _disconnectOnLogout=flag; }
- (BOOL) requireAdminForIBSSCreation; { return _requireAdminForIBSSCreation; }
- (void) setRequireAdminForIBSSCreation:(BOOL) flag; { _requireAdminForIBSSCreation=flag; }
- (BOOL) requireAdminForNetworkChange; { return _requireAdminForNetworkChange; }
- (void) setRequireAdminForNetworkChange:(BOOL) flag; { _requireAdminForNetworkChange=flag; } 
- (BOOL) requireAdminForPowerChange; { return _requireAdminForPowerChange; }
- (void) setRequireAdminForPowerChange:(BOOL) flag; { _requireAdminForPowerChange=flag; }

@end

#if OLD

@interface IWListScanner : NSObject
{ // scan for networks in a background process using iwlist scan command
	NSArray *_modes;
	NSTask *_task;
	NSFileHandle *_stdoutput;
	/* nonretained */ CWInterface *_delegate;	// notify when done by [_delegate _setNetworks:array]
}
@end

@implementation IWListScanner

- (id) init;
{
	if((self=[super init]))
		{
		_modes=[[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil];
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"IWListScanner dealloc");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:nil];
	if(_task && [_task isRunning])
		[_task terminate];
	[_stdoutput release];
	[_task release];
	[_modes release];
	[super dealloc];
}

- (void) setDelegate:(CWInterface *) delegate; { _delegate=delegate; }

- (void) startScanning:(NSError **) err;
{ // start the background process if it is not yet running
#if 0
	NSLog(@"startScanning");
#endif
	if(!_delegate)
		return;
	if(!_task)
		{ // not yet scanning or still waiting for end of last data stream
			NSPipe *p;
#if 0
			NSLog(@"new task");
#endif
			_task=[NSTask new];
			[_task setLaunchPath:@"/sbin/iwlist"];			// on base OS
			[_task setArguments:[NSArray arrayWithObjects:[_delegate name], @"scanning", nil]];
			p=[NSPipe pipe];
			_stdoutput=[[p fileHandleForReading] retain];
			[_task setStandardOutput:p];
			//			[_task setStandardError:p];	// use a single pipe for both stdout and stderr
										// add initializer that we pass the pipe to
										// it does all setup we need...
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateNotification:) name:NSTaskDidTerminateNotification object:_task];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:NSFileHandleReadToEndOfFileCompletionNotification object:_stdoutput];
			[_stdoutput readToEndOfFileInBackgroundAndNotifyForModes:_modes];	// collect data and notify once when done
			NS_DURING
#if 0
			NSLog(@"launch %@", _task);
#endif
			[_task launch];
			NS_HANDLER
			NSLog(@"Could not launch %@ due to %@ because %@.", [_task launchPath], [localException name], [localException reason]);
			NS_ENDHANDLER
		}
}

- (void) stopScanning
{
	[_task terminate];
}

/* sample output

 gta04:~# iwconfig
 lo        no wireless extensions.

 hso0      no wireless extensions.

 usb0      no wireless extensions.

 pan0      no wireless extensions.

 wlan13    IEEE 802.11b/g  ESSID:""
 Mode:Managed  Frequency:2.412 GHz  Access Point: Not-Associated
 Bit Rate:0 kb/s   Tx-Power=15 dBm
 Retry short limit:8   RTS thr=2347 B   Fragment thr=2346 B
 Encryption key:off
 Power Management:off
 Link Quality:0  Signal level:0  Noise level:0
 Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
 Tx excessive retries:0  Invalid misc:0   Missed beacon:0

 gta04:~# ifconfig wlan13   (is down!)
 wlan13    Link encap:Ethernet  HWaddr 00:19:88:3d:ff:eb
 BROADCAST MULTICAST  MTU:1500  Metric:1
 RX packets:0 errors:0 dropped:0 overruns:0 frame:0
 TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
 collisions:0 txqueuelen:1000
 RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

 gta04:~# iwlist wlan13 scan
 wlan13    No scan results

 gta04:~# iwlist wlan13 scanning
 wlan13		Scan completed :
 Cell 01 - Address: 00:**:BF:**:CE:E6
 ESSID:"******"
 Mode:Managed
 Frequency:2.427 GHz (Channel 4)
 Quality=100/100  Signal level=-46 dBm  Noise level=-96 dBm
 Encryption key:off
 Bit Rates:1 Mb/s; 2 Mb/s; 5.5 Mb/s; 6 Mb/s; 9 Mb/s
 11 Mb/s; 12 Mb/s; 18 Mb/s; 24 Mb/s; 36 Mb/s
 48 Mb/s; 54 Mb/s

 another example:

 bb-debian:~# iwlist wlan1 scan
 wlan1     Scan completed :
 Cell 01 - Address: 00:**:**:9B:**:E9
 ESSID:"****-4"
 Mode:Managed
 Frequency:2.417 GHz (Channel 2)
 Quality=96/100  Signal level=-53 dBm  Noise level=-96 dBm
 Encryption key:on
 Bit Rates:1 Mb/s; 2 Mb/s; 5.5 Mb/s; 11 Mb/s; 9 Mb/s
 18 Mb/s; 36 Mb/s; 54 Mb/s; 6 Mb/s; 12 Mb/s
 24 Mb/s; 48 Mb/s
 IE: IEEE 802.11i/WPA2 Version 1
 Group Cipher : CCMP
 Pairwise Ciphers (1) : CCMP
 Authentication Suites (1) : PSK
 Cell 02 - Address: 46:**:**:58:**:D5
 ESSID:"MacBookPro"
 Mode:Ad-Hoc
 Frequency:2.462 GHz (Channel 11)
 Quality=99/100  Signal level=-33 dBm  Noise level=-96 dBm
 Encryption key:off
 Bit Rates:1 Mb/s; 2 Mb/s; 5.5 Mb/s; 6 Mb/s; 9 Mb/s
 11 Mb/s; 12 Mb/s; 18 Mb/s; 24 Mb/s; 36 Mb/s
 48 Mb/s; 54 Mb/s

 bb-debian:~#


 */

- (void) dataReceived:(NSNotification *) n;
{ // all data received
	NSData *data=[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	int err=[[[n userInfo] objectForKey:@"NSFileHandleError"] intValue];
#if 0
	NSLog(@"CoreWLAN dataReceived:_ %@", data);
#endif
	NSString *s=[[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
	NSEnumerator *e=[[s componentsSeparatedByString:@"\n"] objectEnumerator];
	NSString *line;
	NSMutableArray *networks=[NSMutableArray arrayWithCapacity:10];
	NSString *key=@"";	// last key that has been processed
	NSMutableDictionary *attributes=[NSMutableDictionary dictionaryWithCapacity:10];
	while((line=[e nextObject]))
		{
		NSRange r={NSNotFound, 0};
		NSString *prev;
		NSString *value;
#if 0
		NSLog(@"processLine: %@", line);
#endif
			r=[line rangeOfString:@":"];	// key:value
			if(r.location == NSNotFound)
				r=[line rangeOfString:@"="];	// key=value
			if(r.location != NSNotFound)
				{ // (new) key = value
					[key release];
					key=[line substringToIndex:r.location];	// everything up to delimiter
					key=[key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];	// up to delimiter
					[key retain];
					if([key hasSuffix:@"Scan completed"])
						continue;	// ignore
					value=[line substringFromIndex:NSMaxRange(r)];	// take everything behind delimiter
				}
			else
				{ // value only - repeat previous key
					if([key isEqualToString:@"Bit Rates"])
						{
#if 0
						NSLog(@"may be more for Bit Rates");	// continuation line of "Bit Rates"
#endif
						}
					else
						continue;
					value=line;	// take full line
				}
			value=[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];	// from delimiter to end of line
		if([key hasPrefix:@"Cell"])
			{ // special handling for EOF or line starting with "Cell"
				NSArray *cell;
#if 0
				NSLog(@"process %@: %@", key, _attributes);
#endif
				if([attributes count] > 0)
					{ // process previous entry
						CWNetwork *n=[[CWNetwork alloc] initWithAttributes:attributes];
#if 0
						NSLog(@"found %@ %@", n, _attributes);
#endif
						[networks addObject:n];
						[n release];
						[attributes removeAllObjects];	// clear for next record
						[key release];
						key=@"";
					}
				cell=[key componentsSeparatedByString:@" "];
				if([cell count] >= 2)
					[attributes setObject:[cell objectAtIndex:1] forKey:@"Cell"];	// separate cell number
				[key release];
				key=@"Address";
			}
		prev=[attributes objectForKey:key];
		if(prev)
			{ // collect if key is the same
				if([key isEqualToString:@"Bit Rates"])
					value=[NSString stringWithFormat:@"%@; %@", prev, value];	// needs different separator
				else
					value=[NSString stringWithFormat:@"%@ %@", prev, value];
			}
		[attributes setObject:value forKey:key];	// collect all key: value pairs
#if 0
		NSLog(@"attribs: %@", attributes);
#endif
		}
	if([attributes count] > 0)
		{ // process last entry
			CWNetwork *n=[[CWNetwork alloc] initWithAttributes:attributes];
#if 0
			NSLog(@"found %@ %@", n, _attributes);
#endif
			[networks addObject:n];
			[n release];
		}
	[_delegate _setNetworks:networks];	// notify delegate about new network list
}

- (void) terminateNotification:(NSNotification *) n;
{
#if 0
	NSLog(@"CoreWLAN terminateNotification %@", n);
#endif
	if([_task terminationStatus] == 0)
		{ // ok
		}
	[_task release];
	_task=nil;
	[_stdoutput release];
	_stdoutput=nil;
}

@end

#endif

@implementation CWWiFiClient

+ (CWWiFiClient *) sharedWiFiClient;
{
	static CWWiFiClient *sharedWiFiClient;
	if(!sharedWiFiClient)
		sharedWiFiClient=[self new];
	return sharedWiFiClient;
}

+ (NSArray *) interfaceNames;
{
	static NSMutableArray *supportedInterfaces;
	FILE *f=NULL;
	char line[256];
	if(!supportedInterfaces)
		supportedInterfaces=[NSMutableArray new];
#if 1
	else
		return supportedInterfaces;	// collect only once to avoid repeated calls to popen()
#endif
	[NSTask class];	// initialize SIGCHLD or we get problems that system() returns -1 instead of the exit value
	// FIXME: this popen may also timeout and make the process (GUI!) hang!
	// set up NSTask + Timer that interrupts/terminates the task?
	// i.e. task=[NSTask ....]
	// [task performSelector:@(terminate) withObject:nil afterDelay:3];
	f=popen("iwconfig 2>/dev/null", "r");
	if(f)
		{
		while(fgets(line, sizeof(line)-1, f))
			{
			char *e=strchr(line, ' ');
			if(e && e != line)
				{ // non-empty entries are interface names
					NSString *interface=[NSString stringWithCString:line length:e-line];
					if(![supportedInterfaces containsObject:interface])
						[supportedInterfaces addObject:interface];	// new interface found
				}
			}
		pclose(f);
		}
#if 0
	NSLog(@"supportedInterfaces: %@", supportedInterfaces);
#endif
	return supportedInterfaces;
}

- (CWInterface *) interface;
{
	// 	[self _runClient:[NSArray arrayWIthObject:@"ifname"]];
	return [[[CWInterface alloc] init] autorelease];
}

- (CWInterface *) interfaceWithName:(NSString *) name;
{
	return [[[CWInterface alloc] initWithInterfaceName:name] autorelease];
}

@end

@implementation CWInterface

+ (CWInterface *) interface;
{
#if OLD
	return [[self new] autorelease];
#else
	return [[CWWiFiClient sharedWiFiClient] interface];
#endif
}

+ (CWInterface *) interfaceWithName:(NSString *) name;
{
#if OLD
	return [[[self alloc] initWithInterfaceName:name] autorelease];
#else
	return [[CWWiFiClient sharedWiFiClient] interfaceWithName:name];
#endif
}

+ (NSArray *) supportedInterfaces;
{ // may be empty if we don't find interfaces - in this case the client should retry later
#if OLD
	static NSMutableArray *supportedInterfaces;
	FILE *f=NULL;
	char line[256];
	if(!supportedInterfaces)
		supportedInterfaces=[NSMutableArray new];
#if 1
	else
		return supportedInterfaces;	// collect only once to avoid repeated calls to popen()
#endif
	[NSTask class];	// initialize SIGCHLD or we get problems that system() returns -1 instead of the exit value
	if([self _activateHardware:YES])
		{
		// FIXME: this popen may also timeout and make the process (GUI!) hang!
		// set up NSTask + Timer that interrupts/terminates the task?
		// i.e. task=[NSTask ....]
		// [task performSelector:@(terminate) withObject:nil afterDelay:3];
		f=popen("iwconfig 2>/dev/null", "r");
		if(f)
			{
			while(fgets(line, sizeof(line)-1, f))
				{
				char *e=strchr(line, ' ');
				if(e && e != line)
					{ // non-empty entries are interface names
						NSString *interface=[NSString stringWithCString:line length:e-line];
						if(![supportedInterfaces containsObject:interface])
							[supportedInterfaces addObject:interface];	// new interface found
					}
				}
			pclose(f);
			}
		else
			[self _activateHardware:NO];	// can't open
#if 1
		NSLog(@"supportedInterfaces: %@", supportedInterfaces);
#endif
		}
	return supportedInterfaces;
#else
	return [CWWiFiClient interfaceNames];
#endif
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@ if=%@", [super description], [self name]];
}

// FIXME: what do we do if we can't initialize or locate the wlan interface???
// user space code assumes that there is always a CWInterface object
// maybe in state kCWInterfaceStateInactive
// but our hardware does not reveal the interface name unless we can power it on...

// well, we can return an interface without name and add the name as soon as
// it becomes known
// i.e. make interfaceState return kCWInterfaceStateInactive in this case

- (CWInterface *) init;
{
	NSArray *ifs=[CWInterface supportedInterfaces];
	if([ifs count] > 0)
		return [self initWithInterfaceName:[ifs objectAtIndex:0]];	// take the first interface
	[self release];
	return nil;	// could not find any interface - in this case the client should retry later
}

- (CWInterface *) initWithInterfaceName:(NSString *) n;
{ // make them named singletons!
	static NSMutableDictionary *_interfaces;
	CWInterface *inter=[_interfaces objectForKey:n];
	if(inter)
		{
#if 0
		NSLog(@"return singleton %@", inter);
#endif
		[self release];
		return [inter retain];
		}
	if((self=[super init]))
		{
		_name=[n retain];
		if(!_interfaces)
			_interfaces=[[NSMutableDictionary alloc] initWithCapacity:10];
#if 0
		NSLog(@"store singleton %@", self);
#endif
		[_interfaces setObject:self forKey:n];
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"CWInterface dealloc");	// should not happen
#endif
	[_name release];
	[_scanner setDelegate:nil];
	[_scanner release];
	[_modes release];
	[_dataCollector release];
	[super dealloc];
}

- (BOOL) isEqualToInterface:(CWInterface *) interface;
{ 
	return [_name isEqualToString:[interface name]];
}

- (NSUInteger) hash
{
	return [_name hash];
}

- (BOOL) isEqual:(id) other;
{ 
	return [_name isEqualToString:[(CWInterface *) other name]];
}

// FIXME: make thread safe...

- (void) dataReceived:(NSNotification *) n;
{
	NSData *data=[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	if(!data)
		return;
	if(!_dataCollector)
		_dataCollector=[data mutableCopy];
	else
		[_dataCollector appendData:data];
	[[n object] readInBackgroundAndNotifyForModes:_modes];	// collect more data
}

- (NSArray *) _runClient:(NSString *) process args:(NSArray *) args
{ // run command and return result
	NSTask *_task=[[NSTask new] autorelease];
	NSArray *r=nil;
	[_task setLaunchPath:process];			// on base OS
	[_task setArguments:args];
	NSPipe *p=[NSPipe pipe];
	[_task setStandardOutput:p];
	NSFileHandle *_stdoutput=[p fileHandleForReading];
	// [_task setStandardError:p];	// use a single pipe for both stdout and stderr
	// or set standarError:nil
	// add initializer that we pass the pipe to
	// it does all setup we need...
	if(!_modes)
		_modes=[[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil];
	[_dataCollector release];
	_dataCollector=nil;
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateNotification:) name:NSTaskDidTerminateNotification object:_task];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:NSFileHandleReadCompletionNotification object:_stdoutput];
	[_stdoutput readInBackgroundAndNotifyForModes:_modes];	// collect data and notify once when done
	NS_DURING
#if 1
		NSLog(@"launch %@", _task);
#endif
		[_task launch];
	NS_HANDLER
		NSLog(@"Could not launch %@ due to %@ because %@.", [_task launchPath], [localException name], [localException reason]);
	NS_ENDHANDLER
	// waitUntilExit fails if we do not readInBackgroundAndNotifyForModes]
	[_task waitUntilExit];
	if([_task terminationStatus] == 0)
		{
		if(_dataCollector)
			{ // convert string lines into array
				NSString *s=[[[NSString alloc] initWithData:_dataCollector encoding:NSASCIIStringEncoding] autorelease];
				s=[s stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
				r=[s componentsSeparatedByString:@"\n"];
			}
		else
			r=[NSArray array];
		}
#if 1
	NSLog(@"result %d %@", [_task terminationStatus], r);
#endif
	return r;
}

- (NSArray *) _runWPA:(NSString *) cmd;
{ // run simple wpa_cli command
	return [self _runClient:@"/sbin/wpa_cli" args:[NSArray arrayWithObject:cmd]];
}

#if OLD
// FIXME: should be cached and we should re-read value(s) only if older than 1 second since last fetch

- (NSString *) _get:(NSString *) command parameter:(NSString *) parameter
{
	NSString *cmd=[NSString stringWithFormat:@"%@ '%@' %@", command, _name, parameter];
	FILE *f=popen([cmd UTF8String], "r");
	NSString *r;
	char line[512];
	unsigned int n;
	if(!f)
		return nil;
	n=fread(line, 1, sizeof(line)-1, f);
	pclose(f);
	r=[[NSString stringWithCString:line length:n] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
#if 1
	NSLog(@"%@: %@", cmd, r);
#endif
	return r;
}

- (NSString *) _getiw:(NSString *) parameter;
{ // call iwconfig or iwlist or iwgetid
	return [self _get:@"iwgetid" parameter:[NSString stringWithFormat:@"--raw --%@", parameter]];
}

- (NSString *) _getiwlist:(NSString *) parameter;
{ // call iwconfig
	return [self _get:@"iwlist" parameter:parameter];
}

- (NSString *) _getiwconfig;
{ // call iwconfig
	return [self _get:@"iwconfig" parameter:@""];
}
#endif

- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
{ // may block and ask for admin password
#if OLD
	NSString *cmd;
	NSError *dummy;
	if(!err) err=&dummy;
	if(!network)
		{
			// set err
			return NO;
		}
#if 0
	cmd=[NSString stringWithFormat:@"echo ifconfig '%@' up", _name];
#if 1
	NSLog(@"%@", cmd);
#endif
	if(system([cmd UTF8String]) != 0)
		{ // interface does not exist
			// set err
			return NO;
		}		
#endif
	cmd=[NSString stringWithFormat:@"iwconfig '%@' mode '%@' essid -- '%@'", _name, [network isIBSS]?@"ad-hoc":@"managed", [network ssid]];
#if 1
	NSLog(@"%@", cmd);
#endif
	if(system([cmd UTF8String]) != 0)
		{
		// set err
		return NO;
		}
#else
	[self _runClient:@"select_network" args:[NSArray arrayWithObject:@"id"]];
	// set_network_parameters
#endif
	[_associatedNetwork autorelease];
	_associatedNetwork=[network retain];
#if 1
	NSLog(@"associated to %@", network);
#endif
	return YES;
}

- (void) disassociate;
{
	[self _runWPA:@"disconnect"];
	[_associatedNetwork release];
	_associatedNetwork=nil;
}

- (BOOL) enableIBSSWithParameters:(NSDictionary *) params error:(NSError **) err; 
{ // enable as ad-hoc station
#if OLD
	NSString *network=[params objectForKey:kCWIBSSKeySSID];	// get from params or default to machine name
	int channel=[[params objectForKey:kCWIBSSKeyChannel] intValue];	// value may be an NSString
	NSString *cmd;
	NSError *dummy;
	if(!err) err=&dummy;
#if 1
	NSLog(@"parameters %@", params);
#endif
	if(!network)
		network=@"GTA04";	// default; should we use [[NSProcessInfo processInfo] hostName] ?
	if(channel <= 0)
		channel=11;	// default
#if 0
	cmd=[NSString stringWithFormat:@"ifconfig '%@' up", _name];
	if(system([cmd UTF8String]) != 0)
		{
		// set err
		return NO;
		}
#endif
	cmd=[NSString stringWithFormat:@"iwconfig '%@' mode '%@' essid -- '%@' channel '%u' enc 'off'", _name, @"ad-hoc", network, channel];
	if(system([cmd UTF8String]) != 0)
		{
		// set err
		return NO;
		}
	cmd=[NSString stringWithFormat:@"ifconfig '%@' '%@'", _name, @"10.1.1.1"];
	if(system([cmd UTF8String]) != 0)
		{
		// set err
		return NO;
		}
	return YES;
#else
	return NO;
#endif
}

- (void) _setNetworks:(NSArray *) networks;
{ // swap in new network list
#if 1
	NSLog(@"_setNetworks: %@", networks);
#endif
	// wpa_cli add_network
	[_networks autorelease];
	_networks=[networks retain];
}

- (NSArray *) scanForNetworksWithParameters:(NSDictionary*) params error:(NSError **) err;
{
	NSEnumerator *e;
	NSString *line;
	NSMutableArray *nw;
#if OLD
	// should start scanning every 10 seconds
	if(!_scanner)
		{
		_scanner=[IWListScanner new];
		[_scanner setDelegate:self];
		}
	[_scanner startScanning:err];
#else
	// rate limit?
	if(![self _runWPA:@"scan"])	// start scanning - if not yet?
		/*
		 Selected interface 'wlan1'
		 OK
		 */
		return NO;
	e=[[self _runWPA:@"scan_result"] objectEnumerator];
	if(!e)
		return NO;
	/*
	 Selected interface 'wlan1'
	 bssid / frequency / signal level / flags / ssid
	 c0:25:06:e4:8e:cc	2462	-43	[ESS]	DSITRI-3
	 c0:25:06:e4:8e:cb	5200	-60	[ESS]	DSITRI-3-5G
	 */
	[e nextObject];
	[e nextObject];
	nw=[NSMutableArray arrayWithCapacity:10];
	while((line=[e nextObject]))
		{
		CWNetwork *n=[[[CWNetwork alloc] _initWithAttributes:[line componentsSeparatedByString:@"\t"]] autorelease];
		if(!n)
			return nil;	// error
		[nw addObject:n];
		}
	// should we sort or somehow keep sequence stable?
	[self _setNetworks:nw];
#endif
	return _networks;
}

- (SFAuthorization *) authorization; { return _authorization; }
- (void) setAuthorization:(SFAuthorization *) auth; { [_authorization autorelease]; _authorization=[auth retain]; }

// FIXME: store in _associatedNetwork

- (NSString *) bssid;
{
#if OLD
	return [self _getiw:@"ap"];
#else
	return @"?";
#endif
}

//- (NSData *) bssidData; // convert NSString to NSData

- (NSNumber *) channel;	// iwgetid wlan13 --channel
{
#if OLD
	return [NSNumber numberWithInt:[[self _getiw:@"channel"] intValue]];
#else
	return @"?";
#endif
}

- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
{
#if OLD
	NSString *cmd=[NSString stringWithFormat:@"iwconfig '%@' channel %u", _name, (unsigned int) channel];
	NSError *dummy;
	if(!err) err=&dummy;
	if(system([cmd UTF8String]) != 0)
		{
		*err=[NSError errorWithDomain:@"WLAN" code:1 userInfo:nil];
		return NO;
		}
#endif
	return YES;
}

- (BOOL) commitConfiguration:(CWConfiguration *) config error:(NSError **) err;
{ 
	NSError *dummy;
	if(!err) err=&dummy;
#if OLD
	// change current configuration of interface (preferred networks?)
	// there is one configuration for each interface
	// we archive the config in some file - or store it as a NSData in NSUserDefault
#else
	[self _runWPA:@"save_config"];
#endif
	return NO;
}

- (CWConfiguration *) configuration;
{
	// we need one (persistent!) configuration for each interface
	return nil;
}

- (NSString *) countryCode;
{ // no idea how to find out
	return @"";
}

- (NSNumber *) interfaceState;
{
	// FIXME
	// read iwconfig name -> Access Point: Not-Associated or Cell : address
	// or get iwgetid address and check for 00:00:00:00:00:00
#if 0
	NSArray *a=[[self _getiwconfig] componentsSeparatedByString:@"Access Point:"];
	if([a count] >= 2)
		{
		return [NSNumber numberWithFloat:10.0];		
		}
	return [NSNumber numberWithFloat:10.0];
#else
	if(![[self _getiw:@"ap"] hasPrefix:@"00:00:00:00:00:00"])
		return [NSNumber numberWithInt:kCWInterfaceStateRunning];
#endif
	return [NSNumber numberWithInt:kCWInterfaceStateInactive];
}

- (NSString *) name; { return _name; }

- (NSNumber *) noise;
{ // in dBm
	NSArray *a=[[self _getiwconfig] componentsSeparatedByString:@"Noise level:"];
	if([a count] >= 2)
		{
		return [NSNumber numberWithInt:[[a objectAtIndex:1] intValue]];		
		}
	return [NSNumber numberWithInt:-99.0];
}

- (NSNumber *) opMode;
{
	switch([[self _getiw:@"mode"] intValue]) {
		case 2:	return [NSNumber numberWithInt:kCWOpModeStation];
		case 3:	return [NSNumber numberWithInt:kCWOpModeIBSS];
		case 4:	return [NSNumber numberWithInt:kCWOpModeHostAP];
	}
	return nil;	// unknown
}

- (NSNumber *) phyMode;
{ // get current phyMode
	NSString *mode=[self _getiw:@"protocol"];
	if([mode isEqualToString:@"IEEE 802.11b/g"])
		return [NSNumber numberWithInt:kCWPHYMode11G];
/*
 kCWPHYMode11A,
		kCWPHYMode11B,
		kCWPHYMode11G,
		kCWPHYMode11N
*/		
	return nil;
}

- (BOOL) power;
{
	NSString *str=[NSString stringWithContentsOfFile:[NSString stringWithFormat:@"/sys/class/net/%@/flags", _name]];
#if 1
	NSLog(@"power state=%@", str);
#endif
	// FIXME: or should we check if wpa_client status responds?
	// or even both?
	// and is the currently selected interface?
	return [str hasPrefix:@"0x1003"];	// or 0x1002
}

//- (BOOL) powerSave;

- (BOOL) setPower:(BOOL) power error:(NSError **) err;
{
	NSError *dummy;
	if(!err) err=&dummy;
	if([self power] == power)
		return YES;	// no change needed
#if OLD
	// FIXME: we can keep wpa_supplicant running
	// but ifconfig up / down should manage power on/off automatically
	if(power)
		{ // stat wpa_supplicant
			if(system("/root/wlan-on") != 0)
				{ // interface does not exist
				  // set err
					*err=nil;
					return NO;
				}
			sleep(1);
		}
	else
		{
		[self _runClient:@"terminate"];
		// ifdown interface!
		}
#else
	if(power)
		{
		if(![self _runClient:@"/sbin/ifconfig" args:[NSArray arrayWithObjects:_name, @"up", nil]])
			return NO;
		// delete /run/wpa_supplicant/wlan1 to make sure we can start?
		if(![self _runClient:@"/sbin/wpa_supplicant" args:[NSArray arrayWithObjects:@"-B", @"-i", [self name], @"-c", @"/etc/wpa_supplicant/wpa_supplicant.conf", nil]])
			return NO;
		}
	else
		{
		if(![self _runWPA:@"terminate"])
			return NO;
		if(![self _runClient:@"/sbin/ifconfig" args:[NSArray arrayWithObjects:_name, @"down", nil]])
			return NO;
		}
#endif
	return YES;
}

- (NSNumber *) rssi;
{ // in dBm
	NSString *iw=[self _getiwconfig];
	NSArray *a=[iw componentsSeparatedByString:@"Signal level:"];
#if 1
	NSLog(@"iwconfig: %@", a);
#endif
	if([a count] >= 2)
		{
		return [NSNumber numberWithInt:[[a objectAtIndex:1] intValue]];		
		}
	return [NSNumber numberWithInt:-99.0];
}

- (NSNumber *) securityMode;
{
	NSArray *a=[[self _getiwconfig] componentsSeparatedByString:@"Encryption key:"];
	if([a count] >= 2)
		{
		NSString *m=[a objectAtIndex:1];
		if([m hasPrefix:@"off"])
			return [NSNumber numberWithInt:kCWSecurityModeOpen];
#if 1
		NSLog(@"Encryption mode: %@", m);
#endif
		}
	return [NSNumber numberWithInt:kCWSecurityModeOpen];
}

- (NSString *) ssid;
{
	return [self _getiw:@""];
}

- (NSArray *) supportedChannels;
{
	// FIXME: we can read&cache this once per power cycle since it does not change very often...
	NSMutableArray *c=[NSMutableArray arrayWithCapacity:16];
	NSEnumerator *e=[[[self _getiwlist:@"frequency"] componentsSeparatedByString:@"\n"] objectEnumerator];
	NSString *line;
	while((line=[e nextObject]))
		{
		NSArray *a=[line componentsSeparatedByString:@" Channel "];
		if([a count] == 2)
			[c addObject:[NSNumber numberWithInt:[[a objectAtIndex:1] intValue]]];	// copy channel number
		}
	[c sortUsingSelector:@selector(compare:)];
	return c;
}

- (NSArray *) supportedPHYModes;
{
	return [NSArray arrayWithObjects:
			//[NSNumber numberWithInt:kCWPHYMode11A],
			[NSNumber numberWithInt:kCWPHYMode11B],
			[NSNumber numberWithInt:kCWPHYMode11G],
			//[NSNumber numberWithInt:kCWPHYMode11N],
			nil];
}

- (NSNumber *) txPower;
{ // in mW
	NSArray *a=[[self _getiwlist:@"txpower"] componentsSeparatedByString:@"Tx-Power="];
	if([a count] >= 2)
		{
		a=[[a objectAtIndex:1] componentsSeparatedByString:@"("];
		if([a count] >= 2)
			return [NSNumber numberWithInt:[[a objectAtIndex:1] intValue]];	// copy mW value
		}
	return [NSNumber numberWithInt:0];
}

- (NSNumber *) txRate;
{ // in Mbit/s
	NSArray *a=[[self _getiwlist:@"bitrate"] componentsSeparatedByString:@"Current Bit Rate:"];
	if([a count] >= 2)
		return [NSNumber numberWithInt:[[a objectAtIndex:1] intValue]/1000];	// kb/s -> Mbit/s
	return [NSNumber numberWithInt:0];
}

// FIXME: we should link to IOBluetooth and use their method
// FIXME: why do we need this as private method at all?

#if OLD

+ (BOOL) _bluetoothIsActive;
{ // power is up - check if bluetooth is active
	FILE *file;
	char line[256];
	NSString *cmd=@"hciconfig -a";
	file=popen([cmd UTF8String], "r");	// check status
	if(!file)
		return NO;
	/* result looks like
	 hci0:   Type: USB				<- we may have more than one Bluetooth interface!
	 BD Address: 00:06:6E:14:4B:5A ACL MTU: 384:8 SCO MTU: 64:8    <- this is our own address (if we need it)
	 UP RUNNING PSCAN ISCAN
	 RX bytes:154 acl:0 sco:0 events:17 errors:0
	 TX bytes:314 acl:0 sco:0 commands:16 errors:0
	 */
	memset(line, sizeof(line), 0);
	line[fread(line, sizeof(line[0]), sizeof(line)-1, file)]=0; // read as much as we get but not more than buffer holds
	pclose(file);
#if 1
	NSLog(@"_bluetoothIsActive -> %d", strlen(line) > 0);
#endif
	return strlen(line) > 0;	// yes, is active
}
#else

// use 	[[IOBluetoothController sharedController] bluetoothHardwareIsActive];

#endif

@end

@implementation CWInterface (NewerMethods)	// 10.6 and later

- (BOOL) powerOn; { return [self power]; }

/*
 - (BOOL) setPairwiseMasterKey:(NSData *) key
 error:(out NSError **) error;
 - (BOOL) setWEPKey:(NSData *) key
 flags:(CWCipherKeyFlags) flags
 index:(NSInteger) index
 error:(out NSError **) error;
 - (BOOL) setWLANChannel:(CWChannel *) channel
 error:(out NSError **)error;
 - (NSSet *) scanForNetworksWithName:(NSString *) networkName
 error:(out NSError **) error;
 - (NSSet *) scanForNetworksWithSSID:(NSData *)ssid
 error:(out NSError **) error;
 - (BOOL) startIBSSModeWithSSID:(NSData *) ssidData
 security:(CWIBSSModeSecurity) security
 channel:(NSUInteger) channel
 password:(NSString *) password
 error:(out NSError **) error;
 - (BOOL) commitConfiguration:(CWConfiguration *) configuration
 authorization:(SFAuthorization *) authorization
 error:(out NSError **) error;
 - (BOOL) associateToEnterpriseNetwork:(CWNetwork *) network
 identity:(SecIdentityRef) identity
 username:(NSString *) username
 password:(NSString *) password
 error:(out NSError **) error;
 - (BOOL) associateToNetwork:(CWNetwork *) network
 password:(NSString *) password
 error:(out NSError **) error;
 - (BOOL) deviceAttached;
 - (NSString *) interfaceName;
 - (CWPHYMode) activePHYMode;
 - (NSSet *) cachedScanResults;
 - (NSString *) hardwareAddress;
 - (CWInterfaceMode) interfaceMode;
 - (NSInteger) noiseMeasurement;	// dBm
 - (BOOL) powerOn;
 - (NSInteger) rssiValue;
 - (NSSet *) scanForNetworksWithName:(NSString *) networkName
 includeHidden:(BOOL) includeHidden
 error:(out NSError **) error;
 - (NSSet *) scanForNetworksWithSSID:(NSData *)ssid
 includeHidden:(BOOL) includeHidden
 error:(out NSError **) error;
 - (BOOL) serviceActive;
 - (NSData *) ssidData;
 - (NSSet *) supportedWLANChannels;
 - (NSInteger) transmitPower;	// mW
 - (double) transmitRate;	// Mbit/s
 - (CWChannel *)wlanChannel;
*/
@end

@implementation CWNetwork

/* wpa_cli scan_result:
bssid / frequency / signal level / flags / ssid
c0:25:06:e4:8e:cc	2462	-43	[ESS]	DSITRI-3
c0:25:06:e4:8e:cb	5200	-60	[ESS]	DSITRI-3-5G
here we get one line
*/

- (id) _initWithAttributes:(NSArray *) attribs
{ // initialize with attributes
#if 0
	NSLog(@"attributes=%@", attribs);
#endif
	if([attribs count] != 5)
		{
		[self release];
		return nil;
		}
	if((self=[self init]))
		{
		_bssid=[[attribs objectAtIndex:0] retain];
		// _channel = convert from frequency
		_ieData=nil;
		_isIBSS=NO;
		//			_noise=[[NSNumber alloc] initWithFloat:(float)[[q objectAtIndex:0] intValue]];	//something like 49/70
		_rssi=[[NSNumber alloc] initWithFloat:(float)[[attribs objectAtIndex:2] intValue]];
#if 0
			NSLog(@"rssi = %@", _rssi);
#endif
		// _phyMode=[[NSNumber alloc] initWithInt:kCWPHYMode11N];	// get from Bit Rates entry and Frequency
		_securityMode=kCWSecurityModeOpen;	// encoded in flags?
		_ssid=[[attribs objectAtIndex:4] retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	CWNetwork *n=[CWNetwork allocWithZone:zone];
	n->_bssid=[_bssid copyWithZone:zone];
	n->_channel=[_channel copyWithZone:zone];
	n->_ieData=[_ieData copyWithZone:zone];
	n->_noise=[_noise copyWithZone:zone];
	n->_phyMode=[_phyMode copyWithZone:zone];
	n->_rssi=[_rssi copyWithZone:zone];
	n->_securityMode=[_securityMode copyWithZone:zone];
	n->_ssid=[_ssid copyWithZone:zone];
	return n;
}

- (void) dealloc;
{
#if 0
	NSLog(@"dealloc %@", self);
#endif
	[_bssid release];
	[_channel release];
	[_ieData release];
	[_noise release];
	[_phyMode release];
	[_rssi release];
	[_securityMode release];
	[_ssid release];
	[super dealloc];
}

- (BOOL) isEqualToNetwork:(CWNetwork *) network;
{ // ssid, securityMode, isIBSS
	return [_ssid isEqual:[network ssid]] &&
			[_securityMode isEqual:[network securityMode]] &&
			_isIBSS == [network isIBSS];
}

- (BOOL) isEqual:(id) other
{
	return [self isEqualToNetwork:other];
}

- (NSUInteger) hash
{
	return [_ssid hash] + [_securityMode hash] + _isIBSS;
}

- (NSString *) bssid; { return _bssid; }
- (NSData *) bssidData; { return [_bssid dataUsingEncoding:NSUTF8StringEncoding]; }	// FIXME: MAC address binary...
- (NSNumber *) channel; { return _channel; }
- (NSData *) ieData; { return _ieData; }
- (BOOL) isIBSS; { return _isIBSS; }
- (NSNumber *) noise; { return _noise; }
- (NSNumber *) phyMode; { return _phyMode; }
- (NSNumber *) rssi; { return _rssi; }
- (NSInteger) rssiValue; { return [_rssi integerValue]; }
- (NSNumber *) securityMode; { return _securityMode; }
- (NSString *) ssid; { return _ssid; }	// ??? what is the difference to bssid?

- (CWWirelessProfile *) wirelessProfile;
{ // get from database (based on SSID)
	NSDictionary *profiles=nil;	// get from NSUserDefaults
	return [profiles objectForKey:_ssid];
}

// setWirelessProfile?

// initwithcoder
// encodewithcoder

@end

@implementation CWWirelessProfile

+ (CWWirelessProfile *) profile; { return [[self new] autorelease]; }

/*
- (BOOL) isEqualToProfile:(CWWirelessProfile *) profile;
 - (BOOL) isEqual:(id) other;
 - (NSUInteger) hash;
*/

- (NSString *) passphrase; { return _passphrase; }
- (void) setPassphrase:(NSString *) str;
{
	[_passphrase autorelease];
	_passphrase=[str copy];
}

- (NSNumber *) securityMode; { return _mode; }
- (void) setSecurityMode:(NSNumber *) mode;
{
	[_mode autorelease];
	_mode=[mode copy];
}

- (NSString *) ssid; { return _ssid; }
- (void) setSsid:(NSString *) ssid;
{
	[_ssid autorelease];
	_ssid=[ssid copy];
}

- (CW8021XProfile *) user8021XProfile; { return _profile; }
- (void) setUser8021XProfile:(CW8021XProfile *) profile;
{
	[_profile autorelease];
	_profile=[profile copy];
}

@end
