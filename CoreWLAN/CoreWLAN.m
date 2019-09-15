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

@interface CWNetwork (Private)

- (id) _initWithBssid:(NSString *) bssid interface:(CWInterface *) interface;

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
	return [[CWWiFiClient sharedWiFiClient] interface];
}

+ (CWInterface *) interfaceWithName:(NSString *) name;
{
	return [[CWWiFiClient sharedWiFiClient] interfaceWithName:name];
}

+ (NSArray *) supportedInterfaces;
{ // may be empty if we don't find interfaces - in this case the client should retry later
	return [CWWiFiClient interfaceNames];
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

- (void) _dataReceived:(NSNotification *) n;
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
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSTask *_task=[NSTask new];
	NSArray *r=nil;
	[_task setLaunchPath:process];			// on base OS
	[_task setArguments:args];
	NSPipe *p=[NSPipe pipe];
	[_task setStandardOutput:p];
	NSFileHandle *stdoutput=[p fileHandleForReading];
	// [_task setStandardError:p];	// use a single pipe for both stdout and stderr
	// or set standarError:nil
	// add initializer that we pass the pipe to
	// it does all setup we need...
	if(!_modes)
		_modes=[[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil];
	[_dataCollector release];
	_dataCollector=nil;
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateNotification:) name:NSTaskDidTerminateNotification object:_task];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_dataReceived:) name:NSFileHandleReadCompletionNotification object:stdoutput];
	[stdoutput readInBackgroundAndNotifyForModes:_modes];	// collect data and notify once when done
	NS_DURING
#if 1
		NSLog(@"launch: %@ %@", process, [args componentsJoinedByString:@" "]);
#endif
		[_task launch];
	NS_HANDLER
		NSLog(@"Could not launch %@ due to %@ because %@.", [_task launchPath], [localException name], [localException reason]);
	NS_ENDHANDLER
	// waitUntilExit fails if we do not readInBackgroundAndNotifyForModes]
	[_task waitUntilExit];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:stdoutput];
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
	[r retain];
	[_task release];
	[arp release];
	[r autorelease];	// carry to outer ARP
	return r;
}

- (NSArray *) _runWPA:(NSString *) cmd arg:(NSString *) arg;
{ // run simple wpa_cli command witn one argument
#if 0 // may we have to switch interface first if we are not the current interface???
	  // but currently we do not handle multiple interfaces
	static NSString *currentInterface;
	if([_name isEqualToString:currentInterface])
		{ // has changed
			if(![self _runClient:@"/sbin/wpa_cli" args:[NSArray arrayWithObjects:@"interface", _name, nil]])
				return nil;	// can't change
			[currentInterface release];
			currentInterface=[_name retain];
		}
#endif
	return [self _runClient:@"/sbin/wpa_cli" args:[NSArray arrayWithObjects:cmd, arg, nil]];
}

- (NSArray *) _runWPA:(NSString *) cmd;
{ // run simple wpa_cli command with no arguments
	return [self _runWPA:cmd arg:nil];
}

- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
{ // may block and ask for admin password
	if([self _runClient:@"select_network" args:[network _id]])
		{
		[_associatedNetwork autorelease];
		_associatedNetwork=[network retain];
		return YES;
		}
	return NO;
}

- (void) disassociate;
{
	if(_associatedNetwork)
		{
		[self _runWPA:@"disconnect" args:[_associatedNetwork _id]];
		[_associatedNetwork release];
		_associatedNetwork=nil;
		}
}

- (BOOL) enableIBSSWithParameters:(NSDictionary *) params error:(NSError **) err; 
{ // enable as ad-hoc station
	NSString *network=[params objectForKey:kCWIBSSKeySSID];	// get from params or default to machine name
	int channel=[[params objectForKey:kCWIBSSKeyChannel] intValue];	// value may be an NSString
	NSError *dummy;
	if(!err) err=&dummy;
#if 1
	NSLog(@"parameters %@", params);
#endif
	if(!network)
		network=@"Letux";	// default; should we use [[NSProcessInfo processInfo] hostName] ?
	if(channel <= 0)
		channel=11;	// default
	return NO;
}

- (NSSet *) cachedScanResults;
{
	return [NSSet setWithArray:_networks];
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
		NSRange rng=[line rangeOfString:@"\t"];
		NSString *bssid=[line substringToIndex:rng.location];
		CWNetwork *n=[[[CWNetwork alloc] _initWithBssid:bssid interface:self] autorelease];
		if(!n)
			return nil;	// error
		[nw addObject:n];
		}
	// should we sort or somehow keep sequence stable?
	[self _setNetworks:nw];
	return _networks;
}

