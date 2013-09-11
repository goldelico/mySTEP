//
//  CoreDevice.m
//  CoreDevice
//
//  Created by H. Nikolaus Schaller on 14.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CoreDevice.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSSound.h>

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
	NSLog(@"init: %@", self);
    }
    return self;
}

- (void) dealloc
{ // should not happen for a singleton!
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
#if 1
	NSLog(@"CoreDevice dealloc");
	abort();
#endif
	[super dealloc];
}

- (void) _update;
{
#if 1
	NSLog(@"CoreDevice _update");
#endif
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

- (void) _startUpdater;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
	if(generatingDeviceOrientationNotifications || proximityMonitoringEnabled || batteryMonitoringEnabled)
		[self performSelector:@selector(_update) withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];	// trigger updates
}

- (NSString *) batteryPath:(NSString *) value
{
	if([[NSString stringWithContentsOfFile:@"/sys/class/power_supply/bq27000-battery/present"] intValue] == 1)
		return [NSString stringWithFormat:@"/sys/class/power_supply/bq27000-battery/%@", value];
	return [NSString stringWithFormat:@"/sys/class/power_supply/twl4030_battery/%@", value];
}

- (float) batteryLevel;
{
	NSString *val=[NSString stringWithContentsOfFile:[self batteryPath:@"capacity"]];
#if 0
	NSLog(@"batteryLevel = %@", val);
#endif
	return [val intValue]/100.0;
}

- (BOOL) isBatteryMonitoringEnabled;
{
	return batteryMonitoringEnabled;
}

- (void) setBatteryMonitoringEnabled:(BOOL) state;
{
#if 0
	NSLog(@"setBatteryMonitoringEnabled = %d", state);
#endif
	if(batteryMonitoringEnabled != state)
		{
		batteryMonitoringEnabled=state;
		[self _startUpdater];	// trigger updates
		}
}

- (UIDeviceBatteryState) batteryState;
{ // should not be called too often in sequence!
	// we may check when it was lastly asked for and cache the value...
	NSString *status=[NSString stringWithContentsOfFile:[self batteryPath:@"status"]];
#if 0
	NSLog(@"batteryState=%@", status);
#endif
	if(status)
		{
		if([status hasPrefix:@"Full"])
			return UIDeviceBatteryStateFull;
		if([status hasPrefix:@"Charging"])
			{
			if([self batteryLevel] > 0.99)
				return UIDeviceBatteryStateFull;
			// check if VBUS/VAC is >= 4.8V for proper and reliable charging
			status=[NSString stringWithContentsOfFile:@"/sys/class/power_supply/twl4030_usb/status"];
			if([status hasPrefix:@"Charging"])
				return UIDeviceBatteryStateCharging;
			status=[NSString stringWithContentsOfFile:@"/sys/class/power_supply/twl4030_ac/status"];
			if([status hasPrefix:@"Charging"])
				return UIDeviceBatteryStateACCharging;
			return UIDeviceBatteryStateUnplugged;	// we don't know why the battery is charging...
			}
		if([status hasPrefix:@"Discharging"])
			// FIXME: check VBUS/VAC for > 1V and report bad/insufficient charger
			return UIDeviceBatteryStateUnplugged;	// i.e. not connected to charger
		}
	return UIDeviceBatteryStateUnknown;
}

- (NSTimeInterval) remainingTime;
{ // estimate remaining time (in seconds)
	NSString *val=[NSString stringWithContentsOfFile:[self batteryPath:@"time_to_empty_now"]];
	return [val doubleValue];
}

- (unsigned int) chargingCycles;
{ // number of charging cycles
	NSString *val=[NSString stringWithContentsOfFile:[self batteryPath:@"cycle_count"]];
	return [val intValue];
}

- (float) batteryVoltage;
{
	NSString *val=[NSString stringWithContentsOfFile:[self batteryPath:@"voltage_now"]];
	return [val floatValue] * 1e-6;
}

- (float) chargerVoltage;
{
	// FIXME: use VAC or VBUS
	NSString *val=[NSString stringWithContentsOfFile:[self batteryPath:@"voltage_now"]];
	return [val floatValue] * 1e-6;
}

- (float) batteryDischargingCurrent;
{
	NSString *val=[NSString stringWithContentsOfFile:[self batteryPath:@"current_now"]];
	return [val floatValue] * 1e-6;
}

- (NSString *) localizedModel;
{
	return [self model];
}

- (NSString *) model;
{
	return @"GTA04";	// should be read from sysinfo database
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
	[self _startUpdater];
}

- (void) endGeneratingDeviceOrientationNotifications;
{
	generatingDeviceOrientationNotifications=NO;
	[self _startUpdater];
}

- (UIDeviceOrientation) orientation;
{ // ask accelerometer
	NSArray *val=[[NSString stringWithContentsOfFile:@"/sys/bus/i2c/devices/i2c-2/2-0041/coord"] componentsSeparatedByString:@","];
	if([val count] >= 3)
		{
		// check relative magnitudes of X, Y, Z
#if 1
		NSLog(@"orientation=%@", val);
#endif
		}
	return UIDeviceOrientationUnknown;
}

- (BOOL) isProximityMonitoringEnabled;
{
	return proximityMonitoringEnabled;
}

- (void) setProximityMonitoringEnabled:(BOOL) state;
{
	if(state != proximityMonitoringEnabled)
		{
#if 0	// we can't set it to YES unless we have a proximity sensor
		proximityMonitoringEnabled=state;
#endif
		[self _startUpdater];		
		}
}

- (BOOL) proximityState;
{
	return NO;
}

// -(UIUserInterfaceIdiom) userInterfaceIdiom;

- (void) playInputClick;
{
	[[NSSound soundNamed:@"Click"] play];
}

@end
