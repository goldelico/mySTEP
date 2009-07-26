//
//  BluetoothPrivate.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#ifdef __mySTEP__
#import <SystemStatus/NSSystemStatus.h>

// new version to be based on bluez

#define id objc_id
//#include <new/bluetooth/bluez.h>
#include <bluetooth/bluetooth.h>	// from usr/bluetooth
// conflicts with Bluetooth.h
#undef id

#else

@interface NSSystemStatus : NSObject
+ (NSDictionary *) sysInfo;
+ (id) sysInfoForKey:(NSString *) key;
@end
@implementation NSSystemStatus
+ (NSDictionary *) sysInfo; { return nil; }
+ (id) sysInfoForKey:(NSString *) key; { return nil; }
@end

#endif


