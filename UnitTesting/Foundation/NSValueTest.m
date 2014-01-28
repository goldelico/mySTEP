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

#import <SenTestingKit/SenTestingKit.h>


@interface NSValueTest : SenTestCase
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
	STAssertNotNil(val, nil);
//	STAssertEquals((char *) [val objCType], (char *) "*", nil);
//	STAssertEquals((char *) [val pointerValue], (char *) "cstring", nil);
	val=[NSValue value:&c withObjCType:@encode(struct test70)];
	c.a=5;
	c.b="string constant";
	STAssertNotNil(val, nil);
//	STAssertEquals((char *) [val objCType], (char *) "^", nil);
//	STAssertEquals(((struct test70 *) [val pointerValue])->a, 5, nil);
//	STAssertEquals(((struct test70 *) [val pointerValue])->b, "string constant", nil);	
	val=[NSValue value:&c.a withObjCType:@encode(int)];
	STAssertNotNil(val, nil);
//	STAssertEquals([val objCType], "^", nil);
}

- (void) test80
{
	float obj=3.1415;
	NSValue *val=[NSValue valueWithBytes:&obj objCType:@encode(float)];
//	STAssertEquals([val class], [NSValue class], nil); -- no

	// this does fail with incompatible types - why???
//	STAssertEquals([val objCType], (const char *)@encode(float), nil);	// type is id
//	STAssertEquals([val nonretainedObjectValue], nil, nil);	// has been stored
}

- (void) test90
{
	id obj=[NSObject new];	// create object
	unsigned retainCount=[obj retainCount];
	NSValue *val=[NSValue valueWithNonretainedObject:obj];
//	STAssertEquals([val class], [NSValue class], nil);
	STAssertEquals([val nonretainedObjectValue], obj, nil);	// has been stored
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
//	STAssertEquals([val objCType], (const char *)@encode(id), nil);	// type is id
	val=[NSValue valueWithBytes:&obj objCType:@encode(id)];
//	STAssertEquals([val class], [NSValue class], nil);
	STAssertEquals([val nonretainedObjectValue], obj, nil);	// has been stored
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
//	STAssertEquals([val objCType], (const char *)@encode(id), nil);	// type is id
	val=[NSValue valueWithBytes:&obj objCType:@encode(void *)];
//	STAssertEquals([val class], [NSValue class], nil);
	STAssertEquals([val nonretainedObjectValue], obj, nil);	// has been stored
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
//	STAssertEquals([val objCType], (const char *)@encode(id), nil);	// type is id
}

@end

/* more tests
 * [nsnumber isEqual:nil] - raise exception?
 */

