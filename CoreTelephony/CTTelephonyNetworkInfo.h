//
//  CTTelephonyNetworkInfo.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CTCarrier;

@protocol CTNetworkInfoDelegate

- (void) subscriberCellularProviderDidUpdate:(CTCarrier *) carrier;	// SIM card was changed
- (void) currentNetworkDidUpdate:(CTCarrier *) carrier;	// roaming or connected/disconnected from Internet
- (void) currentCellDidUpdate:(CTCarrier *) carrier;	// mobile operation
- (void) signalStrengthDidUpdate:(CTCarrier *) carrier;	// also called for network type changes

@end

@interface CTTelephonyNetworkInfo : NSObject
{
	CTCarrier *subscriberCellularProvider;
	CTCarrier *currentNetwork;
	id <CTNetworkInfoDelegate> delegate;
	int paTemp;
}

+ (CTTelephonyNetworkInfo *) telephonyNetworkInfo;
- (CTCarrier *) subscriberCellularProvider;

@end

@interface CTTelephonyNetworkInfo (Extensions)

- (id <CTNetworkInfoDelegate>) delegate;
- (void) setDelegate:(id <CTNetworkInfoDelegate>) delegate;

- (CTCarrier *) currentNetwork;	// changes while roaming
- (NSSet *) networks;	// set of networks (CTCarrier) that are available

// FIXME: this is not really related to the NetworkInfo! It should be accessible through the modem manager
- (float) paTemperature;	// temperature of PA in centigrade

@end
