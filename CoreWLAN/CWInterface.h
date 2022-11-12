//
//  CWInterface.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLANConstants.h>
#import <CoreWLAN/CoreWLANTypes.h>
#import <CoreWLAN/CWInterface.h>

@class CWConfiguration;
@class CWNetwork;
@class SFAuthorization;

@interface CWInterface : NSObject
{
	NSArray *_networks;	// networks found after last scanForNetworksWithParameters:
	NSString *_name;
	SFAuthorization *_authorization;
	id _scanner;	// internal type
	CWNetwork *_associatedNetwork;
	// add cached values and timestamps
	NSArray *_modes;
	NSMutableData *_dataCollector;
}

#if 1	// deprecated
- (CWInterface *) init;
- (CWInterface *) initWithInterfaceName:(NSString *) name;
+ (CWInterface *) interface;
+ (CWInterface *) interfaceWithName:(NSString *) name;
+ (NSArray *) interfaceNames;
#endif

- (BOOL) commitConfiguration:(CWConfiguration *) config authorization:(SFAuthorization *) auth error:(NSError **) err;
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
- (NSString *) bssid;
- (NSSet *) cachedScanResults;
- (CWConfiguration *) configuration;
- (NSString *) countryCode;
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
- (CWSecurity) security;
- (BOOL) serviceActive;
- (NSString *) ssid;
- (NSData *) ssidData;
- (NSSet *) supportedWLANChannels;
- (NSInteger) transmitPower;	// mW
- (double) transmitRate;	// Mbit/s
- (CWChannel *) wlanChannel;

@end

#if 0	// OLD STUFF
#if 0	// really old
- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
#endif
- (void) disassociate;
- (BOOL) enableIBSSWithParameters:(NSDictionary *) params error:(NSError **) err; 
- (BOOL) isEqualToInterface:(CWInterface *) interface;
- (NSArray *) scanForNetworksWithParameters:(NSDictionary *) params error:(NSError **) err;
- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
- (BOOL) setPower:(BOOL) power error:(NSError **) err;

// ... tons of properties
- (SFAuthorization *) authorization;
- (void) setAuthorization:(SFAuthorization *) auth;

- (NSData *) bssidData;
- (NSNumber *) channel;
- (NSNumber *) interfaceState;
- (NSString *) name;
- (NSNumber *) noise;	// in dBm
- (NSNumber *) opMode;
- (NSNumber *) phyMode;
- (BOOL) power;
- (BOOL) powerSave;
- (NSNumber *) rssi;	// in dBm
- (NSNumber *) securityMode;
- (NSArray *) supportedChannels;
- (NSArray *) supportedPHYModes;
- (BOOL) supportsAES_CCM;
- (BOOL) supportsHostAP;
- (BOOL) supportsIBSS;
- (BOOL) supportsMonitorMode;
- (BOOL) supportsPMGT;
- (BOOL) supportsShortGI20MHz;
- (BOOL) supportsShortGI40MHz;
- (BOOL) supportsTKIP;
- (BOOL) supportsTSN;
- (BOOL) supportsWEP;
- (BOOL) supportsWME;
- (BOOL) supportsWoW;
- (BOOL) supportsWPA;
- (BOOL) supportsWPA2;
- (NSNumber *) txPower;	// in mW
- (NSNumber *) txRate;	// in Mbit/s
@end

@class CWChannel;
typedef NSInteger CWCipherKeyFlags;
typedef NSInteger CWIBSSModeSecurity;
typedef NSInteger CWInterfaceMode;
#ifdef __mySTEP__
typedef void *SecIdentityRef;
#endif

@interface CWInterface (NewerMethods)	// 10.6 and later

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

#endif
