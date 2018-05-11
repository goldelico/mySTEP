//
//  CMAccelerometer.h
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <CoreMotion/CMLogItem.h>

/*
 * if device is held in portrait orientation and facing the display
 *   X-axis runs through the device from left (-) to right (+)
 *   Y-axis through the device from bottom (-) to top (+)
 *   Z-axis runs from the back (-) through the screen to the front (+)
 * values are in units of "g"
 */

typedef struct _CMAcceleration
{
	double x;
	double y;
	double z;
} CMAcceleration;


@interface CMAccelerometer : CMLogItem
{

}

- (CMAcceleration) acceleration;

@end
