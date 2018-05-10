//
//  CMMotionManager.h
//  CoreMotion
//
//  Created by H. Nikolaus Schaller on 12.10.11.
//  Copyright 2011 quantumstep. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMDeviceMotion;

@interface CMMotionManager : NSObject
{

}

- (void) startDeviceMotionUpdates;
- (void) stopDeviceMotionUpdates;
- (CMDeviceMotion *) deviceMotion;

@end
