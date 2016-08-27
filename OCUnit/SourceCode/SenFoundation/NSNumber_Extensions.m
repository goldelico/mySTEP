/*$Id: NSNumber_Extensions.m,v 1.1 2002/01/08 14:54:02 alain Exp $*/

#import "NSNumber_Extensions.h"
#import <SenFoundation/SenFoundation.h>

@implementation NSNumber (Extensions)
+ (NSNumber *) zero
{
    static NSNumber *zero = nil;
    if (zero == nil) {
        zero = [[NSNumber alloc] initWithInt:0];
    }
    return zero;
}


+ (NSNumber *) one
{
    static NSNumber *one = nil;
    if (one == nil) {
        one = [[NSNumber alloc] initWithInt:1];
    }
    return one;

}
@end
