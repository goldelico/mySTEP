//
//  NSValueTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 01.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSValueTest.h"


@implementation NSValueTest

- (void) test80
{
	float obj=3.1415;
	NSValue *val=[NSValue valueWithBytes:&obj objCType:@encode(float)];
	
	// this does fail with incompatible types - why???

//	STAssertEquals([val objCType], (const char *)@encode(float), nil);	// type is id
//	STAssertEquals([val nonretainedObjectValue], nil, nil);	// has been stored
}


- (void) test90
{
	id obj=[NSObject new];	// create object
	unsigned retainCount=[obj retainCount];
	NSValue *val=[NSValue valueWithNonretainedObject:obj];
	STAssertEquals([val nonretainedObjectValue], obj, nil);	// has been stored
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
//	STAssertEquals([val objCType], (const char *)@encode(id), nil);	// type is id
	val=[NSValue valueWithBytes:&obj objCType:@encode(id)];
	STAssertEquals([val nonretainedObjectValue], obj, nil);	// has been stored
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
//	STAssertEquals([val objCType], (const char *)@encode(id), nil);	// type is id
	val=[NSValue valueWithBytes:&obj objCType:@encode(void *)];
	STAssertEquals([val nonretainedObjectValue], obj, nil);	// has been stored
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
//	STAssertEquals([val objCType], (const char *)@encode(id), nil);	// type is id
}

@end

/* more tests
 * [nsnumber isEqual:nil] - raise exception?
 */

