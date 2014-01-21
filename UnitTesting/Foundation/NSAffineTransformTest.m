//
//  NSAffineTransformTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 07.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface NSAffineTransformTest : SenTestCase {
	NSAffineTransform *t;
}

@end

// FIXME: apply withAccuracy to comparing NSPoints and NSSize!

#define STAssertEqualPointsWithAccuracy(p1, p2, acc, msg) STAssertEqualsWithAccuracy(p1.x, p2.x, acc, msg); STAssertEqualsWithAccuracy(p1.y, p2.y, acc, msg);
#define STAssertEqualSizesWithAccuracy(s1, s2, acc, msg) STAssertEqualsWithAccuracy(s1.width, s2.width, acc, msg); STAssertEqualsWithAccuracy(s1.height, s2.height, acc, msg);

@implementation NSAffineTransformTest

- (void) setUp
{
	t=[[NSAffineTransform alloc] init];	// create unit matrix
	STAssertNotNil(t, nil);
}

- (void) tearDown
{
	[t release];
}

- (void) test01
{
	NSAffineTransformStruct ts;
	ts=[t transformStruct];
	STAssertEquals(ts.m11, 1.0f, nil);
	STAssertEquals(ts.m12, 0.0f, nil);
	STAssertEquals(ts.m21, 0.0f, nil);
	STAssertEquals(ts.m22, 1.0f, nil);
	STAssertEquals(ts.tX, 0.0f, nil);
	STAssertEquals(ts.tY, 0.0f, nil);
}

- (void) test02
{
	NSAffineTransformStruct ts;
	[t translateXBy:5.0 yBy:7.0];
	ts=[t transformStruct];
	STAssertEquals(ts.m11, 1.0f, nil);
	STAssertEquals(ts.m12, 0.0f, nil);
	STAssertEquals(ts.m21, 0.0f, nil);
	STAssertEquals(ts.m22, 1.0f, nil);
	STAssertEquals(ts.tX, 5.0f, nil);
	STAssertEquals(ts.tY, 7.0f, nil);
}

- (void) test03
{
	NSAffineTransformStruct ts;
	[t rotateByDegrees:30.0];
	ts=[t transformStruct];
	STAssertEqualsWithAccuracy(ts.m11, 0.8660254f, 2e-6, nil);
	STAssertEquals(ts.m12, 0.5f, nil);
	STAssertEquals(ts.m21, -0.5f, nil);
	STAssertEqualsWithAccuracy(ts.m22, 0.8660254f, 2e-6, nil);
	STAssertEquals(ts.tX, 0.0f, nil);
	STAssertEquals(ts.tY, 0.0f, nil);
}

- (void) test04
{
	NSAffineTransformStruct ts;
	[t translateXBy:5.0 yBy:7.0];
	[t rotateByDegrees:30.0];
	ts=[t transformStruct];
	STAssertEqualsWithAccuracy(ts.m11, 0.8660254f, 2e-6, nil);
	STAssertEquals(ts.m12, 0.5f, nil);
	STAssertEquals(ts.m21, -0.5f, nil);
	STAssertEqualsWithAccuracy(ts.m22, 0.8660254f, 2e-6, nil);
	STAssertEquals(ts.tX, 5.0f, nil);
	STAssertEquals(ts.tY, 7.0f, nil);
}

- (void) test05
{
	NSAffineTransformStruct ts;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	ts=[t transformStruct];
	STAssertEqualsWithAccuracy(ts.m11, 0.8660254f, 2e-6, nil);
	STAssertEquals(ts.m12, 0.5f, nil);
	STAssertEquals(ts.m21, -0.5f, nil);
	STAssertEqualsWithAccuracy(ts.m22, 0.8660254f, 2e-6, nil);
	STAssertEqualsWithAccuracy(ts.tX, 0.830127f, 2e-6, nil);
	STAssertEqualsWithAccuracy(ts.tY, 8.562178f, 2e-6, nil);
}

- (void) test10
{
	NSPoint pt;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	pt=[t transformPoint:NSMakePoint(10.0, 15.0)];
	STAssertEqualPointsWithAccuracy(pt, NSMakePoint(1.99038, 26.552559), 2e-6, nil);
}

- (void) test11
{
	NSSize sz;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(4.820507, 31.650635), 2e-6, nil);
}

- (void) test12
{
	NSPoint pt;
	[t rotateByDegrees:30.0+180.0];
	[t translateXBy:5.0 yBy:7.0];
	pt=[t transformPoint:NSMakePoint(10.0, 15.0)];
	STAssertEqualPointsWithAccuracy(pt, NSMakePoint(-1.99038, -26.552559), 2e-6, nil);
}

- (void) test13
{
	NSSize sz;
	[t rotateByDegrees:30.0+180];
	[t translateXBy:5.0 yBy:7.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820508, -31.650635), 2e-6, nil);
}

- (void) test20
{
	NSSize sz;
	[t scaleXBy:2.0 yBy:-3.0];
	sz=[t transformSize:NSMakeSize(20.0, 25.0)];
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(40.0, -75.0), 2e-6, nil);
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
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, nil);
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
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, nil);
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
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, nil);
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
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, nil);
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
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, nil);
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
	STAssertEqualSizesWithAccuracy(sz, NSMakeSize(-4.820505, -31.650635), 2e-6, nil);
}

- (void) test40
{
	NSPoint pt;
	[t rotateByDegrees:30.0];
	[t translateXBy:5.0 yBy:7.0];
	[t invert];
	pt=[t transformPoint:NSMakePoint(1.99038, 26.5526)];
	STAssertEqualPointsWithAccuracy(pt, NSMakePoint(10.000021, 15.000036), 2e-6, nil);
}

- (void) test41
{
	NSAffineTransformStruct ts;
	[t scaleBy:0.0];
	ts=[t transformStruct];
	STAssertEquals(ts.m11, 0.0f, nil);
	STAssertEquals(ts.m12, 0.0f, nil);
	STAssertEquals(ts.m21, 0.0f, nil);
	STAssertEquals(ts.m22, 0.0f, nil);
	STAssertEquals(ts.tX, 0.0f, nil);
	STAssertEquals(ts.tY, 0.0f, nil);
	STAssertThrowsSpecific([t invert], NSException, nil);
}

@end
