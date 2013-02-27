//
//  Functions.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 23.02.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Functions.h"


@implementation Functions

- (void) test10
{
	NSRect rect=NSMakeRect(10, 20, 30, 42.2);
	STAssertEquals(rect.origin.x, 10.f, nil);
	STAssertEquals(rect.origin.y, 20.f, nil);
	STAssertEquals(rect.size.width, 30.f, nil);
	STAssertEquals(rect.size.height, 42.2f, nil);
	STAssertEquals(NSZeroRect.origin.x, 0.f, nil);
	STAssertEquals(NSZeroRect.origin.y, 0.f, nil);
	STAssertEquals(NSZeroRect.size.width, 0.f, nil);
	STAssertEquals(NSZeroRect.size.height, 0.f, nil);
	STAssertEquals(NSMinX(rect), 10.f, nil);
	STAssertEquals(NSMidX(rect), 25.f, nil);
	STAssertEquals(NSMaxX(rect), 40.f, nil);
	STAssertEquals(NSMinY(rect), 20.f, nil);
	STAssertEquals(NSMidY(rect), 41.1f, nil);
	STAssertEquals(NSMaxY(rect), 62.2f, nil);
	STAssertEquals(NSWidth(rect), 30.f, nil);
	STAssertEquals(NSHeight(rect), 42.2f, nil);
	STAssertTrue(NSIsEmptyRect(NSZeroRect), nil);
	STAssertFalse(NSIsEmptyRect(rect), nil);
	// negative width/height?
	STAssertTrue(NSEqualRects(rect, rect), nil);
	STAssertFalse(NSEqualRects(rect, NSZeroRect), nil);
	// check intersection
	// check inset
	// check union (with empty and non-empty rect)
	// check containsRect
	// check NSDivideRect
	STAssertEqualObjects(NSStringFromRect(rect), @"{{10, 20}, {30, 42.2}}", nil);
	STAssertTrue(NSEqualRects(NSRectFromString(@"{{10, 20}, {30, 42.2}}"), rect), nil);
	STAssertTrue(NSEqualRects(NSRectFromString(@" { { 1e1, 20.000}, { 0030, 42.200}  }  "), rect), nil);
	// check warpping into NSValue
}

- (void) test11
{
	NSPoint point=NSMakePoint(10, 20.2);
	STAssertEquals(point.x, 10.f, nil);
	STAssertEquals(point.y, 20.2f, nil);
	STAssertEquals(NSZeroPoint.x, 0.f, nil);
	STAssertEquals(NSZeroPoint.y, 0.f, nil);
	STAssertTrue(NSEqualPoints(point, point), nil);
	STAssertFalse(NSEqualPoints(point, NSZeroPoint), nil);
	STAssertEqualObjects(NSStringFromPoint(point), @"{10, 20.2}", nil);
	STAssertTrue(NSEqualPoints(NSPointFromString(@"{10, 20.2}"), point), nil);
	STAssertTrue(NSEqualPoints(NSPointFromString(@"  { 1e1, 20.200}  "), point), nil);
}

// same for NSSize, NSPoint, NSRange
// check point in rect (corner cases!), location in range 

- (void) test20
{
	// 	STAssertEquals(NSUserName(), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSHomeDirectory(), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSHomeDirectoryForUser(NSUserName()), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSOpenStepRootDirectory(), @"/", nil);
	// STAssertEquals(NSTemporaryDirectory(), @"/", nil);
}

- (void) test30
{
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO), ([NSArray arrayWithObjects:@"~/Documents", nil]), nil);
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES), ([NSArray arrayWithObjects:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], nil]), nil);
}

@end
