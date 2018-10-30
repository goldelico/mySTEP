//
//  BluetoothPrivate.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#ifdef __mySTEP__
#import <SystemStatus/NSSystemStatus.h>

#else

#import <Cocoa/Cocoa.h>

@interface NSSystemStatus : NSObject
+ (NSDictionary *) sysInfo;
+ (id) sysInfoForKey:(NSString *) key;
@end

#endif

#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>

@interface IOBluetoothDeviceInquiry (Private)
+ (NSTask *) _hcitool:(NSArray *) cmds handler:(id) handler done:(SEL) sel;	// registers handler as observer!
+ (NSTask *) _hcitool:(NSArray *) cmds handler:(id) handler done:(SEL) sel;	// registers handler as observer!
@end

