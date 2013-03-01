//
//  NSValueTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 01.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSValueTest.h"


@implementation NSValueTest

- (void) test99
{
	id obj=[NSObject new];	// create object
	unsigned retainCount=[obj retainCount];
	NSValue *val=[NSValue valueWithNonretainedObject:obj];
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
	val=[NSValue valueWithBytes:obj objCType:@encode(id)];
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
	val=[NSValue valueWithBytes:obj objCType:@encode(void *)];
	STAssertEquals([obj retainCount], retainCount, nil);	// is NOT retained
}

@end
