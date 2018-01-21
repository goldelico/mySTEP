//
//  CWNetwork.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CWWirelessProfile;

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

// Checkme: which ones are on Mac and which ones are our extensions?

- (NSString *) bssid;	// this is the (unique!) MAC address of the base station
- (NSData *) bssidData;
- (NSNumber *) channel;
- (NSData *) ieData;
- (BOOL) isIBSS;
- (NSNumber *) noise;
- (NSNumber *) phyMode;
- (NSNumber *) rssi;
- (NSInteger) rssiValue;
- (NSNumber *) securityMode;
- (NSString *) ssid;	// this is the network name (may be built from different bssids)
- (CWWirelessProfile *) wirelessProfile;

@end
