#import "TestInterface.h"

@implementation TestInterface

- (void) setUp
{
    [textField setStringValue:@"xxx"];
}


- (void) testPass
{
    STAssertTrue (([[textField stringValue] isEqualToString:@"xxx"]),
                  @"The text field should contain xxx.");
}


- (void) testFailOnPurpose
{
    STAssertFalse (([[textField stringValue] isEqualToString:@"xxx"]),
                   @"This test should fail on purpose.");
}
@end
