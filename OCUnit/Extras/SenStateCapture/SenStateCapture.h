#import <Foundation/Foundation.h>


// SenStateCapture v1.0
// Copyright (c) 2004 Erik D. Holley.  All rights reserved. eholley@kelibo.com

////////////////////////////////////////////////////////////////////////////////
// SenStateCapture Program API - use these functions in the program to be tested
////////////////////////////////////////////////////////////////////////////////

#undef  SenEmitState
#define SenEmitState(s)  (SenCapturingStates ? SenEmitRunState(s) : 0)

extern void SenEmitRunState(id state);
extern void (*SenLog)(NSString *format, ...);

extern BOOL SenCapturingStates;

////////////////////////////////////////////////////////////////////////////////
// SenStateCapture Testing API - use these functions in your SenTestCase
////////////////////////////////////////////////////////////////////////////////

extern void SenSetUpStateCapture();
extern void SenTearDownStateCapture();
extern void SenForgetStates();
extern void SenEmitRefState(id state);
extern void SenEmitLogMsgs(BOOL emitMsgs);
extern void SenReportStates();

extern id SenRefStateContainer; // don't access directly, here for assertMatchStates macro
extern id SenRunStateContainer; // don't access directly, here for assertMatchStates macro

#undef assertMatchStates
#define assertMatchStates \
do {    \
    unsigned index = 0; \
    id refState, runState;  \
    unsigned refStatesCount = [SenRefStateContainer count];     \
    unsigned runStatesCount = [SenRunStateContainer count];     \
    do {    \
        refState = (index>=refStatesCount) ? nil : [SenRefStateContainer objectAtIndex:index];  \
        runState = (index>=runStatesCount) ? nil : [SenRunStateContainer objectAtIndex:index];  \
        if(refState || runState) \
            assertEqual(refState, runState, @"State at index %u: (Ref) (Run)",index);  \
        index++;    \
    } while(refState || runState);  \
} while(0)

