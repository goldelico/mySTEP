//
//  CMGyro.h
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <CoreMotion/CMLogItem.h>

/*
 * if device is held in portrait orientation and facing the display
 *   X-axis means tilting back (-?) and forth (+?)
 *   Y-axis means tilting left and right
 *   Z-axis means turing the screen
 * values are in units of "°/s" ???
 */

typedef struct _CMRotationRate
{
	double x;
	double y;
	double z;
} CMRotationRate;

@interface CMGyro : CMLogItem
{

}

- (CMRotationRate) rotationRate;

@end
