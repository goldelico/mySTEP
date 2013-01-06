//
//  NSViewBoundsTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSViewBoundsTest.h"


@implementation NSViewBoundsTest

- (void) setUp;
{
	view=[[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 500.0)];	
}

- (void) tearDown;
{
	[view release];
}

- (void) test01
{ // allocation did work
	STAssertNotNil(view, nil);
}

- (void) test02
{ // default rotation
	STAssertTrue([view frameRotation] == 0.0, nil);
	STAssertTrue([view boundsRotation] == 0.0, nil);
	has=[view frame];
	want=NSMakeRect(0, 0, 500.0, 500.0);
	STAssertTrue(NSEqualRects(has, want), nil);
	has=[view bounds];
	want=NSMakeRect(0, 0, 500.0, 500.0);
	STAssertTrue(NSEqualRects(has, want), nil);
}

- (void) test10
{ // bounds rotation accumulates and can go beyond 360 degrees
	[view setBoundsRotation:30.0];
	STAssertTrue([view boundsRotation] == 30.0, nil);
	[view rotateByAngle:60.0];
	STAssertTrue([view boundsRotation] == 30.0+60.0, nil);
	[view rotateByAngle:180.0];
	STAssertTrue([view boundsRotation] == 90.0+180.0, nil);
	[view rotateByAngle:180.0];
	STAssertTrue([view boundsRotation] == 270.0+180.0, nil);
	[view rotateByAngle:-450.0];
	STAssertTrue([view boundsRotation] == 0.0, nil);
	/* conclusions
	 * there must be a separate instance variable
	 * it is impossible to calculate the bounds rotation through atan2() from the rotation matrix
	 * because a rotation matrix is repeating modulus 2*pi
	 */
}

// do rotation tests
// and pinpoint some special observations
// mix setBoundsSize, setBoundsOrigin, setBounds while bounds are rotated
// influence of flipping?

@end
