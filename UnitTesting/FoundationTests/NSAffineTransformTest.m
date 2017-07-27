//
//  NSMutableArrayTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.07.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSMutableArrayTest : XCTestCase {
	NSMutableArray *t;
}

@end

@implementation NSMutableArrayTest

- (void) setUp
{
	t=[[NSMutableArray alloc] init];
	XCTAssertNotNil(t, @"");
}

- (void) tearDown
{
	[t release];
}

- (void) test01
{
	XCTAssertEqual([t count], 0, @"");
}

- (void) test02
{
	// try remove/insert by NSIndexSet
	// like at https://developer.apple.com/documentation/foundation/nsmutablearray/1410154-removeobjectsatindexes
	// and https://developer.apple.com/documentation/foundation/nsmutablearray/1416482-insertobjects
	// see examples there
	// check if nil indexSet ends in an NSException
}

@end
