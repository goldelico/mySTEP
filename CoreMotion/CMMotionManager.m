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

- (NSString *) description;
{
	// FIXME: add others
	return [NSString stringWithFormat:@"g.x=%+4.1lf g.y=%+4.1lf g.z=%+4.1lf", _gravity.x, _gravity.y, _gravity.z];
}


@end

@implementation CMGyro

@end

@implementation CMLogItem

@end

@implementation CMMagnetometerData

@end

@implementation CMMotionManager

- (void) dealloc
{
	[self stopDeviceMotionUpdates];
	[super dealloc];
}

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
				/* on GTA04A5 it turns out that some axis are inverted
				 compared to the GTA04A4. This should have been
				 handled/unified by the kernel, but it isn't.

				 Device					GTA04A4		GTA04A5		Pyra(Phone)
				 Raw iio data			X / Y / Z	X / Y / Z	X/Y/Z
				 - flat on table		0 / 0 / +1	0 / 0 / -1	0/0/-1
				 - upright (phone2ear)	0 / +1 / 0	0 / +1 / 0	+1/0/0
				 - on left edge			+1 / 0 / 0	-1 / 0 / 0	0/-1/0

				 */

				scaleX=scaleY=scaleZ=-[sc doubleValue]/9.81;	// iio returns kg/s^2
				accel=[device retain];

				/* should use device configuration database */
				NSString *model=[[[UIDevice new] autorelease] model];

				/* to make things worse,
				 * some devices can have multiple sensors with different orientations!
				 */

				NSString *chip=[NSString stringWithContentsOfFile:[device stringByAppendingPathComponent:@"name"]];
				chip=[chip stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

#if 0
				NSLog(@"model for accelerometers = %@ chip name = %@ device = %@", model, chip, device);
#endif
				if([model rangeOfString:@"GTA04A5"].location != NSNotFound)
					{
					if([chip isEqualToString:@"bno055"])
						{ // bno055
						scaleX *= -1;	// invert X axis of GTA04A5
						scaleZ *= -1;	// invert Z axis of GTA04A5
						}
					else
						{ // bmc150_accel
						scaleY *= -1;	// invert Y axis of GTA04A5
						scaleZ *= -1;	// invert Z axis of GTA04A5
						}
					}
				else if([model rangeOfString:@"GTA15"].location != NSNotFound)
					{ // PyraPhone needs a different processing!

					}
				else if([model rangeOfString:@"Pyra"].location != NSNotFound)
					{
					scaleX *= -1;	// invert X axis of Pyra
					scaleZ *= -1;	// invert Z axis of Pyra
					}
				else
					; // assume GTA04A3/4 with bma180
				break;
				}
			}
#if 0
		NSLog(@"iio accel found: %@ scaleX=%g %g %g", accel, scaleX, scaleY, scaleZ);
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
