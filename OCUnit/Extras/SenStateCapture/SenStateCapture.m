#import "SenStateCapture.h"
#import <stdarg.h>


// SenStateCapture v1.0
// Copyright (c) 2004 Erik D. Holley.  All rights reserved. eholley@kelibo.com

////////////////////////////////////////////////////////////////////////////////
// SenStateCapture
////////////////////////////////////////////////////////////////////////////////

id SenRefStateContainer = nil;
id SenRunStateContainer = nil;
BOOL SenCapturingStates = NO;

void SenSetUpStateCapture()
{
    if(!SenCapturingStates) {
        SenRefStateContainer = [[NSMutableArray alloc] init];
        SenRunStateContainer = [[NSMutableArray alloc] init];
        SenCapturingStates = YES;
    } else {
        [SenRefStateContainer retain];
        [SenRunStateContainer retain];
        SenForgetStates();
    }
}

void SenTearDownStateCapture()
{
    unsigned refRetainCount = [SenRefStateContainer retainCount];
    SenForgetStates();
    [SenRefStateContainer release];
    [SenRunStateContainer release];
    if(refRetainCount==1) {
        SenCapturingStates = NO;
        SenRefStateContainer = nil;
        SenRunStateContainer = nil;
    }
}

void SenForgetStates()
{
    [SenRefStateContainer removeAllObjects];
    [SenRunStateContainer removeAllObjects];
}

void SenEmitRefState(id state)
{
    if(state)
        [SenRefStateContainer addObject:state];
}

void SenEmitRunState(id state)
{
    if(state)
        [SenRunStateContainer addObject:state];
}

void SenReportStates()
{
    unsigned index = 0;
    id refState, runState;
    unsigned refStatesCount = [SenRefStateContainer count];
    unsigned runStatesCount = [SenRunStateContainer count];
    SenLog(@"States (Ref) (Run) {");
    do {
        refState = (index>=refStatesCount) ? nil : [SenRefStateContainer objectAtIndex:index];
        runState = (index>=runStatesCount) ? nil : [SenRunStateContainer objectAtIndex:index];
        if(refState || runState)
            SenLog(@"  %u: (%@) (%@)", index, [refState description], [runState description]);
        index++;
    } while(refState || runState);
    SenLog(@"}");
}


////////////////////////////////////////////////////////////////////////////////
// SenLog
////////////////////////////////////////////////////////////////////////////////

void (*SenLog)(NSString *format, ...) = &NSLog;

void SenLogEmitState(NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    NSString *composed = [[[NSString alloc] initWithFormat:format arguments:argList] autorelease];
    va_end(argList);
    NSLog(composed);
    SenEmitRunState(composed);
}

void SenEmitLogMsgs(BOOL emitMsgs)
{
    if(emitMsgs)
        SenLog = &SenLogEmitState;
    else
        SenLog = &NSLog;
}