- (SFAuthorization *) authorization; { return _authorization; }
- (void) setAuthorization:(SFAuthorization *) auth; { [_authorization autorelease]; _authorization=[auth retain]; }

- (NSString *) bssid;
{
	return [_associatedNetwork bssid];
}

- (NSData *) bssidData;
{ // convert NSString to NSData
	return nil;
}

- (NSNumber *) channel;
{
	return [[[[CWNetwork alloc] _initWithBssid:[self bssid] interface:self] autorelease] channel];
}

- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
{
	return YES;
}

- (BOOL) commitConfiguration:(CWConfiguration *) config error:(NSError **) err;
{ 
	NSError *dummy;
	if(!err) err=&dummy;
	return [self _runWPA:@"save_config"] != nil;
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
	return [NSNumber numberWithInt:kCWInterfaceStateRunning];
#if OLD
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
#endif
}

- (NSString *) name; { return _name; }
- (NSString *) interfaceName; { return _name; }

- (NSNumber *) noise;
{ // in dBm
	return [[[[CWNetwork alloc] _initWithBssid:[self bssid] interface:self] autorelease] noise];
}

- (NSNumber *) opMode;
{
	return [NSNumber numberWithInt:kCWOpModeStation];
#if OLD
	switch([[self _getiw:@"mode"] intValue]) {
		case 2:	return [NSNumber numberWithInt:kCWOpModeStation];
		case 3:	return [NSNumber numberWithInt:kCWOpModeIBSS];
		case 4:	return [NSNumber numberWithInt:kCWOpModeHostAP];
	}
	return nil;	// unknown
#endif
}

- (NSNumber *) phyMode;
{ // get current phyMode
	return nil;
#if OLD
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
#endif
}

- (BOOL) power;
{ // check if ifconfig up and wpa_supplicant is running
	NSString *str=[NSString stringWithContentsOfFile:[NSString stringWithFormat:@"/sys/class/net/%@/flags", _name]];
#if 1
	NSLog(@"power state=%@", str);
#endif
	if(![str hasPrefix:@"0x1003"])	// or 0x1002
		return NO;
	return [self _runWPA:@"status"] != nil;
}

- (BOOL) powerSave;
{
	return NO;
}

- (BOOL) setPower:(BOOL) power error:(NSError **) err;
{
	NSError *dummy;
	if(!err) err=&dummy;
	if([self power] == power)
		return YES;	// no change needed
	if(power)
		{
		if(![self _runClient:@"/sbin/ifconfig" args:[NSArray arrayWithObjects:_name, @"up", nil]])
			return NO;
		if(![self _runClient:@"/sbin/wpa_supplicant" args:[NSArray arrayWithObjects:@"-B", @"-i", [self name], @"-c", @"/etc/wpa_supplicant/wpa_supplicant.conf", nil]])
			{ // failed
				if(![self _runWPA:@"status"])
					{ // but does not respond
						NSLog(@"wpa_supplicant is already running but it does not respond");
						// kill and
						// delete /run/wpa_supplicant/wlan1 to make sure we can start?
						return NO;
					}
				else
					NSLog(@"wpa_supplicant is already running");
			};
		}
	else
		{
		[self _runWPA:@"terminate"];	// ignore errors
		if(![self _runClient:@"/sbin/ifconfig" args:[NSArray arrayWithObjects:_name, @"down", nil]])
			return NO;
		}
	return YES;
}

- (NSNumber *) rssi;
{ // in dBm
	return [[[[CWNetwork alloc] _initWithBssid:[self bssid] interface:self] autorelease] rssiValue];
}

- (NSNumber *) securityMode;
{
	return [[[[CWNetwork alloc] _initWithBssid:[self bssid] interface:self] autorelease] securityMode];
}

