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

typedef enum {
	CMMagneticFieldCalibrationAccuracyUncalibrated=-1,
	CMMagneticFieldCalibrationAccuracyLow,
	CMMagneticFieldCalibrationAccuracyMedium,
	CMMagneticFieldCalibrationAccuracyHigh
} CMMagneticFieldCalibrationAccuracy;

typedef struct _CMCalibratedMagneticField
{ // in uTesla
	CMMagneticField field;
	CMMagneticFieldCalibrationAccuracy accuracy;
} CMCalibratedMagneticField;

@interface CMMagnetometerData : CMLogItem
{

}

- (CMMagneticField) magneticField;

@end
