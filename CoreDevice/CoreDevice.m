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

- (NSUInteger) retainCount { return UINT_MAX; }

- (oneway void) release {}

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
#if 0
	NSLog(@"init: %@", self);
#endif
	}
	return self;
}

- (void) dealloc
{ // should not happen for a singleton!
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
#if 0
	NSLog(@"CoreDevice dealloc");
	abort();
#endif
	[super dealloc];
}

- (void) _update;
{
#if 0
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
	[self performSelector:_cmd withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];	// trigger updates
}

- (void) _startUpdater;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel previous updates
	if(generatingDeviceOrientationNotifications || proximityMonitoringEnabled || batteryMonitoringEnabled)
		[self performSelector:@selector(_update) withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];	// trigger updates
}

- (NSString *) getPowerSupplyValue:(NSString *) value forType:(NSString *) type
{
	int bestQuality;
	NSString *bestVal=nil;
	NSFileManager *fm=[NSFileManager defaultManager];
	NSString *dir=@"/sys/class/power_supply";
	NSEnumerator *e=[[fm contentsOfDirectoryAtPath:dir error:NULL] objectEnumerator];
	NSString *device;
	while((device = [e nextObject]))
		{ // find matching device
		NSString *dpath=[dir stringByAppendingPathComponent:device];
		int quality=0;
		NSString *val=[NSString stringWithContentsOfFile:[dpath stringByAppendingPathComponent:value]];
		NSString *t;
#if 0
			NSLog(@"%@/%@ -> %@", dpath, value, val);
#endif
		if(!val)
			continue;	// does not provide value
		t=[NSString stringWithContentsOfFile:[dpath stringByAppendingPathComponent:@"type"]];
		t=[t stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
#if 0
		NSLog(@"%@ = %@", t, type);
#endif
		if([t isEqualToString:type])
			quality+=4;	// type matches
		if([[NSString stringWithContentsOfFile:[dpath stringByAppendingPathComponent:@"present"]] intValue] == 1)
			quality+=2;	// is present
		if([device hasPrefix:@"bq27"])
			quality++;	// prefer bq27xxx fuel gauge
#if 0
			NSLog(@"val=%@ quality=%d bestVal=%@ bestQuality=%d", val, quality, bestVal, bestQuality);
#endif
		if(!bestVal || quality > bestQuality)
			bestVal=val, bestQuality=quality;	// better quality value found
		}
#if 0
	NSLog(@"%@/%@ bestval = %@", type, value, bestVal);
#endif
	return bestVal;
}

- (NSString *) batteryValue:(NSString *) value
{
	return [self getPowerSupplyValue:value forType:@"Battery"];
}

- (float) batteryLevel;
{
	NSString *val=[self batteryValue:@"capacity"];
	if(!val)
		{
		// battery may be decalibrated!
		return 0.5;
		}
#if 0
	NSLog(@"batteryLevel = %@", val);
#endif
	return [val intValue]/100.0;
}

- (float) batteryHealth;
{
	NSString *val=[self batteryValue:@"charge_full"];
	NSString *val2=[self batteryValue:@"charge_full_design"];
	if(!val || val2 || [val2 intValue] == 0)
		return -1;	// can't determine
#if 0
	NSLog(@"batteryHealth = %@ : %@", val, val2);
#endif
	return [val intValue]/[val2 intValue];
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

- (BOOL) checkCable;
{ // if user should check charging cable
	if([self batteryState] == UIDeviceBatteryStateCharging)
		{
		NSString *status;
		status=[self getPowerSupplyValue:@"status" forType:@"USB"];
		if([status hasPrefix:@"Charging"])
			{ // USB charger active
				{ // USB charger active
					if([self chargerVoltage] < 4.7)	// VBUS < 4.7V - risk of HW-disconnect
						return YES;	// weak and unreliable charging - check cable
				}
			}
		}
	/* if unplugged:
	 status=[NSString stringWithContentsOfFile:@"/sys/class/power_supply/twl4030_usb/voltage_now"];
	 if(!status || [status doubleValue] >= 1.0*1e6)	// VBUS > 1V
	 return UIDeviceBatteryStateUnknown;	// discharging although VBUS is available - charger or battery broken?
		*/
	return NO;
}

- (UIDeviceBatteryState) _batteryState;
{ // should not be called too often in sequence!
	// we should check when it was lastly asked for and return a cached value if less than some timeout...
	NSString *status=[self batteryValue:@"status"];
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
			status=[self getPowerSupplyValue:@"status" forType:@"USB"];
			if([status hasPrefix:@"Charging"])
				return UIDeviceBatteryStateCharging;
			status=[self getPowerSupplyValue:@"status" forType:@"Mains"];
			if([status hasPrefix:@"Charging"])
				return UIDeviceBatteryStateACCharging;
			return UIDeviceBatteryStateUnknown;	// we don't know why the battery is charging...
			}
		if([status hasPrefix:@"Discharging"])
			{
			return UIDeviceBatteryStateUnplugged;	// i.e. not connected to charger			
			}
		}
	return UIDeviceBatteryStateUnknown;
}

