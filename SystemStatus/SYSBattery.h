/* 
 SYSBatteryStatus.h
 
 Generic interface to battery manager.
  
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSBatteryStatus
#define _mySTEP_H_SYSBatteryStatus

#import <AppKit/AppKit.h>

@interface SYSBattery : NSObject
+ (SYSBattery *) defaultBattery;			// default battery manager

- (float) batteryFillLevel;					// how much filled
- (BOOL) batteryIsCharging;					// is being charged
- (float) batteryTemperature;				// in Kelvin if available (0 or negative meaning that  we don't know)
- (NSTimeInterval) remainingBatteryTime;	// estimated remaining time till empty/full - negative value means: unknown

@end

#endif