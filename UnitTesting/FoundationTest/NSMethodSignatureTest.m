//
//  NSMethodSignatureTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 16.01.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/NSMethodSignature.h>

@interface NSMethodSignatureTest : XCTestCase {
	
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
	XCTAssertNil(ms, nil);
#endif
}

- (void) test1_basic_void_return
{ // introduced in 10.5
	NSMethodSignature *ms;
	// crashes if called with NULL argument
	ms=[NSMethodSignature signatureWithObjCTypes:"v@:"];
	XCTAssertNotNil(ms, nil);
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 2, nil);
#if 0	// this is architecture specific!
	XCTAssertEqual([ms frameLength], (NSUInteger) 8, nil);
#endif
	XCTAssertTrue(strcmp([ms methodReturnType], "v") == 0, nil);
	XCTAssertEqual([ms methodReturnLength], (NSUInteger) 0, nil);
	XCTAssertFalse([ms isOneway], nil);
#if 0	// crashes if called with NULL argument
	ms=[NSMethodSignature signatureWithObjCTypes:NULL];
	XCTAssertNil(ms, nil);
#endif
}

- (void) test2_for_retain
{
	NSMethodSignature *ms=[self methodSignatureForSelector:@selector(retain)];
	XCTAssertNotNil(ms, nil);
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 2, nil);
#if 0	// this is architecture specific!
	XCTAssertEqual([ms frameLength], (NSUInteger) 8, nil);
#endif
	XCTAssertTrue(strcmp([ms methodReturnType], "@") == 0, nil);
	XCTAssertTrue(strcmp([ms getArgumentTypeAtIndex:0], "@") == 0, nil);
	XCTAssertTrue(strcmp([ms getArgumentTypeAtIndex:1], ":") == 0, nil);
	XCTAssertThrowsSpecificNamed([ms getArgumentTypeAtIndex:2], NSException, NSInvalidArgumentException, nil);
	XCTAssertThrowsSpecificNamed([ms getArgumentTypeAtIndex:-1], NSException, NSInvalidArgumentException, nil);
#if 0	// this is architecture specific!
	XCTAssertEqual([ms methodReturnLength], (NSUInteger) 4, nil);
#endif
	XCTAssertFalse([ms isOneway], nil);
}

- (void) test3_for_undefined_method_count
{
	NSMethodSignature *ms=[self methodSignatureForSelector:@selector(count)];	// selector that does not exist
	XCTAssertNil(ms, nil);
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
	XCTAssertNil(ms, nil);
}

- (void) test5_oneway_implemented
{
	NSMethodSignature *ms;
	ms=[self methodSignatureForSelector:@selector(implemented)];	// has an implementation
	XCTAssertNotNil(ms, nil);
	XCTAssertTrue([ms isOneway], nil);
	/* conclusions:
	 * method must be implemented to have a method signature that we can ask for - defining the protocol is not sufficient
	 */
}

- (void) test6_cached
{ // introduced in 10.5
	NSMethodSignature *ms1, *ms2;
	ms1=[NSMethodSignature signatureWithObjCTypes:"v@:"];
	XCTAssertNotNil(ms1, nil);
	ms2=[NSMethodSignature signatureWithObjCTypes:"v@:"];
	XCTAssertEqualObjects(ms1, ms2, nil);	// should be equal of course
	XCTAssertTrue(ms1 == ms2, nil);	//  method-signatures return the same object for identical encoding (cache)
}

@end
