/* SetTestCase.m created by marco on Sat 06-Jun-1998 */

#import "SetTestCase.h"
#import <SenTestingKit/SenTestingKit.h>

@implementation SetTestCase

- (void) setUp
{
    empty = [[NSMutableSet alloc] init];
    full = [[NSMutableSet alloc] init];
    immutable = [[NSSet setWithObjects:@"1", nil] retain];
}

- (void) testAdd
{
    [empty addObject:@"x"];
    STAssertTrue (([empty containsObject:@"x"]),
                  @"The empty set should contain x.");
}


- (void) testEqual
{
    STAssertEqualObjects(@"x", @"x", @"x should equal x.");
//    STAssertEqualObjects(@"x", @"y", @"");
}


- (void) testIllegal
{
    STAssertThrows (([NSException raise:NSGenericException format:@"A voluntary error"]),
                    @"A voluntary throw.");
//    STAssertThrows ([(NSMutableSet *) immutable addObject:@"0"], @"");
//    STAssertThrows ([empty addObject:@"0"], @""");
}

- (void)  tearDown
{
    RELEASE (empty);
    RELEASE (full);
    RELEASE (immutable);
}
@end
