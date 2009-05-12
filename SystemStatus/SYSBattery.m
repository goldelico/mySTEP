/* 
 Battery driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/SYSBattery.h>
#import <SystemStatus/NSSystemStatus.h>

#define DEMO 0  // set to 1 for sawtooth demo mode

@implementation SYSBattery

/*
 OS X seems to provide something like
 ioreg -l | grep -i IOBatteryInfo
 | |   |   |     "IOBatteryInfo" = ({"Capacity"=1644,"Amperage"=932,"Current"=1638,"Voltage"=16388,"Flags"=838860805})
 should we return such an NSDictionary?
 what does the Flags mean?

 Linux apparently provides:

 /proc/apm - primitive info; single battery only - provided as string for sscanf()

 or alternatively
 /proc/acpi/ac_adapter/#/info
 /proc/acpi/battery/#/status
 /proc/acpi/battery/#/info

 e.g.
cat /proc/acpi/battery/BAT0/state
present:                 yes
capacity state:          ok
charging state:          charged
present rate:            unknown
remaining capacity:      90 mAh
present voltage:         8262 mV
 
 cat /proc/acpi/battery/BAT0/info
...
 last full capacity:      100 mAh

=> read both /proc/acpi/battery/BAT0/info & /proc/acpi/battery/BAT0/status to derive a % indicator
 
 Zaurus ROM 3.10 provides /proc/apm (only)

*/

+ (SYSBattery *) defaultBattery;
{
	static SYSBattery *b;
	if(!b) 
		b=[[self alloc] init];
	return b; 
}

static BOOL _isOnExternalPower;

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@%@%@ %.0f%% %.0lf %.0f",
					_isOnExternalPower?@"on AC ":@"",
					_batteryIsInstalled?@"installed":@"no battery",
					_batteryIsCharging?@" charging":@" not charging",
					100*_batteryFillLevel,
					_remainingBatteryTime,
					_batteryTemperature];
}

- (void) _update
{
#if 0
	NSLog(@"SYSBattery _update");
#endif
	if(!lastUpdate || ([lastUpdate timeIntervalSinceNow] < -5.0))
			{ // more than 5 seconds ago
				FILE *f;
				f=fopen("/proc/apm", "r");
				if(f)
						{ // apm is available
							int linestatus;
							int batterystatus;
							int flag;
							int percentage;
							int time;
							char units[32];
							fscanf(f, "%*s %*d.%*d %*x %x %x %x %d%% %d %31s\n",
										 &linestatus,
										 &batterystatus, 
										 &flag, 
										 &percentage, 
										 &time, 
										 units);
							fclose(f);
							_batteryIsInstalled=((flag & 0x80) == 0 && batterystatus != 0xFF);
							_batteryIsCharging=(batterystatus == 3);
							_isOnExternalPower=(linestatus == 1);
							if(percentage > 100 || percentage < 0)
								percentage=-100;	// C860 returns 255 while charging, Openmoko returns -1
							_batteryFillLevel=percentage/100.0;
							if(time < 0)
									{ // apm can't deliver value: should estimate time to charge and time to decharge yourself
										time=-1;
									}
							if(strncmp(units, "min", 32) == 0)
								time*=60; // in minutes
							_remainingBatteryTime=time;
						}
				// else try /proc/acpi/battery/BAT0
				[lastUpdate release];
				lastUpdate=[[NSDate alloc] init];
#if 0
				NSLog(@"battery status updated: %@", self);
				system("cat /proc/apm");
#endif
			}				
}

- (float) batteryFillLevel;
{ // how much filled / -1 if unknown
#if DEMO
	// make a sawtooth
#define T 60.0
	double i = [[NSDate date] timeIntervalSinceReferenceDate];
	NSLog(@"now = %lf mod=%lf", i, fmod(i, T));
	return fabsf(fmod(i, T)-(T/2.0))/(T/2.0);	// bring to range 1..0..1
#else
	[self _update];
	return _batteryFillLevel;
#endif
}

- (BOOL) batteryIsInstalled;
{
#if 0
	NSLog(@"batteryIsInstalled?");
#endif
	[self _update];
	return _batteryIsInstalled;
}

- (BOOL) batteryIsCharging;
{ // is being charged
#if DEMO
	double i = [[NSDate date] timeIntervalSinceReferenceDate];
	return (30.0-fmod(i, 60.0))<0.0;	// bring to range 30..-30
#else
	[self _update];
	return _batteryIsCharging;
#endif
}

- (NSTimeInterval) remainingBatteryTime;
{ // estimated remaining time till empty/full / -1 if unknown
#if DEMO
	// this should try to estimate the remaining time
	return -1.0;	// unknown
#else
	[self _update];
	return _remainingBatteryTime;
#endif
}

- (float) batteryTemperature;
{ // in Kelvin if available (0 or negative meaning that we don't know)
	[self _update];
	return _batteryTemperature;
}

// power control

+ (void) sleep;
{
	system([[NSSystemStatus sysInfoForKey:@"Sleep"] UTF8String]);
}

+ (void) shutdown;
{
	system([[NSSystemStatus sysInfoForKey:@"Shutdown"] UTF8String]);
}

+ (void) reboot;
{
	system([[NSSystemStatus sysInfoForKey:@"Reboot"] UTF8String]);
}

+ (BOOL) isOnExternalPower;
{ // is on AC power supply
	return _isOnExternalPower;
}

+ (void) keepAlive;
{ // trigger watchdog to prevent automatic sleep
	
}

+ (void) setBackLightLevel:(float) level;
{ // 0..1
	
}

+ (void) backLight:(BOOL) flag;
{ // switch excplicitly on/off
	[self setBackLightLevel:flag?1.0:0.0];
}

@end
