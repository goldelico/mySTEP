//
//  NSMethodSignatureTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 16.01.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/NSMethodSignature.h>

@interface NSMethodSignatureTest : SenTestCase {
	
}

- (oneway void) unimplemented;
- (oneway void) implemented;

@end

@interface NSMethodSignature (Additions)	// exposed in 10.5 and later
+ (NSMethodSignature *) signatureWithObjCTypes:(const char *)types;
@end

@implementation NSMethodSignatureTest

- (void) test0_crash_NULL_type
{ // introduced in 10.5
	NSMethodSignature *ms;
#if 0	// crashes if called with NULL argument
	ms=[NSMethodSignature signatureWithObjCTypes:NULL];
	STAssertNil(ms, nil);
#endif
}

- (void) test1_basics_void_return
{ // introduced in 10.5
	NSMethodSignature *ms;
	// crashes if called with NULL argument
	ms=[NSMethodSignature signatureWithObjCTypes:"v@:"];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], (NSUInteger) 2, nil);
#if 0	// this is architecture specific!
	STAssertEquals([ms frameLength], (NSUInteger) 8, nil);
#endif
	STAssertTrue(strcmp([ms methodReturnType], "v") == 0, nil);
	STAssertEquals([ms methodReturnLength], (NSUInteger) 0, nil);
	STAssertFalse([ms isOneway], nil);
#if 0	// crashes if called with NULL argument
	ms=[NSMethodSignature signatureWithObjCTypes:NULL];
	STAssertNil(ms, nil);
#endif
}

- (void) test2_retain
{
	NSMethodSignature *ms=[self methodSignatureForSelector:@selector(retain)];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], (NSUInteger) 2, nil);
#if 0	// this is architecture specific!
	STAssertEquals([ms frameLength], (NSUInteger) 8, nil);
#endif
	STAssertTrue(strcmp([ms methodReturnType], "@") == 0, nil);
	STAssertTrue(strcmp([ms getArgumentTypeAtIndex:0], "@") == 0, nil);
	STAssertTrue(strcmp([ms getArgumentTypeAtIndex:1], ":") == 0, nil);
	STAssertThrowsSpecificNamed([ms getArgumentTypeAtIndex:2], NSException, NSInvalidArgumentException, nil);
	STAssertThrowsSpecificNamed([ms getArgumentTypeAtIndex:-1], NSException, NSInvalidArgumentException, nil);
#if 0	// this is architecture specific!
	STAssertEquals([ms methodReturnLength], (NSUInteger) 4, nil);
#endif
	STAssertFalse([ms isOneway], nil);
}

- (void) test3_undefined
{
	NSMethodSignature *ms=[self methodSignatureForSelector:@selector(count)];	// selector that does not exist
	STAssertNil(ms, nil);
}

#if 0	/* will raise a compile warning which we can ignore */
- (oneway void) unimplemented;
{ // this is unimplemented
	return;
}
#endif

- (oneway void) implemented;
{ // this is implemented
	return;
}

- (void) test4_oneway_unimplemented
{
	NSMethodSignature *ms;
	ms=[self methodSignatureForSelector:@selector(unimplemented)];	// header exists but no implementation
	STAssertNil(ms, nil);
}

- (void) test5_oneway_implemented
{
	NSMethodSignature *ms;
	ms=[self methodSignatureForSelector:@selector(implemented)];	// has an implementation
	STAssertNotNil(ms, nil);
	STAssertTrue([ms isOneway], nil);
	/* conclusions:
	 * method must be implemented to have a method signature that we can ask for - defining the protocol is not sufficient
	 */
}

// init with NULL signature
// NSObject methodSignatureForSelector - one that exists @selector(retain)
// NSObject one that exists in a different (sub) class @selector(count)
// one that does not exist in the system @selector(_selector_that_does_not_exist_)
// check frame length, numberOfArguments, returnType, isOneway etc.


@end
