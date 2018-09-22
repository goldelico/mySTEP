//
//  BluetoothPrivate.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#ifdef __mySTEP__
#import <SystemStatus/NSSystemStatus.h>

#if OLD
// new version to be based on bluez

#define id objc_id
//#include <new/bluetooth/bluez.h>
#include <bluetooth/bluetooth.h>	// from usr/bluetooth
// conflicts with Bluetooth.h
#undef id

#endif

#else

#import <Cocoa/Cocoa.h>
#import "IOBluetoothDeviceInquiry.h"

@interface NSSystemStatus : NSObject
+ (NSDictionary *) sysInfo;
+ (id) sysInfoForKey:(NSString *) key;
@end

#endif

@interface IOBluetoothDeviceInquiry (Private)
+ (NSTask *) _hcitool:(NSArray *) cmds handler:(id) handler done:(SEL) sel;	// registers handler as observer!
@end

