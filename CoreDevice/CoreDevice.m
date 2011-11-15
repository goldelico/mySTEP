//
//  CoreDevice.m
//  CoreDevice
//
//  Created by H. Nikolaus Schaller on 14.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CoreDevice.h"

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
			// notification
			}
		if(l != _previousBatteryLevel)
			{
			_previousBatteryLevel=l;
			// notification
			}
		// update charging parameter estimation
		// to estimate, we need two different (persistent) sets of calibration values
		// we should update them every 1 minute
		// and dejitter...
		/*
		 * minVoltageDischarging
		 * maxVoltageDischarging
		 * minVoltageCharging
		 * maxVoltageCharging
		 * dischargeRate	// mV/min
		 * chargeRate		// mV/min
		 * lastVoltage
		 * lastTimestamp
		 *
		 * if(charging)
		 *    {
		 *    chargeRate = (100*chargeRate + 1*(voltage-lastVoltage)/(now-lastTimestamp))/(100+1)	// adjust charging Rate estimation - low pass filter
		 *	  minVoltageCharging *=1.01;	// slowly creep up
		 *	  maxVoltageCharging *=0.99;	// slowly creep down
		 *    if(voltage < minVoltageCharging)
		 *        minVoltageCharging=voltage;
		 *    if(voltage > maxVoltageCharging)
		 *        maxVoltageCharging=voltage;
		 *	  }
		 * else discharging
		 *  =>
		 *    batteryLevel=(voltage-minVoltage)(maxVoltage-minVoltage);
		 *    remainingTime=60*(maxVoltage-voltage)/chargeRate;
		 */
		}
	if(generatingDeviceOrientationNotifications)
		{
		UIDeviceOrientation o=[self orientation];
		if(o != _previousOrientation)
			{
			_previousOrientation=o;
			// notification
			}
		}
	if(proximityMonitoringEnabled)
		{
		BOOL s=[self proximityState];
		if(s != _previousProximityState)
			{
			_previousProximityState=s;
			// notification
			}
		}
	[self performSelector:@selector(_update) withObject:nil afterDelay:1.0];	// trigger updates
}

- (void) _updater;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
	if(generatingDeviceOrientationNotifications || proximityMonitoringEnabled || batteryMonitoringEnabled)
		[self performSelector:@selector(_update) withObject:nil afterDelay:1.0];	// trigger updates
}

- (float) batteryLevel;
{
	NSString *val=[NSString stringWithContentsOfFile:@"/sys/bus/platform/devices/twl4030-bci-battery/power_supply/twl4030_bci_battery/voltage_now"];
	if(!val)
		return -1.0;	// unknown
	return ([val intValue]-3200)/(4250.0-3200.0);
}

- (BOOL) isBatteryMonitoringEnabled;
{
	return batteryMonitoringEnabled;
}

- (void) setBatteryMonitoringEnabled:(BOOL) state;
{
	batteryMonitoringEnabled=state;
}

- (UIDeviceBatteryState) batteryState;
{
	NSString *status=[NSString stringWithContentsOfFile:@"/sys/bus/platform/devices/twl4030-bci-battery/power_supply/twl4030_bci_battery/status"];
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
	if(!generatingDeviceOrientationNotifications)
		{
		[self _updater];
		}
	generatingDeviceOrientationNotifications=YES;
}

- (void) endGeneratingDeviceOrientationNotifications;
{
	if(generatingDeviceOrientationNotifications)
		{
		// disable
		}
	generatingDeviceOrientationNotifications=NO;
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
	// we can't set it to YES
	// proximityMonitoringEnabled=state;
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
