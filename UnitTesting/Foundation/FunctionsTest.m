//
//  Functions.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 23.02.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#ifdef __APPLE__	// & SDK before 10.5
#define sel_isEqual(A, B) ((A) == (B))
#endif

@interface FunctionsTest : SenTestCase {
	
}

@end

@implementation FunctionsTest

- (void) test10_NSRect
{
	NSRect rect=NSMakeRect(10, 20, 30, 42.2);
	STAssertEquals(rect.origin.x, (CGFloat) 10., nil);
	STAssertEquals(rect.origin.y, (CGFloat) 20., nil);
	STAssertEquals(rect.size.width, (CGFloat) 30., nil);
	STAssertEquals(rect.size.height, (CGFloat) 42.2, nil);
	STAssertEquals(NSZeroRect.origin.x, (CGFloat) 0., nil);
	STAssertEquals(NSZeroRect.origin.y, (CGFloat) 0., nil);
	STAssertEquals(NSZeroRect.size.width, (CGFloat) 0., nil);
	STAssertEquals(NSZeroRect.size.height, (CGFloat) 0., nil);
	STAssertEquals(NSMinX(rect), (CGFloat) 10., nil);
	STAssertEquals(NSMidX(rect), (CGFloat) 25., nil);
	STAssertEquals(NSMaxX(rect), (CGFloat) 40., nil);
	STAssertEquals(NSMinY(rect), (CGFloat) 20., nil);
	STAssertEquals(NSMidY(rect), (CGFloat) 41.1, nil);
	STAssertEquals(NSMaxY(rect), (CGFloat) 62.2, nil);
	STAssertEquals(NSWidth(rect), (CGFloat) 30., nil);
	STAssertEquals(NSHeight(rect), (CGFloat) 42.2, nil);
	STAssertTrue(NSIsEmptyRect(NSZeroRect), nil);
	STAssertFalse(NSIsEmptyRect(rect), nil);
	STAssertTrue(NSEqualRects(rect, rect), nil);
	STAssertFalse(NSEqualRects(rect, NSZeroRect), nil);
	STAssertEqualObjects(NSStringFromRect(rect), @"{{10, 20}, {30, 42.2}}", nil);
	STAssertTrue(NSEqualRects(NSRectFromString(@"{{10, 20}, {30, 42.2}}"), rect), nil);
	STAssertTrue(NSEqualRects(NSRectFromString(@" { { 1e1, 20.000}, { 0030, 42.200}  }  "), rect), nil);
	// check wrapping into NSValue
	// check intersection
	// check inset
	// check union (with empty and non-empty rect)
	// check containsRect
	// check NSDivideRect
	rect=NSMakeRect(10, 20, -30, 42.2);
	STAssertTrue(NSIsEmptyRect(rect), nil);	// negative width is empty
	rect=NSMakeRect(10, 20, -30, -42.2);
	STAssertTrue(NSIsEmptyRect(rect), nil);	// negative height is empty
	rect=NSMakeRect(10, 20, 0, -42.2);
	STAssertTrue(NSIsEmptyRect(rect), nil);	// zero with is empty
}

- (void) test20_NSPoint
{
	NSPoint point=NSMakePoint(10, 20.2);
	STAssertEquals(point.x, (CGFloat) 10., nil);
	STAssertEquals(point.y, (CGFloat) 20.2, nil);
	STAssertEquals(NSZeroPoint.x, (CGFloat) 0., nil);
	STAssertEquals(NSZeroPoint.y, (CGFloat) 0., nil);
	STAssertTrue(NSEqualPoints(point, point), nil);
	STAssertFalse(NSEqualPoints(point, NSZeroPoint), nil);
	STAssertEqualObjects(NSStringFromPoint(point), @"{10, 20.2}", nil);
	STAssertTrue(NSEqualPoints(NSPointFromString(@"{10, 20.2}"), point), nil);
	STAssertTrue(NSEqualPoints(NSPointFromString(@"  { 1e1, 20.200}  "), point), nil);
}

- (void) test30_NSSize
{
	NSSize size=NSMakeSize(10, 20.2);
	STAssertEquals(size.width, (CGFloat) 10., nil);
	STAssertEquals(size.height, (CGFloat) 20.2, nil);
	STAssertEquals(NSZeroSize.width, (CGFloat) 0., nil);
	STAssertEquals(NSZeroSize.height, (CGFloat) 0., nil);
	STAssertTrue(NSEqualSizes(size, size), nil);
	STAssertFalse(NSEqualSizes(size, NSZeroSize), nil);
	STAssertEqualObjects(NSStringFromSize(size), @"{10, 20.2}", nil);
	STAssertTrue(NSEqualSizes(NSSizeFromString(@"{10, 20.2}"), size), nil);
	STAssertTrue(NSEqualSizes(NSSizeFromString(@"  { 1e1, 20.200}  "), size), nil);
}

