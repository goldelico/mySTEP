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
 *
 * see drawing: http://nshipster.s3.amazonaws.com/cmdm-axes.png
 *
 * this means:
 *  device sitting display up on a table:			0, 0, -1
 *  device standing on the lower edge (microphone):	0, -1, 0
 *  device standing on the left edge:				-1, 0, 0
 *
 * see: http://nshipster.com/cmdevicemotion/
 * code example: https://gist.github.com/cyndibaby905/11200578
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
