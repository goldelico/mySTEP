//
//  CMDeviceMotion.h
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <CoreMotion/CMLogItem.h>
#import <CoreMotion/CMAttitude.h>
#import <CoreMotion/CMAccelerometer.h>
#import <CoreMotion/CMGyro.h>
#import <CoreMotion/CMMagnetometer.h>

@interface CMDeviceMotion : CMLogItem
{
	@public
	CMAttitude *_attitude;
	CMAcceleration _gravity;
	CMCalibratedMagneticField _magneticField;
	CMRotationRate _rotationRate;
	CMAcceleration _userAcceleration;
}

- (CMAttitude *) attitude;
- (CMAcceleration) gravity;
- (CMCalibratedMagneticField) magneticField;
- (CMRotationRate) rotationRate;
- (CMAcceleration) userAcceleration;

@end
