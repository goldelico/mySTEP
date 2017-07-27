//
//  NSAffineTransformTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 07.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSAffineTransformTest : XCTestCase {
	NSAffineTransform *t;
}

@end

// FIXME: apply withAccuracy to comparing NSPoints and NSSize!

#define XCTAssertEqualPointsWithAccuracy(p1, p2, acc, msg) XCTAssertEqualWithAccuracy(p1.x, p2.x, acc, msg); XCTAssertEqualWithAccuracy(p1.y, p2.y, acc, msg);
#define XCTAssertEqualizesWithAccuracy(s1, s2, acc, msg) XCTAssertEqualWithAccuracy(s1.width, s2.width, acc, msg); XCTAssertEqualWithAccuracy(s1.height, s2.height, acc, msg);

@implementation NSAffineTransformTest

- (void) setUp
{
	t=[[NSAffineTransform alloc] init];	// create unit matrix
	XCTAssertNotNil(t, @"");
}

- (void) tearDown
{
	[t release];
}

- (void) test01
{
	NSAffineTransformStruct ts;
	ts=[t transformStruct];
	XCTAssertEqual(ts.m11, (CGFloat) 1.0, @"");
	XCTAssertEqual(ts.m12, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m21, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m22, (CGFloat) 1.0, @"");
	XCTAssertEqual(ts.tX, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.tY, (CGFloat) 0.0, @"");
}

- (void) test02
{
	NSAffineTransformStruct ts;
	[t translateXBy:5.0 yBy:7.0];
	ts=[t transformStruct];
	XCTAssertEqual(ts.m11, (CGFloat) 1.0, @"");
	XCTAssertEqual(ts.m12, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m21, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m22, (CGFloat) 1.0, @"");
	XCTAssertEqual(ts.tX, (CGFloat) 5.0, @"");
	XCTAssertEqual(ts.tY, (CGFloat) 7.0, @"");
}

- (void) test03
{
	NSAffineTransformStruct ts;
	[t rotateByDegrees:30.0];
	ts=[t transformStruct];
	XCTAssertEqualWithAccuracy(ts.m11, (CGFloat) 0.8660254, 2e-6, @"");
	XCTAssertEqual(ts.m12, (CGFloat) 0.5, @"");
	XCTAssertEqual(ts.m21, (CGFloat) -0.5, @"");
	XCTAssertEqualWithAccuracy(ts.m22, (CGFloat) 0.8660254, 2e-6, @"");
	XCTAssertEqual(ts.tX, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.tY, (CGFloat) 0.0, @"");
}

- (void) test04
{
	NSAffineTransformStruct ts;
	[t translateXBy:5.0 yBy:7.0];
	[t rotateByDegrees:30.0];
	ts=[t transformStruct];
	XCTAssertEqualWithAccuracy(ts.m11, (CGFloat) 0.8660254, 2e-6, @"");
	XCTAssertEqual(ts.m12, (CGFloat) 0.5, @"");
	XCTAssertEqual(ts.m21, (CGFloat) -0.5, @"");
	XCTAssertEqualWithAccuracy(ts.m22, (CGFloat) 0.8660254, 2e-6, @"");
	XCTAssertEqual(ts.tX, (CGFloat) 5.0, @"");
	XCTAssertEqual(ts.tY, (CGFloat) 7.0, @"");
}

- (void) test05
{
	NSAffineTransformStruct ts;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	ts=[t transformStruct];
	XCTAssertEqualWithAccuracy(ts.m11, (CGFloat) 0.8660254, 2e-6, @"");
	XCTAssertEqual(ts.m12, (CGFloat) 0.5, @"");
	XCTAssertEqual(ts.m21, (CGFloat) -0.5, @"");
	XCTAssertEqualWithAccuracy(ts.m22, (CGFloat) 0.8660254, 2e-6, @"");
	XCTAssertEqualWithAccuracy(ts.tX, (CGFloat) 0.830127, 2e-6, @"");
	XCTAssertEqualWithAccuracy(ts.tY, (CGFloat) 8.562178, 2e-6, @"");
}

