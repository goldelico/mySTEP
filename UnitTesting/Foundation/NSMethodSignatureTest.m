//
//  NSMethodSignatureTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 16.01.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface NSMethodSignatureTest : SenTestCase {
	
}

@end


@implementation NSMethodSignatureTest

// init with NULL signature
// NSObject methodSignatureForSelector - one that exists @selector(retain)
// NSObject one that exists in a different (sub) class @selector(count)
// one that does not exist in the system @selector(_selector_that_does_not_exist_)
// check frame length, numberOfArguments, returnType, isOneway etc.


@end
