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

- (unsigned int) hash
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

- (unsigned int) hash;
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

@implementation CWInterface

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

/*
 * we could also run a global iweven in a NSTask to get notifications about wireless events
 */

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
{
	if((self=[super init]))
		{
		_name=[n retain];
		}
	return self;
}

- (void) dealloc;
{
	[_name release];
	[super dealloc];
}

- (BOOL) isEqualToInterface:(CWInterface *) interface;
{ 
	return [_name isEqualToString:[interface name]];
}

- (unsigned int) hash;
{
	return [_name hash];
}

- (BOOL) isEqual:(id) other;
{ 
	return [_name isEqualToString:[(CWInterface *) other name]];
}

// FIXME: should be cached and reread value(s) only if older than 1 second since last fetch

- (NSString *) _getiw:(NSString *) parameter;
{ // call iwconfig or iwlist or iwgetid
	NSString *cmd=[NSString stringWithFormat:@"iwgetid '%@' --raw --%@", _name, parameter];
	FILE *f=popen([cmd UTF8String], "r");
	char line[512];
	if(!f)
		return nil;
	fgets(line, sizeof(line)-1, f);
	fclose(f);
#if 1
	NSLog(@"%@: %@", parameter, [[NSString stringWithCString:line] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
#endif
	return [[NSString stringWithCString:line] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) _getiwlist:(NSString *) parameter;
{ // call iwconfig
	NSString *cmd=[NSString stringWithFormat:@"iwlist '%@' %@", _name, parameter];
	FILE *f=popen([cmd UTF8String], "r");
	char line[512];
	unsigned int n;
	if(!f)
		return nil;
	n=fread(line, 1, sizeof(line)-1, f);
	fclose(f);
#if 1
	NSLog(@"%@: %@", parameter, [[NSString stringWithCString:line length:n] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
#endif
	return [[NSString stringWithCString:line length:n] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) _getiwconfig;
{ // call iwconfig
	NSString *cmd=[NSString stringWithFormat:@"iwconfig '%@'", _name];
	FILE *f=popen([cmd UTF8String], "r");
	char line[512];
	unsigned int n;
	if(!f)
		return nil;
	n=fread(line, 1, sizeof(line)-1, f);
	fclose(f);
#if 1
	NSLog(@"%@", [[NSString stringWithCString:line length:n] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
#endif
	return [[NSString stringWithCString:line length:n] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
{
	NSString *cmd;
	NSError *dummy;
	if(!err) err=&dummy;
	if(!network)
		{
			// set err
			return NO;
		}
	cmd=[NSString stringWithFormat:@"echo ifconfig '%@' up", _name];
	if(system([cmd UTF8String]) != 0)
		{ // interface does not exist
			// set err
			return NO;
		}		
	cmd=[NSString stringWithFormat:@"iwconfig '%@' mode '%@' essid -- '%@'", _name, [network isIBSS]?@"ad-hoc":@"managed", [network ssid]];
	if(system([cmd UTF8String]) != 0)
		{
		// set err
		return NO;
		}
	return YES;
}
 
- (void) disassociate;
{
	// CHECKME: is that really a disassociate?
	// FIXME: we should set SSID="" to disassociate
	NSString *cmd=[NSString stringWithFormat:@"ifconfig '%@' down", _name];
	system([cmd UTF8String]);
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
	cmd=[NSString stringWithFormat:@"ifconfig '%@' up", _name];
	if(system([cmd UTF8String]) != 0)
		{
		// set err
		return NO;
		}
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

- (NSArray *) scanForNetworksWithParameters:(NSDictionary*) params error:(NSError **) err;
{ // is blocking! Should be implemented thread-safe because it is most likely not running in the main thread...
	NSString *cmd;
	FILE *f;
	NSMutableArray *a;
	char line[256];
	NSError *dummy;
	NSMutableDictionary *attributes=[NSMutableDictionary dictionaryWithCapacity:15];
	CWNetwork *n;
	if(!err) err=&dummy;
	cmd=[NSString stringWithFormat:@"ifconfig '%@' up", _name];
	if(system([cmd UTF8String]) != 0)
		{ // interface does not exist
			// set err
			return NO;
		}		
	cmd=[NSString stringWithFormat:@"iwlist '%@' scanning", _name];
#if 1
	NSLog(@"popen %@", cmd);
#endif
	f=popen([cmd UTF8String], "r");
	if(!f)
		{
		*err=[NSError errorWithDomain:@"WLAN" code:1 userInfo:nil];
		return nil;
		}
	a=[NSMutableArray arrayWithCapacity:10];
	/*
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
	 */
	while(fgets(line, sizeof(line)-1, f))
		{
		char *s;
		NSString *key;
		NSString *value;
		printf("line=%s", line);
		s=strchr(line, ':');
		if(!s)
			s=strchr(line, '=');
		if(!s)
			// may be "No scan results"
			// if available, append to "Bit Rates"
			continue;
		key=[[NSString stringWithCString:line length:s-line] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];	// up to delimiter
		if([key hasSuffix:@"Scan completed"])
			continue;	// ignore
		value=[[NSString stringWithCString:s+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];	// from delimiter to end of line
		if([key hasPrefix:@"Cell"])
			{
			NSArray *cell;
			if([attributes count] > 0)
				{ // process previous entry
				n=[[CWNetwork alloc] initWithAttributes:attributes];
				[a addObject:n];
				[n release];
				[attributes removeAllObjects];	// clear for next record
				}
			cell=[key componentsSeparatedByString:@" "];
			if([cell count] >= 2)
				[attributes setObject:[cell objectAtIndex:1] forKey:@"Cell"];	// separate cell number
			key=@"Address";
			}
		[attributes setObject:value forKey:key];	// collect
		}
	if([attributes count] > 0)
		{ // add last record
			n=[[CWNetwork alloc] initWithAttributes:attributes];
			if(n)
				[a addObject:n];
			[n release];
		}
	pclose(f);
#if 1
	NSLog(@"pclose %@", cmd);
#endif
	return a;
}

- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
{
	NSString *cmd=[NSString stringWithFormat:@"iwconfig '%@' channel %u", _name, channel];
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
	if(!err) err=&dummy;
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
	return [[NSString stringWithContentsOfFile:@"/sys/devices/platform/reg-virt-consumer.4/max_microvolts"] intValue] > 0;
}

//- (BOOL) powerSave;

- (NSNumber *) rssi;
{ // in dBm
	NSArray *a=[[self _getiwconfig] componentsSeparatedByString:@"Signal level:"];
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
#if 1
	NSLog(@"WLAN _activateHardware:%d", flag);
#endif
	if(flag)
		{ // power on
			if([[NSString stringWithContentsOfFile:@"/sys/devices/platform/reg-virt-consumer.4/max_microvolts"] intValue] > 0)
				{
#if 1
				NSLog(@"WLAN already powered on");
#endif
				return YES;	// already powered on
				}
#if 1
			NSLog(@"WLAN power on");
#endif
			if(system("VDD=3150000;"
					  "echo \"255\" >/sys/class/leds/tca6507:6/brightness &&"
					  "echo \"$VDD\" >/sys/devices/platform/reg-virt-consumer.4/max_microvolts &&"
					  "echo \"$VDD\" >/sys/devices/platform/reg-virt-consumer.4/min_microvolts &&"
					  "echo \"normal\" >/sys/devices/platform/reg-virt-consumer.4/mode &&"
					  "echo \"0\" >/sys/class/leds/tca6507:6/brightness") != 0)
				{
				NSLog(@"VAUX4 power on failed");
				return NO;	// something failed
				}
			// we should wait until libertas becomes available
			return YES;
		}
	else
		{
		if([[NSString stringWithContentsOfFile:@"/sys/devices/platform/reg-virt-consumer.4/max_microvolts"] intValue] == 0)
			{
#if 1
			NSLog(@"WLAN already powered down");
#endif
			return YES;				
			}
		if([self _bluetoothIsActive])
			{
#if 1
			NSLog(@"WLAN not powered down (Bluetooth still active)");
#endif
			return YES;	// if bluetooth is still on - ignore
			}
#if 1
		NSLog(@"WLAN power off");
#endif
		system("echo \"255\" >/sys/class/leds/tca6507:6/brightness;"
			   "echo 0 >/sys/devices/platform/reg-virt-consumer.4/max_microvolts");
		return YES;
		}
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

- (id) initWithAttributes:(NSDictionary *) attribs
{ // initialize with attributes
	NSLog(@"attributes=%@", attribs);
	if((self=[self init]))
		{
		NSArray *f=[[attribs objectForKey:@"Frequency"] componentsSeparatedByString:@" "];
		NSArray *q=[[attribs objectForKey:@"Quality"] componentsSeparatedByString:@"="];
		NSString *m=[attribs objectForKey:@"Mode"];
		_bssid=[[attribs objectForKey:@"Address"] retain];
		if([f count] >= 4)
			_channel=[[NSNumber alloc] initWithInt:[[f objectAtIndex:3] intValue]];
		_ieData=nil;
		_isIBSS=[m hasPrefix:@"Ad-Hoc"];
		if([q count] >= 3)
			{
			_noise=[[NSNumber alloc] initWithFloat:(float)[[q objectAtIndex:2] intValue]];
			_rssi=[[NSNumber alloc] initWithFloat:(float)[[q objectAtIndex:1] intValue]];
			// quality [[q objectAtIndex:1] intValue]
			}
		_phyMode=[[NSNumber alloc] initWithInt:kCWPHYMode11N];	// get from Bit Rates entry and Frequency
		_securityMode=kCWSecurityModeOpen;
		m=[attribs objectForKey:@"Encryption key"];
		if([m hasPrefix:@"off"])
			_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeOpen];
		else 
			{ // assume "on"
				m=[attribs objectForKey:@"IE"];
				if([m hasPrefix:@"WEP"])
					_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeWEP];
				else if([m hasPrefix:@"WEP"])
					_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeWPA_PSK];
				else if([m hasPrefix:@"IEEE 802.11i/WPA2 Version 1"])
					_securityMode=[[NSNumber alloc] initWithInt:kCWSecurityModeWPA2_PSK];
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
//	NSLog(@"dealloc %@", self);
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

- (unsigned int) hash
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
- (unsigned int) hash;
 
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
