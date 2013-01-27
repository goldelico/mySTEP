//
//  CoreDevice.m
//  CoreDevice
//
//  Created by H. Nikolaus Schaller on 14.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CoreDevice.h"
#import <AppKit/NSApplication.h>

NSString *UIDeviceBatteryLevelDidChangeNotification=@"UIDeviceBatteryLevelDidChangeNotification";
NSString *UIDeviceBatteryStateDidChangeNotification=@"UIDeviceBatteryStateDidChangeNotification";
NSString *UIDeviceOrientationDidChangeNotification=@"UIDeviceOrientationDidChangeNotification";
NSString *UIDeviceProximityStateDidChangeNotification=@"UIDeviceProximityStateDidChangeNotification";


@implementation UIDevice

/* NIB-safe Singleton pattern */

#define SINGLETON_CLASS		UIDevice
#define SINGLETON_VARIABLE	currentDevice
#define SINGLETON_HANDLE	currentDevice

/* static part */

static SINGLETON_CLASS * SINGLETON_VARIABLE = nil;

+ (id) allocWithZone:(NSZone *)zone
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		return [super allocWithZone:zone];
	}
    return SINGLETON_VARIABLE;
}

- (id) copyWithZone:(NSZone *)zone { return self; }

- (id) retain { return self; }

- (unsigned) retainCount { return UINT_MAX; }

- (void) release {}

- (id) autorelease { return self; }

+ (SINGLETON_CLASS *) SINGLETON_HANDLE
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		[[self alloc] init];
    }
    return SINGLETON_VARIABLE;
}

/* customized part */

- (id) init
{
	//    Class myClass = [self class];
	//    @synchronized(myClass)
	{
	if (!SINGLETON_VARIABLE && (self = [super init]))
		{
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		_previousBatteryState=UIDeviceBatteryStateUnknown;
		_previousBatteryLevel=-1.0;
		_previousOrientation=UIDeviceOrientationUnknown;
		_previousProximityState=NO;
		}
    }
    return self;
}

- (void) dealloc
{ // should not happen for a singleton!
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
	NSLog(@"CoreDevice dealloc");
	abort();
	[super dealloc];
}

- (void) _update;
{
	if(batteryMonitoringEnabled)
		{
		UIDeviceBatteryState s=[self batteryState];
		float l=[self batteryLevel];
		if(s != _previousBatteryState)
			{
			_previousBatteryState=s;
			[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceBatteryStateDidChangeNotification object:nil];
			}
		if(fabs(l - _previousBatteryLevel) > 0.01)
			{ // more than 1%
				_previousBatteryLevel=l;
				[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceBatteryLevelDidChangeNotification object:nil];
			}
		}
	if(generatingDeviceOrientationNotifications)
		{
		UIDeviceOrientation o=[self orientation];
		if(o != _previousOrientation)
			{
			_previousOrientation=o;
			[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
			}
		}
	if(proximityMonitoringEnabled)
		{
		BOOL s=[self proximityState];
		if(s != _previousProximityState)
			{
			_previousProximityState=s;
			[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceProximityStateDidChangeNotification object:nil];
			}
		}
	[self performSelector:@selector(_update) withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];	// trigger updates
}

- (void) _updater;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
	if(generatingDeviceOrientationNotifications || proximityMonitoringEnabled || batteryMonitoringEnabled)
		[self performSelector:@selector(_update) withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];	// trigger updates
}

- (float) batteryLevel;
{
	// bq27000 on 3.7 kernel
	NSString *val=[NSString stringWithContentsOfFile:@"/sys/devices/w1_bus_master1/01-000000000000/bq27000-battery/power_supply/bq27000-battery/capacity"];
	if(val)
		return [val intValue]/100.0;
	// battery voltage in mV on 3.7 kernel
	val=[NSString stringWithContentsOfFile:@"/sys/devices/platform/twl4030_madc_hwmon/in12_input"];
	// battery voltage in mV on 2.6 kernel
	if(!val)
		val=[NSString stringWithContentsOfFile:@"/sys/bus/platform/devices/twl4030-bci-battery/power_supply/twl4030_bci_battery/voltage_now"];
	if(!val)
		return -1.0;	// unknown
	return ([val intValue]-3200)/(4250.0-3200.0);	// estimate from voltage
}

