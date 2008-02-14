/* 
 NSSystemStatus.h
 
 Interface for workspace extension.
  
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_NSSystemStatus
#define _mySTEP_H_NSSystemStatus

#import <AppKit/AppKit.h>
#import <SystemStatus/SYSBattery.h>
#import <SystemStatus/SYSDevice.h>
#import <SystemStatus/SYSEnvironment.h>
#import <SystemStatus/SYSLocation.h>
#import <SystemStatus/SYSNetwork.h>
#import <SystemStatus/SYSWireless.h>

@interface NSSystemStatus : NSObject
+ (NSDictionary *) sysInfo;				// get CPU type, speed, free memory, etc. for system About box and other areas
+ (id) sysInfoForKey:(NSString *) key;
@end

#endif