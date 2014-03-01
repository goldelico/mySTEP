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
	STAssertTrue(NSEqualRects(rect, rect), nil);
	STAssertFalse(NSEqualRects(rect, NSZeroRect), nil);
	STAssertEqualObjects(NSStringFromRect(rect), @"{{10, 20}, {30, 42.2}}", nil);
	STAssertTrue(NSEqualRects(NSRectFromString(@"{{10, 20}, {30, 42.2}}"), rect), nil);
	STAssertTrue(NSEqualRects(NSRectFromString(@" { { 1e1, 20.000}, { 0030, 42.200}  }  "), rect), nil);
	// check wraping into NSValue
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
	STAssertTrue(NSIsEmptyRect(rect), nil);	// zero with is nempty
}

- (void) test20
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

- (void) test30
{
	NSSize size=NSMakeSize(10, 20.2);
	STAssertEquals(size.width, 10.f, nil);
	STAssertEquals(size.height, 20.2f, nil);
	STAssertEquals(NSZeroSize.width, 0.f, nil);
	STAssertEquals(NSZeroSize.height, 0.f, nil);
	STAssertTrue(NSEqualSizes(size, size), nil);
	STAssertFalse(NSEqualSizes(size, NSZeroSize), nil);
	STAssertEqualObjects(NSStringFromSize(size), @"{10, 20.2}", nil);
	STAssertTrue(NSEqualSizes(NSSizeFromString(@"{10, 20.2}"), size), nil);
	STAssertTrue(NSEqualSizes(NSSizeFromString(@"  { 1e1, 20.200}  "), size), nil);
}

// same for NSSize, NSPoint, NSRange
// check point in rect (corner cases!), location in range 

- (void) test60
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

- (void) test70
{
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO), ([NSArray arrayWithObjects:@"~/Documents", nil]), nil);
	STAssertEqualObjects(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES), ([NSArray arrayWithObjects:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], nil]), nil);
}

- (void) test80
{ // this is more like a compiler test...
	STAssertTrue(strcmp(@encode(char), @encode(signed char)) == 0, nil);
	STAssertFalse(strcmp(@encode(char), @encode(unsigned char)) == 0, nil);
	STAssertTrue(strcmp(@encode(int), @encode(signed int)) == 0, nil);
	STAssertFalse(strcmp(@encode(int), @encode(unsigned int)) == 0, nil);
}

- (void) test91
{ // nil object method calls
	id obj=nil;
	STAssertEqualObjects([obj self], nil, nil);
	STAssertEquals([obj boolValue], NO, nil);
	STAssertEquals([obj intValue], 0, nil);
	STAssertEquals([obj longValue], 0l, nil);
	/* these are known to fail on all Debian */
	STAssertEquals([obj longLongValue], 0ll, @"unreliable");
	/* these are known to fail on Debian-i386 */
	STAssertEquals([obj floatValue], 0.0f, @"i386 unreliable");
	STAssertEquals([obj doubleValue], 0.0, @"i386 unreliable");
}

- (void) test90
{ // selectors and equality
	SEL s=NSSelectorFromString(@"test90");
#if 0 // this was from debugging Debian-i386
	NSLog(@"%s -- %s", s, @selector(test90));
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
