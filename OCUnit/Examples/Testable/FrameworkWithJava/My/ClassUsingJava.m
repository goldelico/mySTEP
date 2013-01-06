/* ClassUsingJava.m created by peter on Wed 01-Mar-2000 */

#import "ClassUsingJava.h"

@implementation ClassUsingJava

- (NSString *)string {
    return [NSClassFromString(@"JavaClass") performSelector:@selector(string)];
}

@end
