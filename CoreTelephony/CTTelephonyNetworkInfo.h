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

- (void) subscriberCellularProviderDidUpdate:(CTCarrier *) carrier;

@end

@interface CTTelephonyNetworkInfo : NSObject

- (CTCarrier *) subscriberCellularProvider;

@end

@interface CTTelephonyNetworkInfo (Extensions)

- (id <CTNetworkInfoDelegate>) delegate;
- (void) setDelegate:(id <CTNetworkInfoDelegate>) delegate;

- (CTCarrier *) currentNetwork;	// different during roaming
- (NSSet *) networks;	// list of networks being available

@end