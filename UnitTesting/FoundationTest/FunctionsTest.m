//
//  Functions.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 23.02.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>

#ifdef __APPLE__	// & SDK before 10.5
#define sel_isEqual(A, B) ((A) == (B))
#endif

@interface FunctionsTest : XCTestCase {
	
}

@end

@implementation FunctionsTest

- (void) test10_NSRect
{
	NSRect rect=NSMakeRect(10, 20, 30, 42.2);
	XCTAssertEqual(rect.origin.x, (CGFloat) 10., @"rect.origin.x");
	XCTAssertEqual(rect.origin.y, (CGFloat) 20., @"rect.origin.y");
	XCTAssertEqual(rect.size.width, (CGFloat) 30., @"rect.size.width");
	XCTAssertEqual(rect.size.height, (CGFloat) 42.2, @"rect.size.height");
	XCTAssertEqual(NSZeroRect.origin.x, (CGFloat) 0., @"rect.origin.x");
	XCTAssertEqual(NSZeroRect.origin.y, (CGFloat) 0., @"rect.origin.y");
	XCTAssertEqual(NSZeroRect.size.width, (CGFloat) 0., @"rect.size.width");
	XCTAssertEqual(NSZeroRect.size.height, (CGFloat) 0., @"rect.size.height");
	XCTAssertEqual(NSMinX(rect), (CGFloat) 10., @"NSMinX");
	XCTAssertEqual(NSMidX(rect), (CGFloat) 25., @"NSMidX");
	XCTAssertEqual(NSMaxX(rect), (CGFloat) 40., @"NSMaxX");
	XCTAssertEqual(NSMinY(rect), (CGFloat) 20., @"NSMinY");
	XCTAssertEqual(NSMidY(rect), (CGFloat) 41.1, @"NSMidY");
	XCTAssertEqual(NSMaxY(rect), (CGFloat) 62.2, @"NSMaxY");
	XCTAssertEqual(NSWidth(rect), (CGFloat) 30., @"NSWidth");
	XCTAssertEqual(NSHeight(rect), (CGFloat) 42.2, @"NSHeight");
	XCTAssertTrue(NSIsEmptyRect(NSZeroRect), @"NSIsEmptyRect");
	XCTAssertFalse(NSIsEmptyRect(rect), @"NSIsEmptyRect");
	XCTAssertTrue(NSEqualRects(rect, rect), @"NSIsEmptyRect");
	XCTAssertFalse(NSEqualRects(rect, NSZeroRect), @"NSEqualRects");
	XCTAssertEqualObjects(NSStringFromRect(rect), @"{{10, 20}, {30, 42.2}}", @"NSStringFromRect");
	XCTAssertTrue(NSEqualRects(NSRectFromString(@"{{10, 20}, {30, 42.2}}"), rect), @"NSStringFromRect");
	XCTAssertTrue(NSEqualRects(NSRectFromString(@" { { 1e1, 20.000}, { 0030, 42.200}  }  "), rect), @"NSStringFromRect");
	// check wrapping into NSValue
	// check intersection
	// check inset
	// check union (with empty and non-empty rect)
	// check containsRect
	// check NSDivideRect
	rect=NSMakeRect(10, 20, -30, 42.2);
	XCTAssertTrue(NSIsEmptyRect(rect), @"NSIsEmptyRect");	// negative width is empty
	rect=NSMakeRect(10, 20, -30, -42.2);
	XCTAssertTrue(NSIsEmptyRect(rect), @"NSIsEmptyRect");	// negative height is empty
	rect=NSMakeRect(10, 20, 0, -42.2);
	XCTAssertTrue(NSIsEmptyRect(rect), @"NSIsEmptyRect");	// zero with is empty
}

- (void) test20_NSPoint
{
	NSPoint point=NSMakePoint(10, 20.2);
	XCTAssertEqual(point.x, (CGFloat) 10., @"point.x");
	XCTAssertEqual(point.y, (CGFloat) 20.2, @"point.y");
	XCTAssertEqual(NSZeroPoint.x, (CGFloat) 0., @"point.x");
	XCTAssertEqual(NSZeroPoint.y, (CGFloat) 0., @"point.y");
	XCTAssertTrue(NSEqualPoints(point, point), @"NSEqualPoints");
	XCTAssertFalse(NSEqualPoints(point, NSZeroPoint), @"NSEqualPoints");
	XCTAssertEqualObjects(NSStringFromPoint(point), @"{10, 20.2}", @"NSStringFromPoint");
	XCTAssertTrue(NSEqualPoints(NSPointFromString(@"{10, 20.2}"), point), @"NSEqualPoints");
	XCTAssertTrue(NSEqualPoints(NSPointFromString(@"  { 1e1, 20.200}  "), point), @"NSEqualPoints");
}

- (void) test30_NSSize
{
	NSSize size=NSMakeSize(10, 20.2);
	XCTAssertEqual(size.width, (CGFloat) 10., nil);
	XCTAssertEqual(size.height, (CGFloat) 20.2, nil);
	XCTAssertEqual(NSZeroSize.width, (CGFloat) 0., nil);
	XCTAssertEqual(NSZeroSize.height, (CGFloat) 0., nil);
	XCTAssertTrue(NSEqualSizes(size, size), nil);
	XCTAssertFalse(NSEqualSizes(size, NSZeroSize), nil);
	XCTAssertEqualObjects(NSStringFromSize(size), @"{10, 20.2}", nil);
	XCTAssertTrue(NSEqualSizes(NSSizeFromString(@"{10, 20.2}"), size), nil);
	XCTAssertTrue(NSEqualSizes(NSSizeFromString(@"  { 1e1, 20.200}  "), size), nil);
}

