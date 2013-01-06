#import "SenTestStateCapture.h"
#import "SenStateCapture.h"

// Copyright (c) 2004 Erik D. Holley.  All rights reserved. eholley@kelibo.com

#undef assertFailTest
#define assertFailTest(testSelector, failCount, ...) \
do {    \
    SenTest *failTest = [[self class] testCaseWithSelector:(testSelector)];  \
    [SenTestObserver suspendObservation];   \
    SenTestRun *failTestRun = [failTest run];     \
    [SenTestObserver resumeObservation];    \
    assertTrue (([failTestRun failureCount] == (failCount)), __VA_ARGS__);   \
    assertTrue (([failTestRun unexpectedExceptionCount] == 0), __VA_ARGS__);    \
    assertFalse (([failTestRun hasSucceeded]), __VA_ARGS__);       \
} while(0)


@implementation SenStateCaptureTest

- (void)setUp
{
    SenSetUpStateCapture();
}

- (void)tearDown
{
    SenTearDownStateCapture();
}


- (void)testReportSenStates
{
    // 3 run states
    SenEmitRunState(@"a");
    SenEmitRunState(@"b");
    SenEmitRunState(@"c");
    
    // to compare against 3 run states
    SenEmitRefState(@"a");  
    SenEmitRefState(@"b");
    SenEmitRefState(@"c");
    
    SenEmitLogMsgs(YES);
    SenReportStates();
    SenEmitLogMsgs(NO);
            
    // to compare against output of 3 run states
    SenEmitRefState(@"States (Ref) (Run) {");
    SenEmitRefState(@"  0: (a) (a)");
    SenEmitRefState(@"  1: (b) (b)");
    SenEmitRefState(@"  2: (c) (c)");
    SenEmitRefState(@"}");

    assertMatchStates;
}


- (void)testPassShouldMatchStatesBothValid
{
    SenEmitRefState(@"testing");
    SenEmitRunState(@"testing");
    assertMatchStates;
}


- (void)testPassShouldMatchStatesBothNil
{
    assertMatchStates;
}


- (void)runFailShouldMatchStatesBothValid
{
    SenEmitRefState(@"testing ref");
    SenEmitRunState(@"testing run");
    assertMatchStates;
}

- (void)testFailShouldMatchStatesBothValid
{   
    assertFailTest(@selector(runFailShouldMatchStatesBothValid), 1, @"See testFailShouldMatchStatesBothValid");
}


- (void)runFailShouldMatchStatesRefNil
{
    SenEmitRunState(@"testing run");
    assertMatchStates;
}

- (void)testFailShouldMatchStatesRefNil
{   
    assertFailTest(@selector(runFailShouldMatchStatesRefNil), 1, @"See testFailShouldMatchStatesRefNil");
}


- (void)runFailShouldMatchStatesRunNil
{
    SenEmitRefState(@"testing ref");
    assertMatchStates;
}

- (void)testFailShouldMatchStatesRunNil
{   
    assertFailTest(@selector(runFailShouldMatchStatesRunNil), 1, @"See testFailShouldMatchStatesRunNil");
}


- (void)runFailShouldMatchStatesOutOfBalanceRef
{
    SenEmitRefState(@"testing a");
    SenEmitRefState(@"testing b");
    SenEmitRefState(@"testing c");
    SenEmitRefState(@"testing d");
    
    SenEmitRunState(@"testing a");
    SenEmitRunState(@"testing b");
    
    assertMatchStates;
}

- (void)testFailShouldMatchStatesOutOfBalanceRef
{   
    assertFailTest(@selector(runFailShouldMatchStatesOutOfBalanceRef), 2, @"See testFailShouldMatchStatesOutOfBalanceRef");
}

- (void)runFailShouldMatchStatesOutOfBalanceRun
{
    SenEmitRefState(@"testing a");
    SenEmitRefState(@"testing b");
    
    SenEmitRunState(@"testing a");
    SenEmitRunState(@"testing b");
    SenEmitRunState(@"testing c");
    SenEmitRunState(@"testing d");
    SenEmitRunState(@"testing e");
    
    assertMatchStates;
}

- (void)testFailShouldMatchStatesOutOfBalanceRun
{
    assertFailTest(@selector(runFailShouldMatchStatesOutOfBalanceRun), 3, @"See testFailShouldMatchStatesOutOfBalanceRun");
}


- (void)testCaptureSenLog
{
    SenEmitRefState(@"should be captured");
    SenEmitRefState(@"this, too");

    SenLog(@"should not be captured");
    SenEmitLogMsgs(YES);
    SenLog(@"should be captured");   
    SenLog(@"this, too");
    SenEmitLogMsgs(NO);
    SenLog(@"but not this");
    
    assertMatchStates;
}


- (void)testEmitSenStateMacro
{
    SenEmitRefState(@"testing");
    SenEmitState(@"testing");
    assertMatchStates;
}

@end

