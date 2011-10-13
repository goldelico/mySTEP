//
//  CMMagnetometer.h
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <CoreMotion/CMLogItem.h>


typedef struct _CMMagneticField
{ // in uTesla
	double x;
	double y;
	double z;
} CMMagneticField;

@interface CMMagnetometerData : CMLogItem
{

}

- (CMMagneticField) magneticField;

@end
