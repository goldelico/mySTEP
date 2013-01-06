/*$Id: SenTestableProjectType.m,v 1.1 2003/11/21 14:44:33 phink Exp $*/
// Copyright (c) 2000 Sen:te Ltd.  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenTestableProjectType.h"

#define TEST_TARGETS [NSArray arrayWithObjects:@"test", @"test_debug", nil]

@implementation SenTestableProjectType

- (NSArray *)buildTargets
{
    return [[super buildTargets] arrayByAddingObjectsFromArray:TEST_TARGETS];
}


+ (void) initialize
{
    static BOOL isInitialized = NO;

    if (!isInitialized) {
        [SenTestableProjectType poseAsClass:[PBProjectType class]];
        [super initialize];
        isInitialized = YES;
    }
}
@end
