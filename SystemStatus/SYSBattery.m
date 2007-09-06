/* 
 Battery driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/SYSBattery.h>

#define DEMO 0  // set to 1 for sawtooth demo mode

@implementation SYSBattery

// OS X seems to provide something like
// ioreg -l | grep -i IOBatteryInfo
// | |   |   |     "IOBatteryInfo" = ({"Capacity"=1644,"Amperage"=932,"Current"=1638,"Voltage"=16388,"Flags"=838860805})
// should we return such an NSDictionary?
// what does the Flags mean?

// Linux apparently provides:
//
// /proc/apm - primitive info; single battery only - provided as string for sscanf()
// /proc/acpi/ac_adapter/#/info
// /proc/acpi/battery
// /proc/acpi/info
//
// Zaurus ROM 3.10 provides /proc/apm (only)
//
// an example how to use can be found in Kismet: panelfront.cc/int PanelFront::Tick()

struct bat 
{
	int available;		// battery status is available
	int ac;				// connected to AC
	int percentage;		// % charged (during charging/discharging)
	int time;			// remaining time to charge/discharge)
	int charging;		// is (still) charging
	int linestatus;		// AC power line status
	int batterystatus;  // battery status flag
	int flag;			// other flags
	char units[32];
};

static struct bat getbat(void)
{ // fetch battery data
	struct bat r;
	FILE *f=fopen("/proc/apm", "r");
	if(!f)
		{ // apm can't be opened
		memset(&r, 0, sizeof(r));
		return r;
		}
	fscanf(f, "%*s %*d.%*d %*x %x %x %x %d%% %d %31s\n",
			   &r.linestatus,
			   &r.batterystatus, 
			   &r.flag, 
			   &r.percentage, 
			   &r.time, 
			   r.units);
	fclose(f);
	r.available=((r.flag & 0x80) == 0 && r.batterystatus != 0xFF);
	r.charging=(r.batterystatus == 3);
	r.ac=(r.linestatus == 1);
	if(r.percentage > 100)
		r.percentage=100;	// C860 return 255 while charging
	if(r.time == -1)
		r.time=0;   // apm can't deliver value: should estimate time to charge and time to decharge
	if(strncmp(r.units, "min", 32) == 0)
		r.time*=60; // in minutes
	return r;
	}

+ (SYSBattery *) defaultBattery;
{
	static SYSBattery *b;
	if(!b) 
		b=[[self alloc] init];
	return b; 
}

- (float) batteryFillLevel;
{ // how much filled
#if DEMO
	// make a sawtooth
#define T 60.0
	double i = [[NSDate date] timeIntervalSinceReferenceDate];
	NSLog(@"now = %lf mod=%lf", i, fmod(i, T));
	return fabsf(fmod(i, T)-(T/2.0))/(T/2.0);	// bring to range 1..0..1
#else
	return getbat().percentage/100.0;
#endif
}

- (BOOL) batteryIsCharging;
{ // is being charged
#if DEMO
	double i = [[NSDate date] timeIntervalSinceReferenceDate];
	return (30.0-fmod(i, 60.0))<0.0;	// bring to range 30..-30
#else
	return getbat().charging;
#endif
}

- (NSTimeInterval) remainingBatteryTime;
{ // estimated remaining time till empty/full
#if DEMO
	// this should try to estimate the remaining time
	return -1.0;	// unknown
#else
	return getbat().time;
#endif
}

- (float) batteryTemperature;
{ // in Kelvin if available (0 or negative meaning that  we don't know)
	return 0.0;
}

@end

