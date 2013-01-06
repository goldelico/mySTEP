/* SetTestCase.m created by marco on Sat 06-Jun-1998 */

#import "SetTestCase.h"
#import <SenTestingKit/SenTestingKit.h>
#import <SenFoundation/SenFoundation.h>

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
    should ([empty containsObject:@"x"]);
}


- (void) testEqual
{
    shouldBeEqual(@"x", @"x");
    shouldBeEqual(@"x", @"y");
}


- (void) testIllegal
{
    shouldRaise ([(NSMutableSet *) immutable addObject:@"0"]);
    shouldRaise ([empty addObject:@"0"]);
}


- (void)  tearDown
{
    RELEASE (empty);
    RELEASE (full);
    RELEASE (immutable);
}
@end