- (UIDeviceBatteryState) batteryState;
{
	// static or iVars???
	static time_t last;
	static UIDeviceBatteryState lastState;	// cached state
	time_t t=time(NULL);
	if(t >= last+1)
		lastState=[self _batteryState];	// get new value every second
	last=t;
	return lastState;
}

- (NSTimeInterval) remainingTime;
{ // estimate remaining time (in seconds)
	// FIXME: only available if discharging! During charging we have time_to_full_now
	NSString *val=[self batteryValue:@"time_to_empty_now"];
	return val?[val doubleValue]:-1.0;
}

- (unsigned int) chargingCycles;
{ // number of charging cycles
	NSString *val=[self batteryValue:@"cycle_count"];
	return val?[val intValue]:-1;
}

- (float) batteryVoltage;
{
	NSString *val=[self batteryValue:@"voltage_now"];
	return val?[val floatValue] * 1e-6:-1.0;
}

- (float) batteryDischargingCurrent;
{
	NSString *val=[self batteryValue:@"current_now"];
	return val?[val floatValue] * 1e-6:0.0;
}

- (float) chargerVoltage;
{
	// FIXME: use VAC or VBUS whatever is available
	NSString *val=[self getPowerSupplyValue:@"voltage_now" forType:@"USB"];
	return val?[val floatValue] * 1e-6 : -1.0;
}

- (NSString *) localizedModel;
{
	return [self model];
}

- (NSString *) model;
{
	// read /sys/firmware/devicetree/base/model
	return @"GTA04";	// should be read from sysinfo database or device tree
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
  // FIXME: needs a completely different approach to be generic
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
	// check system preferences if it is enabled/disabled
	AudioServicesStopSystemSound(kSystemSoundID_Vibrate);
	NSArray *pattern=
	[NSArray arrayWithObjects:
	 [NSNumber numberWithBool:YES],
	 [NSNumber numberWithFloat:50],
	 [NSNumber numberWithBool:NO],
	 [NSNumber numberWithFloat:100],
	 nil];
	NSMutableDictionary *dict=
	[NSMutableDictionary dictionaryWithObjectsAndKeys:pattern, @"VibePattern",
	 [NSNumber numberWithDouble:1.0],
	 nil];
	AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, dict);
	[[NSSound soundNamed:@"Click"] play];
}

// HM, this should be better in AudioToolbox/AudioServices.h
// see http://stackoverflow.com/questions/2080442/programmatically-make-the-iphone-vibrate
// but it is not an Obj-C framework

- (void) playVibraCall;
{
	// check system preferences if it is enabled/disabled
	AudioServicesStopSystemSound(kSystemSoundID_Vibrate);
	NSArray *pattern=
	[NSArray arrayWithObjects:
	 [NSNumber numberWithBool:YES],
	 [NSNumber numberWithFloat:100],
	 [NSNumber numberWithBool:NO],
	 [NSNumber numberWithFloat:200],
	 [NSNumber numberWithBool:YES],
	 [NSNumber numberWithFloat:100],
	 [NSNumber numberWithBool:NO],
	 [NSNumber numberWithFloat:200],
	 [NSNumber numberWithBool:YES],
	 [NSNumber numberWithFloat:100],
	 [NSNumber numberWithBool:NO],
	 [NSNumber numberWithFloat:200],
	 nil];
	NSMutableDictionary *dict=
	[NSMutableDictionary dictionaryWithObjectsAndKeys:pattern, @"VibePattern",
	 [NSNumber numberWithDouble:1.0],
	 nil];
	AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, dict);
}

