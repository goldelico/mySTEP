/* SetTestCase.h created by marco on Sat 06-Jun-1998 */

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestCase.h>

@interface SetTestCase : SenTestCase
{
    NSMutableSet *empty;
    NSMutableSet *full;
    NSSet *immutable;
}

@end
