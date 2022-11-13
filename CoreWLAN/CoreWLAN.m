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

  More up-to date is:
	   https://developer.apple.com/documentation/corewlan?language=objc

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

- (void) encodeWithCoder:(NSCoder *) coder
{

}

- (id) initWithCoder:(NSCoder *) coder
{
	return nil;
}

@end

@implementation CWConfiguration

+ (CWConfiguration *) configuration; { return [[self new] autorelease]; }
+ (CWConfiguration *) configurationWithConfiguration:(CWConfiguration *) other;
{
	return [[[self alloc] initWithConfiguration:other] autorelease];
}

- (id) init;
{
	if((self=[super init]))
		{
		}
	return self;
}

- (id) initWithConfiguration:(CWConfiguration *) other;
{
	if((self=[super init]))
		{
		// copy values
		}
	return self;
}

- (void) dealloc;
{
	[_networkProfiles release];
	[super dealloc];
}

- (BOOL) isEqualToConfiguration:(CWConfiguration *) config;
{
	return [_networkProfiles isEqualToOrderedSet:[config networkProfiles]]
	&& [self rememberJoinedNetworks] == [config rememberJoinedNetworks]
	&& [self requireAdministratorForAssociation] == [config requireAdministratorForAssociation]
	&& [self requireAdministratorForIBSSMode] == [config requireAdministratorForIBSSMode]
	&& [self requireAdministratorForPower] == [config requireAdministratorForPower];
}

- (BOOL) isEqual:(id) other;
{
	return [self isEqualToConfiguration:other];
}

- (NSUInteger) hash;
{
	return [_networkProfiles hash]
	+ [self rememberJoinedNetworks] * (1<<2)
	+ [self requireAdministratorForAssociation] * (1<<3)
	+ [self requireAdministratorForIBSSMode] * (1<<5)
	+ [self requireAdministratorForPower] * (1<<7);
}

- (NSOrderedSet *) networkProfiles;	{ return _networkProfiles; }
- (BOOL) rememberJoinedNetworks; { return _rememberJoinedNetworks; }
- (BOOL) requireAdministratorForAssociation; { return _requireAdministratorForAssociation; }
- (BOOL) requireAdministratorForIBSSMode; { return _requireAdministratorForIBSSMode; }
- (BOOL) requireAdministratorForPower; { return _requireAdministratorForPower; }

- (id) copyWithZone:(NSZone *) zone
{
	return [[CWConfiguration alloc] initWithConfiguration:self];
}

- (id) mutableCopyWithZone:(NSZone *) zone
{
	return [[CWMutableConfiguration alloc] initWithConfiguration:self];
}

- (void) encodeWithCoder:(NSCoder *) coder
{

}

- (id) initWithCoder:(NSCoder *) coder
{
	return nil;
}

@end

@implementation CWMutableConfiguration
- (void) setRememberJoinedNetworks:(BOOL) flag;
{

}
- (void) setRequireAdministratorForAssociation:(BOOL) flag;
{

}
- (void) setRequireAdministratorForIBSSMode:(BOOL) flag;
{

}
- (void) setRequireAdministratorForPower:(BOOL) flag;
{

}
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
#if 1	// does not work if an USB WiFi stick is plugged in
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

- (id) delegate; { return _delegate; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }

- (NSArray *) interfaces;
{
	static NSMutableArray *allInterfaces;
	if(!allInterfaces)
		{
		NSEnumerator *e=[[CWInterface interfaceNames] objectEnumerator];
		NSString *name;
		CWInterface *i;
		allInterfaces=[[NSMutableArray alloc] initWithCapacity:10];
		while((name=[e nextObject]))
			{
			i=[[CWInterface alloc] initWithInterfaceName:name];
			[allInterfaces addObject:i];
			[i release];
			}
		}
	return allInterfaces;
}

- (CWInterface *) interface;	// default interface
{
	return [[self interfaces] lastObject];
}

- (CWInterface *) interfaceWithName:(NSString *) name;
{
	NSEnumerator *e=[[self interfaces] objectEnumerator];
	CWInterface *i;
	while((i=[e nextObject]))
		if([[i interfaceName] isEqualToString:name])
			return i;
	return nil;
}

/* 10.10 */
- (BOOL) startMonitoringEventWithType:(CWEventType) type error:(NSError **) error; { return NO; }
- (BOOL) stopMonitoringAllEventsAndReturnError:(NSError **) error; { return NO; }
- (BOOL) stopMonitoringEventWithType:(CWEventType) type error:(NSError **) error; { return NO; }

@end

@implementation CWInterface

