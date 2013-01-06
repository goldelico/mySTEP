/* ClosurePerformanceTest.m created by phink on Thu 10-Dec-1998 */

#import "ClosurePerformanceTest.h"
#import <SenFoundation/SenFoundation.h>

#define RepetitionCount 10
#define ElementCount    10

@implementation ClosurePerformanceTest
- (void) setUp
{
    int count = ElementCount;
    source = [[NSMutableArray arrayWithCapacity:ElementCount] retain];
    while (count--) {
        [source addObject:[NSNumber numberWithInt:count]];
    }
}


- (void) testCollecting
{
    id pool = [[NSAutoreleasePool alloc] init];
    int repetition = RepetitionCount;
    while (repetition--) {
        (void) [source collectionByPerformingSelector:@selector(stringValue)];
    }
    [pool release];
}


- (void) testEnumerator
{
    id pool = [[NSAutoreleasePool alloc] init];
    int repetition = RepetitionCount;
    while (repetition--) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[source count]];
        NSEnumerator *enumerator = [source objectEnumerator];
        id each;
        while (each = [enumerator nextObject]) {
            [array addObject:[each stringValue]];
        }
    }
    [pool release];
}


- (void) testLoop
{
    id pool = [[NSAutoreleasePool alloc] init];
    int repetition = RepetitionCount;
    while (repetition--) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[source count]];
        unsigned i;
        for (i = 0; i < ElementCount; i++) {
            [array addObject:[[source objectAtIndex:i] stringValue]];
        }
    }
    [pool release];
}

#if 0
- (void) testTrampoline
{
    id pool = [[NSAutoreleasePool alloc] init];
    int repetition = RepetitionCount;
    while (repetition--) {
        [[source collect] stringValue];
    }
    [pool release];
}
#endif

- (void) tearDown
{
    RELEASE(source);
}
@end
