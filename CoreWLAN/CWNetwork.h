//
//  CWNetwork.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWNetwork : NSObject <NSCopying, NSCoding>
{
	NSString *_bssid;
	NSNumber *_channel;
	NSData *_ieData;
	NSNumber *_noise;
	NSNumber *_phyMode;
	NSNumber *_rssi;
	NSNumber *_securityMode;
	NSString *_ssid;
	BOOL _isIBSS;
}

- (BOOL) isEqualToNetwork:(CWNetwork *) network;		// obnly checks same ssid, securityMode and isIBSS

- (NSInteger) beaconInterval;	// in ms
- (NSString *) bssid;	// this is the (unique!) MAC address of the base station
- (NSString *) countryCode;
- (BOOL) ibss;	// should this be isIbss by some getter?
- (NSData *) informationElementData;
- (NSInteger) noiseMeasurement;	// dBm
- (NSInteger) rssiValue;	// dBm
- (NSString *) ssid;	// this is the network name (may be built from different bssids)
- (NSData *) ssidData;
- (CWChannel *) wlanChannel;

@end
