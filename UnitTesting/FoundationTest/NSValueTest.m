//
//  NSValueTest.m
//  UnitTests
//
//  Note: SenTestingKit requires a working implementation of NSValue!
//        Therefore it is tricky do work on that class through test driven development.
//
//  Created by H. Nikolaus Schaller on 01.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSValueTest : XCTestCase
{
	
}

@end


@implementation NSValueTest

- (void) test70
{
	struct test70
	{
		int a;
		char *b;
	} c;
	NSValue *val;
	val=[NSValue value:"cstring" withObjCType:@encode(char *)];
	XCTAssertNotNil(val, @"create cstring");
//	XCTAssertEqual((char *) [val objCType], (char *) "*", @"");
//	XCTAssertEqual((char *) [val pointerValue], (char *) "cstring", @"");
	val=[NSValue value:&c withObjCType:@encode(struct test70)];
	c.a=5;
	c.b="string constant";
	XCTAssertNotNil(val, @"string constant");
//	XCTAssertEqual((char *) [val objCType], (char *) "^", @"");
//	XCTAssertEqual(((struct test70 *) [val pointerValue])->a, 5, @"");
//	XCTAssertEqual(((struct test70 *) [val pointerValue])->b, "string constant", @"");	
	val=[NSValue value:&c.a withObjCType:@encode(int)];
	XCTAssertNotNil(val, @"int value");
//	XCTAssertEqual([val objCType], "^", @"");
}

- (void) test80
{
	float obj=3.1415;
	NSValue *val=[NSValue valueWithBytes:&obj objCType:@encode(float)];
//	XCTAssertEqual([val class], [NSValue class], @""); -- no

	// this does fail with incompatible types - why???
//	XCTAssertEqual([val objCType], (const char *)@encode(float), @"");	// type is id
//	XCTAssertEqual([val nonretainedObjectValue], nil, @"");	// has been stored
}

- (void) test90
{
	id obj=[NSObject new];	// create object
	NSUInteger retainCount=[obj retainCount];
	NSValue *val=[NSValue valueWithNonretainedObject:obj];
//	XCTAssertEqual([val class], [NSValue class], @"");
	XCTAssertEqual([val nonretainedObjectValue], obj, @"nonretained");	// has been stored
	XCTAssertEqual([obj retainCount], retainCount, @"retain");	// is NOT retained
//	XCTAssertEqual([val objCType], (const char *)@encode(id), @"");	// type is id
	val=[NSValue valueWithBytes:&obj objCType:@encode(id)];
//	XCTAssertEqual([val class], [NSValue class], @"");
	XCTAssertEqual([val nonretainedObjectValue], obj, @"store");	// has been stored
	XCTAssertEqual([obj retainCount], retainCount, @"retain");	// is NOT retained
//	XCTAssertEqual([val objCType], (const char *)@encode(id), @"");	// type is id
	val=[NSValue valueWithBytes:&obj objCType:@encode(void *)];
//	XCTAssertEqual([val class], [NSValue class], @"");
	XCTAssertEqual([val nonretainedObjectValue], obj, @"store");	// has been stored
	XCTAssertEqual([obj retainCount], retainCount, @"retain");	// is NOT retained
//	XCTAssertEqual([val objCType], (const char *)@encode(id), @"");	// type is id
}

@end

/* more tests
 * [nsnumber isEqual:nil] - raise exception?
 */

