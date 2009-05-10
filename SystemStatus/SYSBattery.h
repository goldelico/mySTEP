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

// FIXME: should be renamed to SYSPowerManagement

@interface SYSBattery : NSObject
{
	NSDictionary *data;	// current data (updated every now and then)
	NSDate *lastUpdate;
}

+ (SYSBattery *) defaultBattery;			// default battery manager

- (float) batteryFillLevel;					// how much filled (0..1)
- (BOOL) batteryIsInstalled;				// is installed
- (BOOL) batteryIsCharging;					// is being charged
- (float) batteryTemperature;				// in Kelvin if available (0 or negative meaning that we don't know)
- (NSTimeInterval) remainingBatteryTime;	// estimated remaining time until empty/full - negative value means: unknown

+ (void) sleep;
+ (void) shutdown;
+ (void) reboot;
+ (void) keepAlive;		// trigger watchdog to prevent automatic sleep

+ (void) setBackLightLevel:(float) level;		// 0..1
+ (void) backLight:(BOOL) flag;					// excplicitly on/off

@end

#endif
