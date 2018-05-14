//
//  CMMotionManager.m
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

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
	static double scale;
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
				scale=[sc doubleValue]/9.81;	// iio returns kg/s^2
				accel=[device retain];
				break;
				}
			}
#if 0
		NSLog(@"iio accel found: %@ scale=%g", accel, scale);
#endif
		}
	if(accel)
		{
		_deviceMotion->_gravity.x=scale*[[NSString stringWithContentsOfFile:[accel stringByAppendingPathComponent:@"in_accel_x_raw"]] intValue];
		_deviceMotion->_gravity.y=scale*[[NSString stringWithContentsOfFile:[accel stringByAppendingPathComponent:@"in_accel_y_raw"]] intValue];
		_deviceMotion->_gravity.z=scale*[[NSString stringWithContentsOfFile:[accel stringByAppendingPathComponent:@"in_accel_z_raw"]] intValue];
		// swap&scale depending on device model adjustments
		// should read the Device database...
		// GTA04A5:
		_deviceMotion->_gravity.x=-_deviceMotion->_gravity.x;
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