@end

#ifdef __linux__

#include <linux/input.h>

// should be provided through #import <AudioToolbox/AudioToolbox.h>

static int rumbleFd = -1;
static struct input_event event;
static struct ff_effect e;

void AudioServicesStopSystemSound(SystemSoundID sound)
{
	if(sound == kSystemSoundID_Vibrate)
		{
		if(rumbleFd < 0 || e.id < 0)
			return;	// no effect running

		// Stop the effect
		event.type = EV_FF;
		event.code = e.id;
		event.value = 0;	// stop

		if (write(rumbleFd, (const void *)&event, sizeof(event)) < 0)
			perror("rumble write");

		// Remove the effect
		if (e.id >= 0 && ioctl(rumbleFd, EVIOCRMFF, e.id) < 0)
			perror("rumble remove");

		e.id = -1;
		}
}

void AudioServicesPlaySystemSound(SystemSoundID sound)
{
	AudioServicesPlaySystemSoundWithVibration(sound, nil, nil);
}

void AudioServicesPlaySystemSoundWithVibration(SystemSoundID sound, id arg, NSDictionary *pattern)
{
#if 1
	NSLog(@"AudioServicesPlaySystemSoundWithVibration: %08x %@ %@", sound, arg, pattern);
#endif
	if(sound == kSystemSoundID_Vibrate)
		{
		NSArray *durations=[pattern objectForKey:@"VibePattern"];
		NSNumber *intensity=[pattern objectForKey:@"Intensity"];

		AudioServicesStopSystemSound(sound);	// stop and remove previous effect

		// Open rumble device if not yet open
		if(rumbleFd < 0)
			{
			rumbleFd = open("/dev/input/rumble", O_RDWR);
			if (rumbleFd < 0)
				{
				perror("rumble open");
				return;	// can't open
				}
			}

		// Translate pattern
		NSEnumerator *f=[durations objectEnumerator];
		int timeoutMs=0;
		id o;
		// NOTE: for handling complex patterns, we must add our own timer!
		while((o=[f nextObject]))
			{ //take the last YES pattern
				NSLog(@"try %@ %d", o, [o boolValue]);
			if([o boolValue])
				{
				o=[f nextObject]
				timeoutMs=1000*[o doubleValue];
				NSLog(@"to %@ %d", o, timeoutMs);
				}
			else
				[f nextObject];
			}

		// Define the new event
		e.type = FF_RUMBLE;
		e.id = -1;	// will be assigned by ioctl
		e.direction = 0;
		e.trigger.button = 0;
		e.trigger.interval = 0;
		e.replay.length = timeoutMs <= 0 ? timeoutMs : 3000;
		e.replay.delay = 0;
		float i=[intensity floatValue];
		i=MAX(MIN(i, 1.0), 0.0);	//range limit
		e.u.rumble.strong_magnitude = (0xffff*i);
		e.u.rumble.weak_magnitude = e.u.rumble.strong_magnitude;	// play both channels for Pyra!

#if 1
		NSLog(@"AudioServicesPlaySystemSoundWithVibration: replaylength=%d e.magnitude=%d", e.replay.length, e.u.rumble.strong_magnitude);
#endif

		// Write the event
		if (ioctl(rumbleFd, EVIOCSFF, &e) < 0)
			{
			perror("rumble upload");
			return;
			}

		// Play the effect
		event.type = EV_FF;
		event.code = e.id;
		event.value = 1;	// repeat once

		if (write(rumbleFd, (const void *)&event, sizeof(event)) < 0)
			perror("rumble write");
		}
}

#endif
