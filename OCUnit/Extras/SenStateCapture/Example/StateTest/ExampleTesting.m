#import "ExampleTesting.h"
#import "SenStateCapture.h"

@implementation MyProcessTesting

- (void)setUp
{
    SenSetUpStateCapture();
    testObj = [[MyProcess alloc] init];
}

- (void)tearDown
{
    SenTearDownStateCapture();
    [testObj release];
}

- (void)testProcessAt1Time
{
    SenEmitRefState(State_Begin);
    SenEmitRefState(State_Process);
    SenEmitRefState(State_End);
    
    [testObj run:1];
    
    assertMatchStates;
}

- (void)testProcessAt5Times
{
    SenEmitRefState(State_Begin);
    SenEmitRefState(State_Process);
    SenEmitRefState(State_Process);
    SenEmitRefState(State_Process);
    SenEmitRefState(State_Process);
    SenEmitRefState(State_Process);
    SenEmitRefState(State_End);
    
    [testObj run:5];
    
    assertMatchStates;
}

@end