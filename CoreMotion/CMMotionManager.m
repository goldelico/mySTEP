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
	// if not yet located, locate iio devices
	// read iio values
	// store values in CMDeviceMotion object
	_deviceMotion->_gravity.x=(float)rand()/((float)3*RAND_MAX)-0.5;
	_deviceMotion->_gravity.y=(float)rand()/((float)3*RAND_MAX)-0.5;
	_deviceMotion->_gravity.z=1;
	return _deviceMotion;
}

@end
