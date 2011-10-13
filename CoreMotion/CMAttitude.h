//
//  CMAttitude.h
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _CMRotationMatrix
{
	double m11, m12, m13;
	double m21, m22, m23;
	double m31, m32, m33;
} CMRotationMatrix;

typedef struct _CMQuaternion
{
	double x, y, z, w;
} CMQuaternion;

typedef enum _CMAttitudeReferenceFrame
{
	CMAttitudeReferenceFrameXArbitraryZVertical				= 1 << 0,
	CMAttitudeReferenceFrameXArbitraryCorrectedZVertical	= 1 << 1,
	CMAttitudeReferenceFrameXMagneticNorthZVertical			= 1 << 2,
	CMAttitudeReferenceFrameXTrueNorthZVertical				= 1 << 3
} CMAttitudeReferenceFrame;

@interface CMAttitude : NSObject <NSCoding, NSCopying>
{

}

- (double) pitch;
- (double) roll;
- (double) yaw;

- (CMQuaternion) quaternion;
- (CMRotationMatrix) rotationMatrix;

- (void) multiplyByInverseOfAttitude:(CMAttitude *) attitude;

@end
