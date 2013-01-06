/* Delegate.m created by phink on Thu 02-Mar-2000 */

#import "Delegate.h"

@implementation Delegate

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{
    if (YES) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Tests" ofType:@"bundle"]; 
        [[NSBundle bundleWithPath:path] load];
    }
}
@end
