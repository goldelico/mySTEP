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
	STAssertEquals([view frameRotation], 0.0f, nil);
	STAssertEquals([view boundsRotation], 0.0f, nil);
	STAssertEquals([view frame], NSMakeRect(0, 0, 500.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0, 0, 500.0, 500.0), nil);
}

- (void) test10
{ // bounds rotation accumulates and can go beyond 360 degrees
	[view setBoundsRotation:30.0];
	STAssertEquals([view boundsRotation], 30.0f, nil);
	[view rotateByAngle:60.0];
	STAssertEquals([view boundsRotation], 30.0f+60.0f, nil);
	[view rotateByAngle:180.0];
	STAssertEquals([view boundsRotation], 90.0f+180.0f, nil);
	[view rotateByAngle:180.0];
	STAssertEquals([view boundsRotation], 270.0f+180.0f, nil);
	[view rotateByAngle:-450.0];
	STAssertEquals([view boundsRotation], 0.0f, nil);
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
