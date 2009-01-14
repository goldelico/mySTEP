/* 
 SYSEnvironmentStatus.h
 
 Generic interface for device environment (temperature, humidity, radiosity etc.).
  
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSEnvironmentStatus
#define _mySTEP_H_SYSEnvironmentStatus

#import <AppKit/AppKit.h>

@interface SYSEnvironment : NSObject

+ (SYSEnvironment *) sharedEnvironment;	// shared environment manager object

- (float) environmentTemperature;   // temperature in Kelvin
- (float) environmentPressure;		// air pressure in Pascal
- (float) environmentHumidity;		// air humidity in %

@end

#endif
