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

#if 0	// debugging
#define system(CMD) (printf("system: %s\n", (CMD)), 0)
#endif

extern int system(const char *cmd);

@interface CWInterface (Private)

+ (BOOL) _bluetoothIsActive;
+ (BOOL) _activateHardware:(BOOL) flag;

@end

@interface CWNetwork (Private)

- (id) initWithAttributes:(NSDictionary *) attributes;

@end

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

@implementation CWInterface

+ (CWInterface *) interface;
{
	return [[self new] autorelease];
}

+ (CWInterface *) interfaceWithName:(NSString *) name;
{
	return [[[self alloc] initWithInterfaceName:name] autorelease];	
}

+ (NSArray *) supportedInterfaces;
{ // may be empty if we don't find interfaces - in this case the client should retry later
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
#if 0
		NSLog(@"supportedInterfaces: %@", supportedInterfaces);
#endif
		}
	return supportedInterfaces;
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
	NSArray *ifs=[CWInterface supportedInterfaces];	// this will power on
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

- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
{ // may block and ask for admin password
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
	[_associatedNetwork autorelease];
	_associatedNetwork=[network retain];
#if 1
	NSLog(@"associated to %@", network);
#endif
	return YES;
}
 
- (void) disassociate;
{
	[_associatedNetwork release];
	_associatedNetwork=nil;
	// CHECKME: is that really a disassociate?
	// FIXME: we should set SSID="" to disassociate
//	NSString *cmd=[NSString stringWithFormat:@"ifconfig '%@' down", _name];
//	system([cmd UTF8String]);
}

- (BOOL) enableIBSSWithParameters:(NSDictionary *) params error:(NSError **) err; 
{ // enable as ad-hoc station
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
}

- (void) _setNetworks:(NSArray *) networks;
{ // swap in new network list
#if 0
	NSLog(@"_setNetworks: %@", networks);
#endif
	[_networks autorelease];
	_networks=[networks retain];
}

- (NSArray *) scanForNetworksWithParameters:(NSDictionary*) params error:(NSError **) err;
{
	// should start scanning every 10 seconds
	if(!_scanner)
		{
		_scanner=[IWListScanner new];
		[_scanner setDelegate:self];
		}
	[_scanner startScanning:err];
	return _networks;	// already scanning - return what we know
}

- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
{
	NSString *cmd=[NSString stringWithFormat:@"iwconfig '%@' channel %u", _name, (unsigned int) channel];
	NSError *dummy;
	if(!err) err=&dummy;
	if(system([cmd UTF8String]) != 0)
		{
		*err=[NSError errorWithDomain:@"WLAN" code:1 userInfo:nil];		
		return NO;
		}
	return YES;
}

- (BOOL) setPower:(BOOL) power error:(NSError **) err;
{
	NSError *dummy;
	NSString *cmd;
	if(!err) err=&dummy;
	if([self power] == power)
		return YES;	// no change needed
	if(power)
		cmd=[NSString stringWithFormat:@"ifconfig '%@' up", _name];
	else
		cmd=[NSString stringWithFormat:@"ifconfig '%@' down", _name];
	if(system([cmd UTF8String]) != 0)
		{ // interface does not exist
			// set err
			*err=nil;
			return NO;
		}
	sleep(1);
	return YES;
	
#if 0	// has no result on our hardware
	NSString *cmd=[NSString stringWithFormat:@"iwconfig '%@' power '%@'", _name, power?@"on":@"off"];
	if(system([cmd UTF8String]) != 0)
		{
		if(err)
			*err=[NSError errorWithDomain:@"WLAN" code:1 userInfo:nil];
		return NO;
		}
	return YES;
#else
	return [CWInterface _activateHardware:power];	// we should count activations/deactivations
#endif
}

- (SFAuthorization *) authorization; { return _authorization; }
- (void) setAuthorization:(SFAuthorization *) auth; { [_authorization autorelease]; _authorization=[auth retain]; }

// FIXME: store in _associatedNetwork

- (NSString *) bssid;
{
	return [self _getiw:@"ap"];
}

//- (NSData *) bssidData; // convert NSString to NSData

- (NSNumber *) channel;	// iwgetid wlan13 --channel
{
	return [NSNumber numberWithInt:[[self _getiw:@"channel"] intValue]];
}

- (BOOL) commitConfiguration:(CWConfiguration *) config error:(NSError **) err;
{ 
	NSError *dummy;
	if(!err) err=&dummy;
	// change current configuration of interface (preferred networks?)
	// there is one configuration for each interface
	// we archive the config in some file - or store it as a NSData in NSUserDefault
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
#if 0
	NSLog(@"power state=%@", str);
#endif
	return [str hasPrefix:@"0x1003"];	// or 0x1002
}

//- (BOOL) powerSave;

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

