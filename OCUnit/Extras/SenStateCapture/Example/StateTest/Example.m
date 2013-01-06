#import "Example.h"
#import "SenStateCapture.h"

NSString * const State_Begin    = @"begin";
NSString * const State_End      = @"end";
NSString * const State_Process  = @"process";

@implementation MyProcess

- (id)init
{
    return [super init];
}

- (void)run:(int)times
{
    SenEmitState(State_Begin);
    
    // start the lengthy process
    
    while(times--) {
        SenEmitState(State_Process);
        // perform processing
    }
    
    // close down process
    
    SenEmitState(State_End);
}

@end