// same for NSSize, NSPoint, NSRange
// check point in rect (corner cases!), location in range 

- (void) test60_User_and_Home
{
	STAssertEqualObjects(NSUserName(), [NSString stringWithUTF8String:getenv("LOGNAME")], nil);
#ifdef __mySTEP__
	STAssertEqualObjects(NSHomeDirectory(), @"/Users/user", nil);
	STAssertEqualObjects(NSHomeDirectoryForUser(NSUserName()), @"/Users/user", nil);
#else
	STAssertEqualObjects(NSHomeDirectory(), [NSString stringWithUTF8String:getenv("HOME")], nil);
	STAssertEqualObjects(NSHomeDirectoryForUser(NSUserName()), [NSString stringWithUTF8String:getenv("HOME")], nil);
#endif
	STAssertNotNil(NSHomeDirectoryForUser(@"root"), nil);
	STAssertNil(NSHomeDirectoryForUser(@"*unknown-user*"), nil);
	STAssertEqualObjects(NSOpenStepRootDirectory(), @"/", nil);
	// STAssertEquals(NSTemporaryDirectory(), @"/", nil);
}

- (void) test70_SearchPathForDirectories
{
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO), ([NSArray arrayWithObjects:@"~/Documents", nil]), nil);
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES), ([NSArray arrayWithObjects:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], nil]), nil);
}

- (void) test80_encoding
{ // this is more like a compiler test...
	STAssertTrue(strcmp(@encode(char), @encode(signed char)) == 0, nil);
	STAssertFalse(strcmp(@encode(char), @encode(unsigned char)) == 0, nil);
	STAssertTrue(strcmp(@encode(int), @encode(signed int)) == 0, nil);
	STAssertFalse(strcmp(@encode(int), @encode(unsigned int)) == 0, nil);
}

- (void) test91_NSString_value
{ // nil object method calls
	id obj=@"0";
	STAssertEqualObjects([obj self], @"0", nil);
	STAssertEquals([obj boolValue], NO, nil);
	STAssertEquals([obj intValue], 0, nil);
	STAssertThrows([obj longValue], nil);	/* -[NSString longValue] does not exist */
	STAssertEquals([obj longLongValue], 0ll, nil);
	STAssertEquals([obj floatValue], 0.0f, nil);
	STAssertEquals([obj doubleValue], 0.0, nil);
	obj=@"3.14";
	STAssertEqualObjects([obj self], @"3.14", nil);
	STAssertEquals([obj boolValue], YES, nil);
	STAssertEquals([obj intValue], 3, nil);
	STAssertThrows([obj longValue], nil);	/* -[NSString longValue] does not exist */
	STAssertEquals([obj longLongValue], 3ll, nil);
	STAssertEquals([obj floatValue], 3.14f, nil);
	STAssertEquals([obj doubleValue], 3.14, nil);
}

- (void) test92_nil_value
{ // nil object method calls
	id obj=nil;
	STAssertEqualObjects([obj self], nil, nil);
	STAssertEquals([obj boolValue], NO, nil);
	STAssertEquals([obj intValue], 0, nil);
	STAssertEquals([obj longValue], 0l, nil);
	/* these are known to fail on all Debian */
	STAssertEquals([obj longLongValue], 0ll, @"known to fail");
	/* these are known to fail on Debian-i386 */
	STAssertEquals([obj floatValue], 0.0f, @"known to fail");
	STAssertEquals([obj doubleValue], 0.0, @"known to fail");
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
	STAssertTrue(sel_isEqual(s, @selector(test90)), nil);
	STAssertTrue(sel_isEqual(_cmd, @selector(test90)), nil);
	STAssertTrue(sel_isEqual(_cmd, s), nil);
	STAssertFalse(sel_isEqual(_cmd, @selector(test91)), nil);
	STAssertFalse(sel_isEqual(@selector(test90), @selector(test91)), nil);
//	STAssertTrue(sel_isEqual(@selector(test90), @selector(test91)), nil);
//	STAssertFalse(sel_isEqual(@selector(test91), @selector(test91)), nil);
	STAssertTrue(sel_isEqual(@selector(test91), @selector(test91)), nil);
	// check if we can create nil selectors, empty selectors (""), "unknown" selctors, UTF8 selectors etc.
	// Note: on Debian-i386, SEL are not simple C-Strings
}
// NSMakeRange - test for corner cases (0 start + 0 length, >0 start + 0 length, negative start + negative length, maxint start + >0 length etc.)

@end