- (NSString *) ssid;
{
	return [_associatedNetwork ssid];
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

@end

@implementation CWInterface (NewerMethods)	// 10.6 and later

/*
 - (BOOL) setPairwiseMasterKey:(NSData *) key error:(out NSError **) error;
 - (BOOL) setWEPKey:(NSData *) key flags:(CWCipherKeyFlags) flags index:(NSInteger) index error:(out NSError **) error;
 - (BOOL) setWLANChannel:(CWChannel *) channel error:(out NSError **)error;
 - (NSSet *) scanForNetworksWithName:(NSString *) networkName error:(out NSError **) error;
 - (NSSet *) scanForNetworksWithSSID:(NSData *)ssid error:(out NSError **) error;
 - (BOOL) startIBSSModeWithSSID:(NSData *) ssidData security:(CWIBSSModeSecurity) security channel:(NSUInteger) channel password:(NSString *) password error:(out NSError **) error;
 - (BOOL) commitConfiguration:(CWConfiguration *) configuration authorization:(SFAuthorization *) authorization error:(out NSError **) error;
 - (BOOL) associateToEnterpriseNetwork:(CWNetwork *) network identity:(SecIdentityRef) identity username:(NSString *) username password:(NSString *) password error:(out NSError **) error;
 - (BOOL) associateToNetwork:(CWNetwork *) network password:(NSString *) password error:(out NSError **) error;
 - (BOOL) deviceAttached;
 - (CWPHYMode) activePHYMode;
 - (CWInterfaceMode) interfaceMode;
 - (NSSet *) scanForNetworksWithName:(NSString *) networkName includeHidden:(BOOL) includeHidden error:(out NSError **) error;
 - (NSSet *) scanForNetworksWithSSID:(NSData *)ssid includeHidden:(BOOL) includeHidden error:(out NSError **) error;
 - (BOOL) serviceActive;
 - (NSSet *) supportedWLANChannels;
 - (CWChannel *)wlanChannel;
*/

- (NSString *) hardwareAddress;
{
	// get local MAC address
	return @"?";
}

- (NSInteger) noiseMeasurement;	// dBm
{
	return [[self noise] integerValue];
}

- (BOOL) powerOn; { return [self power]; }

- (NSInteger) rssiValue;
{ // in dBm
	return [[self rssi] integerValue];
}

- (NSData *) ssidData;
{ // convert NSString to NSData
	return nil;
}

- (NSInteger) transmitPower;
{
	return [[self txPower] integerValue];
}

- (double) transmitRate;	// Mbit/s
{
	return [[self txRate] doubleValue];
}

@end

@implementation CWNetwork

/* wpa_cli scan_result:
 wpa_cli bss c0:25:06:e4:8e:cc
 id=2
 bssid=c0:25:06:e4:8e:cc
 freq=2462
 beacon_int=100
 capabilities=0x0421
 qual=0
 noise=0
 level=-33
 tsf=0000000069346696
 age=74
 ie=00084453495452492d33010882848b968c12982403010b0706444520010d142a01003204b048606c2d1ace111bffff0000000000000000000001000000000000000000003d160b0f06000000000000000000000000000000000000007f080000000000000040dd180050f2020101000003a4000027a4000042435e0062322f00dd0900037f01010000ff7fdd0c00040e010102010000000000
 flags=[ESS]
 ssid=DSITRI-3*/

// an alternative would be to store everything in an NSDictionary
// and ket the key->value inside the getters
// would also simplify copy and be extensible

- (id) _initWithBssid:(NSString *) bssid interface:(CWInterface *) interface
{ // initialize with attributes
#if 0
	NSLog(@"bssid=%@", bssid);
#endif
	if(!bssid)
		{
		[self release];
		return nil;
		}
	if((self=[self init]))
		{
		NSArray *bssattribs;
		NSEnumerator *e;
		NSString *line;
		bssattribs=[interface _runWPA:@"bss" arg:bssid];	// get more info
		if(!bssattribs)
			{
			[self release];
			return nil;
			}
		e=[bssattribs objectEnumerator];
		while((line=[e nextObject]))
			{
			NSRange rng=[line rangeOfString:@"="];
			NSString *key;
			NSString *value;
			if(rng.location == NSNotFound)
				{
				[self release];
				return nil;
				}
			key=[line substringToIndex:rng.location];
			value=[line substringFromIndex:NSMaxRange(rng)];
			if([key isEqualToString:@"id"])
				;
			else if([key isEqualToString:@"bssid"])
				[_bssid release], _bssid=[value retain];
			else if([key isEqualToString:@"freq"])
				;	// convert to channel number
			else if([key isEqualToString:@"qual"])
				;
			else if([key isEqualToString:@"noise"])
				;
			else if([key isEqualToString:@"level"])
				;
			else if([key isEqualToString:@"ie"])
				[_ieData release], _ieData=[value retain];
			else if([key isEqualToString:@"ssid"])
				[_ssid release], _ssid=[value retain];
			else
				NSLog(@"unknown key %@ value %@", key, value);
			}
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
- (NSString *) ssid; { return _ssid; }

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