- (void) test10
{
	NSPoint pt;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	pt=[t transformPoint:NSMakePoint(10.0, 15.0)];
	XCTAssertEqualPointsWithAccuracy(pt, NSMakePoint(1.99038, 26.552559), 2e-6, @"");
}

- (void) test11
{
	NSSize sz;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(4.820507, 31.650635), 2e-6, @"");
}

- (void) test12
{
	NSPoint pt;
	[t rotateByDegrees:30.0+180.0];
	[t translateXBy:5.0 yBy:7.0];
	pt=[t transformPoint:NSMakePoint(10.0, 15.0)];
	XCTAssertEqualPointsWithAccuracy(pt, NSMakePoint(-1.99038, -26.552559), 2e-6, @"");
}

- (void) test13
{
	NSSize sz;
	[t rotateByDegrees:30.0+180];
	[t translateXBy:5.0 yBy:7.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820508, -31.650635), 2e-6, @"");
}

- (void) test20
{
	NSSize sz;
	[t scaleXBy:2.0 yBy:-3.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(40.0, -75.0), 2e-6, @"");
}

- (void) test30
{
	NSSize sz;
	NSAffineTransform *t2=[[NSAffineTransform new] autorelease];
	[t2 rotateByDegrees:30.0];
	[t rotateByDegrees:180.0];
	[t appendTransform:t2];
	[t translateXBy:5.0 yBy:7.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, @"");
}

- (void) test31
{
	NSSize sz;
	NSAffineTransform *t2=[[NSAffineTransform new] autorelease];
	[t2 rotateByDegrees:30.0];
	[t rotateByDegrees:180.0];
	[t translateXBy:5.0 yBy:7.0];
	[t appendTransform:t2];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, @"");
}

- (void) test32
{
	NSSize sz;
	NSAffineTransform *t2=[[NSAffineTransform new] autorelease];
	[t2 rotateByDegrees:30.0];
	[t rotateByDegrees:180.0];
	[t prependTransform:t2];
	[t translateXBy:5.0 yBy:7.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, @"");
}

- (void) test33
{
	NSSize sz;
	NSAffineTransform *t2=[[NSAffineTransform new] autorelease];
	[t2 rotateByDegrees:30.0];
	[t rotateByDegrees:180.0];
	[t translateXBy:5.0 yBy:7.0];
	[t prependTransform:t2];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, @"");
}

- (void) test34
{
	NSSize sz;
	NSAffineTransform *t2=[[NSAffineTransform new] autorelease];
	[t2 rotateByDegrees:30.0];
	[t2 translateXBy:5.0 yBy:7.0];
	[t rotateByDegrees:180.0];
	[t prependTransform:t2];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, @"");
}

- (void) test35
{
	NSSize sz;
	NSAffineTransform *t2=[[NSAffineTransform new] autorelease];
	[t2 rotateByDegrees:30.0];
	[t2 translateXBy:5.0 yBy:7.0];
	[t rotateByDegrees:180.0];
	[t appendTransform:t2];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	XCTAssertEqualizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, @"");
}

- (void) test40
{
	NSPoint pt;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	[t invert];
	pt=[t transformPoint:NSMakePoint(1.99038, 26.5526)];
	XCTAssertEqualPointsWithAccuracy(pt, NSMakePoint(10.000021, 15.000036), 2e-6, @"");
}

- (void) test41
{
	NSAffineTransformStruct ts;
	[t scaleBy:0.0];
	ts=[t transformStruct];
	XCTAssertEqual(ts.m11, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m12, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m21, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.m22, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.tX, (CGFloat) 0.0, @"");
	XCTAssertEqual(ts.tY, (CGFloat) 0.0, @"");
	XCTAssertThrowsSpecific([t invert], NSException, @"");
}

@end
