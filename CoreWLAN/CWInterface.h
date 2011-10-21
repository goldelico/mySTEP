//
//  CWInterface.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CWConfiguration;
@class CWNetwork;
@class SFAuthorization;

@interface CWInterface : NSObject
{
	NSString *_name;
	SFAuthorization *_authorization;
}

+ (NSArray *) supportedInterfaces;

+ (CWInterface *) interface;
+ (CWInterface *) interfaceWithName:(NSString *) name;

- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
- (BOOL) commitConfiguration:(CWConfiguration *) config error:(NSError **) err;
- (void) disassociate;
- (BOOL) enableIBSSWithParameters:(NSDictionary *) params; 
- (CWInterface *) init;
- (CWInterface *) initWithInterfaceName:(NSString *) name;
- (BOOL) isEqualToInterface:(CWInterface *) interface;
- (NSArray *) scanForNetworksWithParameters:(NSDictionary*) params error:(NSError **) err;
- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
- (BOOL) setPower:(BOOL) power error:(NSError **) err;

// ... tons of properties
- (SFAuthorization *) authorization;
- (void) setAuthorization:(SFAuthorization *) auth;

- (NSString *) bssid; 
- (NSData *) bssidData; 
- (NSNumber *) channel; 
- (CWConfiguration *) configuration;
- (NSString *) countryCode;
- (NSNumber *) interfaceState;
- (NSString *) name;
- (NSNumber *) noise;	// in dBm
- (NSNumber *) opMode;
- (NSNumber *) phyMode;
- (BOOL) power;
- (BOOL) powerSave;
- (NSNumber *) rssi;	// in dBm
- (NSNumber *) securityMode;
- (NSString *) ssid;
- (NSNumber *) txPower;	// in mW
- (NSNumber *) txRate;	// in Mbit/s

@end
