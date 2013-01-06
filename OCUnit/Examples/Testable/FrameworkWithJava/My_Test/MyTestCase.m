/* MyTestCase.m created by peter on Wed 01-Mar-2000 */

#import "MyTestCase.h"
#import <My/ClassUsingJava.h>

@implementation MyTestCase

- (void)setUp {
    
    //[[NSBundle bundleWithPath:@"/Network/Users/phink/Library/Frameworks/My.framework"] load];

    // Uncomment the line above and change the path to the framework,
    // and the test case won't fail.
    //
    // Let's pretend that My.framework doesn't contain any Java classes,
    // but instead uses another framework that does -- then that framework
    // would have to be explicitly loaded for the test case to succeed.
    //
    // Also, if there would be two Java-using frameworks among all the
    // dependant frameworks, both need to be explicitly loaded.
    //
    // The "best" solution would be for otest to traverse and load all
    // dependant frameworks - just like WOApplication and EOApplication
    // does.
    // - Peter
    //
    // This is corrected, OCUnit v16 and above. -marco
}

- (void)test {
    ClassUsingJava *cuj = [[[ClassUsingJava alloc] init] autorelease];
    shouldBeEqual([cuj string], @"String from JavaClass");
}

@end