- (id) initWithInterfaceName:(NSString *) n;
{
	if((self=[super init]))
		{
		_name=[n retain];
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

+ (CWInterface *) interface;
{
	return [[CWWiFiClient sharedWiFiClient] interface];
}

+ (CWInterface *) interfaceWithName:(NSString *) name;
{
	return [[CWWiFiClient sharedWiFiClient] interfaceWithName:name];
}

+ (NSArray *) interfaceNames;
{
	return [CWWiFiClient interfaceNames];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@ if=%@", [super description], [self interfaceName]];
}

- (BOOL) isEqualToInterface:(CWInterface *) interface;
{ 
	return [_name isEqualToString:[interface interfaceName]];
}

- (NSUInteger) hash
{
	return [_name hash];
}

- (BOOL) isEqual:(id) other;
{ 
	return [_name isEqualToString:[(CWInterface *) other interfaceName]];
}

// low level functions

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

// high level functions

- (BOOL) commitConfiguration:(CWConfiguration *) config
			   authorization:(SFAuthorization *) auth
					   error:(NSError **) err;
{
	NSError *dummy;
	if(!err) err=&dummy;
	[_authorization autorelease];
	_authorization=[auth retain];
	return [self _runWPA:@"save_config"] != nil;
}

- (BOOL) associateToEnterpriseNetwork:(CWNetwork *) network
							 identity:(SecIdentityRef) identity
							 username:(NSString *) username
							 password:(NSString *) password
								error:(out NSError **) error;
{
	return NO;
}

- (BOOL) associateToNetwork:(CWNetwork *) network password:(NSString *) password error:(NSError **) err;
{ // may block and ask for admin password
	if([self _runWPA:@"select_network" arg:[network ssid]])
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
		[self _runWPA:@"disconnect" arg:[_associatedNetwork ssid]];
		[_associatedNetwork release];
		_associatedNetwork=nil;
		}
}

- (BOOL) deviceAttached; { return YES; }

- (BOOL) startIBSSModeWithSSID:(NSData *) ssidData
					  security:(CWIBSSModeSecurity) security
					   channel:(NSUInteger) channel
					  password:(NSString *) password
						 error:(NSError **) error;
{ // enable as ad-hoc station
//	NSString *network=[params objectForKey:kCWIBSSKeySSID];	// get from params or default to machine name
	NSError *dummy;
	if(!error) error=&dummy;
#if 0
	NSLog(@"parameters %@", params);
#endif
//	if(!network)
//		network=@"Letux";	// default; should we use [[NSProcessInfo processInfo] hostName] ?
	if(channel <= 0)
		channel=11;	// default
	// do the setup
	return NO;
}

- (NSString *) interfaceName; { return _name; }

- (CWPHYMode) activePHYMode; { return kCWPHYMode11ac; }

- (NSString *) bssid;
{
	return [_associatedNetwork bssid];
}

- (NSData *) bssidData;
{ // convert NSString to NSData
	return nil;
}

- (NSSet *) cachedScanResults; { return _networks; }

- (CWConfiguration *) configuration;
{
	// we need one (persistent!) configuration for each interface
	return nil;
}

- (NSString *) countryCode;
{ // no idea how to find out
	return @"";
}

- (NSString *) hardwareAddress;
{
// 	return [self _getiw:@"ap"] hasPrefix:@"00:00:00:00:00:00"];
	return nil;
}

- (CWInterfaceMode) interfaceMode; { return 0; }

- (NSInteger) noiseMeasurement;
{ // dBm
	return 0;
}

- (BOOL) powerOn;
{ // check if ifconfig up and wpa_supplicant is running
	NSString *str=[NSString stringWithContentsOfFile:[NSString stringWithFormat:@"/sys/class/net/%@/flags", _name]];
#if 1
	NSLog(@"power state=%@", str);
#endif
	if(![str hasPrefix:@"0x1003"])	// or 0x1002
		return NO;
	return [self _runWPA:@"status"] != nil;
}

- (NSInteger) rssiValue;
{
	return 0;
}

- (NSSet *) scanForNetworksWithName:(NSString *) networkName
					  includeHidden:(BOOL) includeHidden
							  error:(NSError **) error;
{
	NSEnumerator *e;
	NSString *line;
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
	[_networks release];
	_networks=[[NSMutableSet alloc] initWithCapacity:10];
	while((line=[e nextObject]))
		{
		NSRange rng=[line rangeOfString:@"\t"];
		NSString *bssid=[line substringToIndex:rng.location];
		// filter with Name (pattern)
		CWNetwork *n=[[[CWNetwork alloc] _initWithBssid:bssid interface:self] autorelease];
		if(!n)
			return nil;	// error
		[_networks addObject:n];
		}
	// wpa_cli add_network
	return _networks;
}

- (NSSet *) scanForNetworksWithSSID:(NSData *) ssid
					  includeHidden:(BOOL) includeHidden
							  error:(NSError **) error;
{
	return nil;
}

- (CWSecurity) security; { return 0; }
- (BOOL) serviceActive; { return YES; }
- (BOOL) setPairwiseMasterKey:(NSData *) key
						error:(NSError **) error;
{
	return NO;
}

- (BOOL) setPower:(BOOL) power error:(NSError **) err;
{
	NSError *dummy;
	if(!err) err=&dummy;
	if([self powerOn] == power)
		return YES;	// no change needed
	if(power)
		{
		if(![self _runClient:@"/sbin/ifconfig" args:[NSArray arrayWithObjects:_name, @"up", nil]])
			return NO;
		if(![self _runClient:@"/sbin/wpa_supplicant" args:[NSArray arrayWithObjects:@"-B", @"-i", [self interfaceName], @"-c", @"/etc/wpa_supplicant/wpa_supplicant.conf", nil]])
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

- (BOOL) setWEPKey:(NSData *) key
			 flags:(CWCipherKeyFlags) flags
			 index:(NSInteger) index
			 error:(NSError **) error;
{
	return NO;
}
- (BOOL) setWLANChannel:(CWChannel *) channel
				  error:(NSError **)error;
{
	return NO;
}

- (NSString *) ssid;
{
	return [_associatedNetwork ssid];
}
- (NSData *) ssidData;
{
	return [_associatedNetwork ssidData];
}
- (NSSet *) supportedWLANChannels;
{
	return nil;
}

- (NSInteger) transmitPower;
{ // mW
	return 0;
}

- (double) transmitRate;
{ // Mbit/s
	return 0;
}

- (CWChannel *) wlanChannel;
{
	return nil;
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
	return [_ssid isEqual:[network ssid]];
}

- (BOOL) isEqual:(id) other
{
	return [self isEqualToNetwork:other];
}

- (NSUInteger) hash
{
	return [_ssid hash];
}

- (NSInteger) beaconInterval; { return NSNotFound; }	// in ms
- (NSString *) bssid; { return _bssid; }
- (NSString *) countryCode; { return @"?"; }
- (BOOL) ibss; { return _isIBSS; }
- (NSData *) informationElementData; { return _ieData; }
- (NSInteger) noiseMeasurement;	{ return [_noise integerValue]; }
- (NSInteger) rssiValue; { return [_rssi integerValue]; }
- (NSString *) ssid; { return _ssid; }
- (NSData *) ssidData; { return nil; }
- (CWChannel *) wlanChannel; { return nil; }

- (void) encodeWithCoder:(NSCoder *) coder {

}

- (id) initWithCoder:(NSCoder *) coder {
	return nil;
}

@end

@implementation CWNetworkProfile

- (id) initWithNetworkProfile:(CWNetworkProfile *) other;
{
	// FIXME: copy all
	return self;
}

- (void) dealloc
{
//	[_passphrase release]
	[_ssid release];
	[super dealloc];
}

+ (CWNetworkProfile *) networkProfile; { return [[self new] autorelease]; }
+ (CWNetworkProfile *) networkProfileWithNetworkProfile:(CWNetworkProfile *) other; { return [[[self alloc] initWithNetworkProfile:other] autorelease]; }

/*
- (BOOL) isEqualToProfile:(CWWirelessProfile *) profile;
- (BOOL) isEqual:(id) other;
- (NSUInteger) hash;
*/

- (CWSecurity) security; { return _mode; }
- (NSString *) ssid; { return [[[NSString alloc] initWithData:_ssid encoding:NSUTF8StringEncoding] autorelease]; }	// convert _ssid to string
- (NSData *) ssidData; { return _ssid; }

- (id) copyWithZone:(NSZone *) zone {
	return nil;
}

- (id) mutableCopyWithZone:(NSZone *) zone {
	return nil;
}

- (void) encodeWithCoder:(NSCoder *) coder {

}

- (id) initWithCoder:(NSCoder *) coder {
	return nil;
}

@end

@implementation CWMutableNetworkProfile

- (void) setSsid:(NSString *) ssid;
{
	[_ssid autorelease];
	_ssid=[[ssid dataUsingEncoding:NSUTF8StringEncoding] retain];
}

- (void) setSsidData:(NSData *) ssid;
{
	[_ssid autorelease];
	_ssid=[ssid copy];
}

- (void) setSecurity:(CWSecurity) security;
{
	_mode=security;
}
@end
