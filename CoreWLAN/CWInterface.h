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
	NSMutableSet *_networks;	// networks found after last scanForNetworksWithParameters:
	NSString *_name;
	SFAuthorization *_authorization;
	id _scanner;	// internal type
	CWNetwork *_associatedNetwork;
	// add cached values and timestamps
	NSArray *_modes;
	NSMutableData *_dataCollector;
}

#if 1	// deprecated
/* - (CWInterface *) init; */
- (id) initWithInterfaceName:(NSString *) name;
+ (CWInterface *) interface;
+ (CWInterface *) interfaceWithName:(NSString *) name;
+ (NSArray *) interfaceNames;
- (BOOL) startIBSSModeWithSSID:(NSData *) ssidData
					  security:(CWIBSSModeSecurity) security
					   channel:(NSUInteger) channel
					  password:(NSString *) password
						 error:(NSError **) error;
- (BOOL) isEqualToInterface:(CWInterface *) interface;
#endif

#ifdef __mySTEP__
typedef void *SecIdentityRef;
#endif

- (BOOL) associateToEnterpriseNetwork:(CWNetwork *) network
							 identity:(SecIdentityRef) identity
							 username:(NSString *) username
							 password:(NSString *) password
								error:(NSError **) error;
- (BOOL) associateToNetwork:(CWNetwork *) network
				   password:(NSString *) password
					  error:(NSError **) error;
- (void) disassociate;
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
							  error:(NSError **) error;
- (NSSet *) scanForNetworksWithSSID:(NSData *) ssid
					  includeHidden:(BOOL) includeHidden
							  error:(NSError **) error;
- (CWSecurity) security;
- (BOOL) serviceActive;
- (BOOL) setPairwiseMasterKey:(NSData *) key
						error:(NSError **) error;
- (BOOL) setPower:(BOOL) power error:(NSError **) err;
- (BOOL) setWEPKey:(NSData *) key
			 flags:(CWCipherKeyFlags) flags
			 index:(NSInteger) index
			 error:(NSError **) error;
- (BOOL) setWLANChannel:(CWChannel *) channel
				  error:(NSError **)error;
- (NSString *) ssid;
- (NSData *) ssidData;
- (NSSet *) supportedWLANChannels;
- (NSInteger) transmitPower;	// mW
- (double) transmitRate;	// Mbit/s
- (CWChannel *) wlanChannel;

@end
