//
//  Functions.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 23.02.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Functions.h"


@implementation Functions

- (void) test1
{
	NSRect rect=NSMakeRect(10, 20, 30, 42);
	STAssertEquals(rect.origin.x, 10.f, nil);
	STAssertEquals(rect.origin.y, 20.f, nil);
	STAssertEquals(rect.size.width, 30.f, nil);
	STAssertEquals(rect.size.height, 42.f, nil);
	STAssertEquals(NSMinX(rect), 10.f, nil);
	STAssertEquals(NSMidX(rect), 25.f, nil);
	STAssertEquals(NSMaxX(rect), 40.f, nil);
	STAssertEquals(NSMinY(rect), 20.f, nil);
	STAssertEquals(NSMidY(rect), 41.f, nil);
	STAssertEquals(NSMaxY(rect), 62.f, nil);
	STAssertEquals(NSWidth(rect), 30.f, nil);
	STAssertEquals(NSHeight(rect), 42.f, nil);
	// check isEqualRect
	// check empty rect
	// check intersection
	// check inset
	// check containsRect
	// check NSDivideRect
}

// same for NSSize, NSPoint, NSRange

- (void) test11
{
	// 	STAssertEquals(NSUserName(), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSHomeDirectory(), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSHomeDirectoryForUser(NSUserName()), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSOpenStepRootDirectory(), @"/", nil);
	// STAssertEquals(NSTemporaryDirectory(), @"/", nil);
}

- (void) test12
{
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO), ([NSArray arrayWithObjects:@"~/Documents", nil]), nil);
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES), ([NSArray arrayWithObjects:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], nil]), nil);
}

@end
