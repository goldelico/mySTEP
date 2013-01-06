#import "SenStateCapture.h"
#import <SenTestingKit/SenTestingKit.h>

// Copyright (c) 2004 Erik D. Holley.  All rights reserved. eholley@kelibo.com

@interface SenStateCaptureTest : SenTestCase
- (void)runFailShouldMatchStatesBothValid;
- (void)runFailShouldMatchStatesRefNil;
- (void)runFailShouldMatchStatesRunNil;
- (void)runFailShouldMatchStatesOutOfBalanceRef;
- (void)runFailShouldMatchStatesOutOfBalanceRun;
@end
