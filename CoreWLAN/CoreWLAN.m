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
 
  Examples how to use see e.g.
		http://dougt.org/wordpress/2009/09/usingcorewlan/
		http://lists.apple.com/archives/macnetworkprog/2009/Sep/msg00007.html
		Apple CoreWLANController
 */

#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>
// SFAuthentication.h

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

@implementation CW8021XProfile
/*
+ (NSArray *) allUser8021XProfiles;
+ (CW8021XProfile *) profile; 

- (CW8021XProfile *) init; 
- (BOOL) isEqualToProfile:(CW8021XProfile *) profile; 

- (BOOL) alwaysPromptForPassword;
- (void) setAlwaysPromptForPassword:(BOOL) flag; 
// all are copy
- (NSString *) password;
- (void) setPassword:(NSString *) str;
- (NSString *) ssid;
- (void) setSsid:(NSString *) str;
- (NSString *) userDefinedName;
- (void) setUserDefinedName:(NSString *) name;
- (NSString *) username;
- (void) setUsername:(NSString *) name;
*/
@end

@implementation CWConfiguration
/*
+ (CWConfiguration *) configuration; 

- (CWConfiguration *) init; 
- (BOOL) isEqualToConfiguration:(CWConfiguration *) config; 

- (BOOL) alwaysRememberNetworks;
- (void) setAlwaysRememberNetworks:(BOOL) flag; 
- (BOOL) disconnectOnLogout;
- (void) setDiconnectOnLogout:(BOOL) flag; 
- (BOOL) requireAdminForIBSSCreation;
- (void) setRequireAdminForIBSSCreation:(BOOL) flag; 
- (BOOL) requireAdminForNetworkChange;
- (void) setRequireAdminForNetworkChange:(BOOL) flag; 
- (BOOL) requireAdminForPowerChange;
- (void) setRequireAdminForPowerChange:(BOOL) flag; 

// all are copy
- (NSArray *) preferredNetworks;
- (void) setPreferredNetworks:(NSArray *) str;
- (NSArray *) rememberedNetworks;
- (void) setRememberedNetworks:(NSArray *) str;
*/
@end

@implementation CWInterface
/*
- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
- (BOOL) commitConfiguration:(CWConfiguration *) config error:(NSError **) err;
- (void) disassociate;
- (BOOL) enableIBSSWithParameters:(NSDictionary *) params; 
- (CWInterface *) init;
- (CWInterface *) initWithInterfaceName:(NSString *) name;
+ (CWInterface *) interface;
+ (CWInterface *) interfaceWithName:(NSString *) name;
- (BOOL) isEqualToInterface:(CWInterface*)interface;
- (NSArray *) scanForNetworksWithParameters:(NSDictionary*) params error:(NSError **) err;
- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
- (BOOL) setPower:(BOOL) power error:(NSError **) err;
+ (NSArray *) supportedInterfaces;

// ... properties
*/
@end

@implementation CWNetwork
/*

- (BOOL) isEqualToNetwork:(CWNetwork *) network; 

// some of these are also available through CWInterface (so use subclassing/forwarding?)

- (NSString *) bssid;
- (NSData *) bssidData;
- (NSNumber *) channel;
- (NSData *) ieData;
- (BOOL) isIBSS;
- (NSNumber *) noise;
- (NSNumber *) phyMode;
- (NSNumber *) rssi;
- (NSNumber *) securityMode;
- (NSString *) ssid;
- (CWWirelessProfile *) irelessProfile;
*/
@end

@implementation CWWirelessProfile
/*

+ (CWWirelessProfile *) profile; 

- (CWWirelessProfile *) init; 
- (BOOL) isEqualToProfile:(CWWirelessProfile *) profile; 

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
