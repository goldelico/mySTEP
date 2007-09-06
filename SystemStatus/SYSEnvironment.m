/* 
 SYSTEM STATUS driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/SYSEnvironment.h>

@implementation SYSEnvironment

+ (SYSEnvironment *) sharedEnvironment;
{
	static SYSEnvironment *e;
	if(!e) 
		e=[[self alloc] init];
	return e; 
}

- (float) environmentTemperature; { return 273.0 + 22; }	// temperature in Kelvin
- (float) environmentPressure; { return 1020*100; }			// air pressure in Pascal
- (float) environmentHumidity; { return 0.40; }				// air humidity in %

@end