// same for NSSize, NSPoint, NSRange
// check point in rect (corner cases!), location in range 

- (void) test60_User_and_Home
{
	XCTAssertEqualObjects(NSUserName(), [NSString stringWithUTF8String:getenv("LOGNAME")], nil);
#ifdef __mySTEP__
	XCTAssertEqualObjects(NSHomeDirectory(), @"/Users/user", nil);
	XCTAssertEqualObjects(NSHomeDirectoryForUser(NSUserName()), @"/Users/user", nil);
#else
	XCTAssertEqualObjects(NSHomeDirectory(), [NSString stringWithUTF8String:getenv("HOME")], nil);
	XCTAssertEqualObjects(NSHomeDirectoryForUser(NSUserName()), [NSString stringWithUTF8String:getenv("HOME")], nil);
#endif
	XCTAssertNotNil(NSHomeDirectoryForUser(@"root"), nil);
	XCTAssertNil(NSHomeDirectoryForUser(@"*unknown-user*"), nil);
	XCTAssertEqualObjects(NSOpenStepRootDirectory(), @"/", nil);
	// XCTAssertEqual(NSTemporaryDirectory(), @"/", nil);
}

- (void) test70_SearchPathForDirectories
{
	XCTAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO), ([NSArray arrayWithObjects:@"~/Documents", nil]), nil);
	XCTAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES), ([NSArray arrayWithObjects:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], nil]), nil);
}

- (void) test80_encoding
{ // this is more like a compiler test...
	XCTAssertTrue(strcmp(@encode(char), @encode(signed char)) == 0, nil);
	XCTAssertFalse(strcmp(@encode(char), @encode(unsigned char)) == 0, nil);
	XCTAssertTrue(strcmp(@encode(int), @encode(signed int)) == 0, nil);
	XCTAssertFalse(strcmp(@encode(int), @encode(unsigned int)) == 0, nil);
}

- (void) test91_NSString_value
{ // nil object method calls
	id obj=@"0";
	XCTAssertEqualObjects([obj self], @"0", nil);
	XCTAssertEqual([obj boolValue], NO, nil);
	XCTAssertEqual([obj intValue], 0, nil);
	XCTAssertThrows([obj longValue], nil);	/* -[NSString longValue] does not exist */
	XCTAssertEqual([obj longLongValue], 0ll, nil);
	XCTAssertEqual([obj floatValue], 0.0f, nil);
	XCTAssertEqual([obj doubleValue], 0.0, nil);
	obj=@"3.14";
	XCTAssertEqualObjects([obj self], @"3.14", nil);
	XCTAssertEqual([obj boolValue], YES, nil);
	XCTAssertEqual([obj intValue], 3, nil);
	XCTAssertThrows([obj longValue], nil);	/* -[NSString longValue] does not exist */
	XCTAssertEqual([obj longLongValue], 3ll, nil);
	XCTAssertEqual([obj floatValue], 3.14f, nil);
	XCTAssertEqual([obj doubleValue], 3.14, nil);
}

- (void) test92_nil_value
{ // nil object method calls
	id obj=nil;
	XCTAssertEqualObjects([obj self], nil, nil);
	XCTAssertEqual([obj boolValue], NO, nil);
	XCTAssertEqual([obj intValue], 0, nil);
	XCTAssertEqual([obj longValue], 0l, nil);
	/* these are known to fail on all Debian */
	XCTAssertEqual([obj longLongValue], 0ll, @"known to fail");
	/* these are known to fail on Debian-i386 */
	XCTAssertEqual([obj floatValue], 0.0f, @"known to fail");
	XCTAssertEqual([obj doubleValue], 0.0, @"known to fail");
}

- (void) test90_selectors
{ // selectors and equality
	SEL s=NSSelectorFromString(@"test90");
#if 1 // this was from debugging Debian-i386
	NSLog(@"%@ -- %@", NSStringFromSelector(s), NSStringFromSelector(@selector(test90)));
	NSLog(@"1: %@", sel_isEqual(s, @selector(test90))?@"YES":@"NO");
	NSLog(@"2: %@", sel_isEqual(s, @selector(test91))?@"YES":@"NO");
	NSLog(@"3: %@", sel_isEqual(@selector(test90), @selector(test91))?@"YES":@"NO");
	NSLog(@"4: %@", !sel_isEqual(@selector(test90), @selector(test91))?@"YES":@"NO");
	NSLog(@"1: %d", sel_isEqual(s, @selector(test90)));
	NSLog(@"2: %d", sel_isEqual(s, @selector(test91)));
	NSLog(@"3: %d", sel_isEqual(@selector(test90), @selector(test91)));
	NSLog(@"4: %d", !sel_isEqual(@selector(test90), @selector(test91)));
#endif
	XCTAssertTrue(sel_isEqual(s, @selector(test90)), nil);
	XCTAssertTrue(sel_isEqual(_cmd, @selector(test90)), nil);
	XCTAssertTrue(sel_isEqual(_cmd, s), nil);
	XCTAssertFalse(sel_isEqual(_cmd, @selector(test91)), nil);
	XCTAssertFalse(sel_isEqual(@selector(test90), @selector(test91)), nil);
//	XCTAssertTrue(sel_isEqual(@selector(test90), @selector(test91)), nil);
//	XCTAssertFalse(sel_isEqual(@selector(test91), @selector(test91)), nil);
	XCTAssertTrue(sel_isEqual(@selector(test91), @selector(test91)), nil);
	// check if we can create nil selectors, empty selectors (""), "unknown" selctors, UTF8 selectors etc.
	// Note: on Debian-i386, SEL are not simple C-Strings
}
// NSMakeRange - test for corner cases (0 start + 0 length, >0 start + 0 length, negative start + negative length, maxint start + >0 length etc.)

@end
