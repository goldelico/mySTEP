/* SomeTest.m created by phink on Thu 02-Mar-2000 */

#import "SomeTest.h"
#import <Some.h>

@implementation SomeTest

- (void) testYes
{
    id some = [[[Some alloc] init] autorelease];
    should ([some yes]);
}

@end