- (BOOL) isBatteryMonitoringEnabled;
{
	return batteryMonitoringEnabled;
}

- (void) setBatteryMonitoringEnabled:(BOOL) state;
{
	if(batteryMonitoringEnabled != state)
		{
		batteryMonitoringEnabled=state;
		[self _updater];	// trigger updates
		}
}

- (UIDeviceBatteryState) batteryState;
{
	NSString *status=[NSString stringWithContentsOfFile:@"/sys/devices/w1_bus_master1/01-000000000000/bq27000-battery/power_supply/bq27000-battery/status"];
	if(status)
		{ // bq27000 on 3.7 kernel
#if 1
			NSLog(@"bq27000 status %@", status);
#endif
			if([status isEqualToString:@"Charging"])
				return UIDeviceBatteryStateCharging;
			return UIDeviceBatteryStateUnknown;
		}
	status=[NSString stringWithContentsOfFile:@"/sys/devices/platform/omap_i2c.1/i2c-1/1-004b/twl4030_bci/power_supply/twl4030_usb/status"];
#if 1
	NSLog(@"3.7 USB charger status %@", status);
#endif
	if(!status)
		status=[NSString stringWithContentsOfFile:@"/sys/bus/platform/devices/twl4030-bci-battery/power_supply/twl4030_bci_battery/status"];
#if 1
	NSLog(@"status %@", status);
#endif
	if(status == nil)
		return UIDeviceBatteryStateUnknown;
	if([self batteryLevel] >= 0.97)
		return UIDeviceBatteryStateFull;
	if([status hasPrefix:@"Charging"])
		return UIDeviceBatteryStateCharging;
	return UIDeviceBatteryStateUnplugged;
}

- (NSTimeInterval) remainingTime;
{ // estimate
	NSString *status=[NSString stringWithContentsOfFile:@"/sys/devices/w1_bus_master1/01-000000000000/bq27000-battery/power_supply/bq27000-battery/time_to_empty_now"];
#if 1
	NSLog(@"bq27000 remainingTime %@", status);
#endif
	if([status length] > 0)
		;
	return [self batteryLevel]*((1200*3600/450));	// 1200 mAh / 450 mA
}

- (NSString *) localizedModel;
{
	return [self model];
}

- (NSString *) model;
{
	return @"GTA04";	// read from sysinfo database
}

- (BOOL) isMultitaskingSupported;	/* always YES */
{
	return YES;
}

- (NSString *) name;	/* e.g. Zaurus, GTA04 */
{
	return [[NSProcessInfo processInfo] hostName];
}

- (NSString *) systemName;	/* @"QuantumSTEP" */
{
	return [[NSProcessInfo processInfo] operatingSystemName];
}

- (NSString *) systemVersion;
{
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

- (BOOL) isGeneratingDeviceOrientationNotifications;
{
	return generatingDeviceOrientationNotifications;
}

- (void) beginGeneratingDeviceOrientationNotifications;
{
	generatingDeviceOrientationNotifications=YES;
	[self _updater];
}

- (void) endGeneratingDeviceOrientationNotifications;
{
	generatingDeviceOrientationNotifications=NO;
	[self _updater];
}

- (UIDeviceOrientation) orientation;
{ // ask accelerometer
	NSArray *val=[[NSString stringWithContentsOfFile:@"/sys/bus/i2c/devices/i2c-2/2-0041/coord"] componentsSeparatedByString:@","];
	if([val count] >= 3)
		{
		// check relative magnitudes
		NSLog(@"orientation=%@", val);
		}
	return UIDeviceOrientationUnknown;
}

- (BOOL) isProximityMonitoringEnabled;
{
	return proximityMonitoringEnabled;
}

- (void) setProximityMonitoringEnabled:(BOOL) state;
{
#if 0	// we can't set it to YES unless we have a proximity sensor
	proximityMonitoringEnabled=state;
#endif
	[self _updater];
}

- (BOOL) proximityState;
{
	return NO;
}

// -(UIUserInterfaceIdiom) userInterfaceIdiom;

- (void) playInputClick;
{
	
}

@end
