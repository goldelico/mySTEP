//
//  CMMotionManager.m
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <CoreDevice/CoreDevice.h>

@implementation CMAccelerometer

@end

@implementation CMAttitude

@end

@implementation CMDeviceMotion

- (CMAttitude *) attitude; { return _attitude; }
- (CMAcceleration) gravity; { return _gravity; }
- (CMCalibratedMagneticField) magneticField; { return _magneticField; }
- (CMRotationRate) rotationRate; { return _rotationRate; }
- (CMAcceleration) userAcceleration; { return _userAcceleration; }

@end

@implementation CMGyro

@end

@implementation CMLogItem

@end

@implementation CMMagnetometerData

@end

@implementation CMMotionManager

- (void) startDeviceMotionUpdates;
{
	// power up sensors
}

- (void) stopDeviceMotionUpdates;
{
	// power down sensors
}

- (CMDeviceMotion *) deviceMotion;
{
	static CMDeviceMotion *_deviceMotion;
	if(!_deviceMotion)
		_deviceMotion=[CMDeviceMotion new];
#if __linux__
#if 0
	NSLog(@"read iio accelerometers");
#endif
	static NSString *accel;
	static double scaleX;
	static double scaleY;
	static double scaleZ;
	if(!accel)
		{
		NSError *error;
		NSString *dir=@"/sys/bus/iio/devices/";
		NSEnumerator *e=[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&error] objectEnumerator];
		NSString *device;

		while((device=[e nextObject]))
			{
			device=[dir stringByAppendingPathComponent:device];
#if 0
			NSLog(@"try %@", device);
#endif
			id sc=[NSString stringWithContentsOfFile:[device stringByAppendingPathComponent:@"in_accel_scale"]];
			if(sc)
				{
				scaleX=scaleY=scaleZ=[sc doubleValue]/9.81;	// iio returns kg/s^2
				accel=[device retain];

				/* should use device configuration database */
				NSString *model=[[[UIDevice new] autorelease] model];

				/* on GTA04A5 it turns out that some axis are inverted
				 compared to the GTA04A4. This should have been
				 handled/unified by the kernel, but it isn't.

				 Values					GTA04A4		GTA04A5		Pyra(Phone)
										X / Y / Z	X / Y / Z
				 Device
				 - flat on table		0 / 0 / +1	0 / 0 / -1	0/0/-1
				 - upright (phone2ear)	0 / +1 / 0	0 / +1 / 0	+1/0/0
				 - on left edge			+1 / 0 / 0	-1 / 0 / 0	0/-1/0

				 */

#if 0
				NSLog(@"model for accelerometers = %@", model);
#endif
				if([model rangeOfString:@"GTA04A5"].location != NSNotFound)
					{
#if 0
					NSLog(@"invert Y");
#endif
					scaleY=-scaleY;	// invert Y axis of GTA04A5
					}
				else if([model rangeOfString:@"Pyra"].location != NSNotFound)
					{
#if 0
					NSLog(@"invert Y&Z"),
#endif
					scaleY=-scaleY;	// invert Y axis of Pyra
					scaleZ=-scaleZ;	// invert Z axis of Pyra
					}
				break;
				}
			}
#if 0
		NSLog(@"iio accel found: %@ scale=%g", accel, scale);
#endif
		}
	if(accel)
		{
		_deviceMotion->_gravity.x=scaleX*[[NSString stringWithContentsOfFile:[accel stringByAppendingPathComponent:@"in_accel_x_raw"]] intValue];
		_deviceMotion->_gravity.y=scaleY*[[NSString stringWithContentsOfFile:[accel stringByAppendingPathComponent:@"in_accel_y_raw"]] intValue];
		_deviceMotion->_gravity.z=scaleZ*[[NSString stringWithContentsOfFile:[accel stringByAppendingPathComponent:@"in_accel_z_raw"]] intValue];
		}
#else
	// debugging
#define K 0.6
	_deviceMotion->_gravity.x=K*((float)rand()/((float)RAND_MAX)-0.5);
	_deviceMotion->_gravity.y=K*((float)rand()/((float)RAND_MAX)-0.5);
	_deviceMotion->_gravity.z=1;
#endif
#if 0
	NSLog(@"accel x: %g y:%g z:%g", _deviceMotion->_gravity.x, _deviceMotion->_gravity.y, _deviceMotion->_gravity.z);
#endif
	return _deviceMotion;
}

@end