+ (BOOL) _activateHardware:(BOOL) flag;
{
	return YES;	// no longer required on >= 3.7 kernel
}

@end

@implementation CWNetwork

/*
 gta04:~# iwlist wlan13 scanning     
 wlan13    Scan completed :
			Cell 01 - Address: 00:**:BF:**:CE:E6
			ESSID:"******"
			Mode:Managed
			Frequency:2.427 GHz (Channel 4)
			Quality=100/100  Signal level=-46 dBm  Noise level=-96 dBm
			Encryption key:off
			Bit Rates:1 Mb/s; 2 Mb/s; 5.5 Mb/s; 6 Mb/s; 9 Mb/s
					11 Mb/s; 12 Mb/s; 18 Mb/s; 24 Mb/s; 36 Mb/s
					48 Mb/s; 54 Mb/s
 
*/

/* NSDictionary:
 attributes={
 Address = B2:9C:**:D4:**:CC;
 "Bit Rates" = "1 Mb/s; 2 Mb/s; 5.5 Mb/s; 6 Mb/s; 9 Mb/s";
 Cell = 01;
 ESSID = "MacBookPro";
 "Encryption key" = off;
 Frequency = "2.462 GHz (Channel 11)";
 Mode = "Ad-Hoc";
 Quality = "97/100  Signal level=-29 dBm  Noise level=-96 dBm";
 }
*/

// post-process "Frequency" into freq & channel
// post-process "Quailty" into quality and level
// post-process bit rates into array

- (id) initWithAttributes:(NSDictionary *) attribs
{ // initialize with attributes
#if 0
	NSLog(@"attributes=%@", attribs);
#endif
	if((self=[self init]))
		{
		NSArray *f=[[attribs objectForKey:@"Frequency"] componentsSeparatedByString:@" "];
		// FIXME: format isn't very stable... sometimes separates by :and sometimes by =
		NSArray *q=[[attribs objectForKey:@"Quality"] componentsSeparatedByString:@"="];
		NSArray *r=[[attribs objectForKey:@"Bit Rates"] componentsSeparatedByString:@";"];
		NSString *m=[attribs objectForKey:@"Mode"];
#if 0
		NSLog(@"frequency: %@", f);
		NSLog(@"quality: %@", q);
#endif
		_bssid=[[attribs objectForKey:@"Address"] retain];
		if([f count] >= 4)
			_channel=[[NSNumber alloc] initWithInt:[[f objectAtIndex:3] intValue]];
		_ieData=nil;
		_isIBSS=[m hasPrefix:@"Ad-Hoc"];
		if([q count] >= 2)
			{
			_noise=[[NSNumber alloc] initWithFloat:(float)[[q objectAtIndex:0] intValue]];	//something like 49/70
			_rssi=[[NSNumber alloc] initWithFloat:(float)[[q objectAtIndex:1] intValue]];
#if 0
			NSLog(@"rssi = %@", _rssi);
#endif
			// quality [[q objectAtIndex:1] intValue]
			}
		_phyMode=[[NSNumber alloc] initWithInt:kCWPHYMode11N];	// get from Bit Rates entry and Frequency
		_securityMode=kCWSecurityModeOpen;
		m=[attribs objectForKey:@"Encryption key"];
		if([m hasPrefix:@"off"])
			_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeOpen];
		else 
			{ // assume "on"
			  // process multiple entries!
				m=[attribs objectForKey:@"IE"];
				if([m hasPrefix:@"WEP"])
					_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeWEP];
				else if([m hasPrefix:@"WEP"])
					_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeWPA_PSK];
				else if([m hasPrefix:@"IEEE 802.11i/WPA2 Version 1"])
					_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeWPA2_PSK];
				else if([m hasPrefix:@"Unknown:"])
					;
				else
					NSLog(@"unknown Encryption: %@", m);
			}
		_ssid=[[[attribs objectForKey:@"ESSID"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]] retain];
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
	return [_ssid isEqual:[network ssid]]
	&& [_securityMode isEqual:[network securityMode]]
	&& _isIBSS == [network isIBSS];
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

// initwithcoder
// encodewithcoder

@end

@implementation CWWirelessProfile

+ (CWWirelessProfile *) profile; { return [[self new] autorelease]; }

/*
- (CWWirelessProfile *) init; 
- (BOOL) isEqualToProfile:(CWWirelessProfile *) profile; 
 - (BOOL) isEqual:(id) other; 
 - (NSUInteger) hash;

- (NSString *) passphrase;
- (void) setPassphrase:(NSString *) str;	// copy
- (NSNumber *) securityMode;
- (void) setSecurityMode:(NSNumber *) str;
- (NSString *) ssid;
- (void) setSsid:(NSString *) name;
- (CW8021XProfile *) user8021XProfile;
- (void) setUser8021XProfile:(CW8021XProfile *) name;
*/

@end
