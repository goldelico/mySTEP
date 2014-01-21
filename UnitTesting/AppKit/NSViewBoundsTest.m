//
//  NSViewBoundsTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Cocoa/Cocoa.h>


@interface NSViewBoundsTest : SenTestCase {
	NSView *view;
}

@end

#define MOCKUP

#ifdef MOCKUP
@interface View : NSView

@end

@implementation View

- (id) initWithFrame:(NSRect)frameRect
{
	return [super initWithFrame:frameRect];
}
// here we can implement our own view rotation algorithms and have them tested

@end

#endif

@implementation NSViewBoundsTest

- (void) setUp;
{
#ifdef MOCKUP
	view=[[View alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 500.0)];
#else
	view=[[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 500.0)];
#endif	
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

- (void) test05
{ // setting negative frame size is possible
	[view setFrameSize:NSMakeSize(-200.0, -300.0)];
	STAssertEquals([view frame], NSMakeRect(0.0, 0.0, -200.0, -300.0), nil);
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

- (void) test20
{
	[view setBoundsRotation:0.0];
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);
	// rotate bounds
	[view setBoundsRotation:45.0];
	// they grow larger
	STAssertEquals([view bounds], NSMakeRect(0.0, -sqrt(0.5)*100.0,sqrt(2)*100.0, sqrt(2)*100.0), nil);	// enlarges to sqrt(2)*100.0
	// and shrink back
	[view setBoundsRotation:90.0];
	STAssertEquals([view bounds], NSMakeRect(0.0, -100.0, 100.0, 100.0), nil);	// dimensions go back to 100, 100
	// and the original value is known
	[view setBoundsRotation:0.0];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);	// back to original setting
	/* conclusion: most likely the bounds are stored internally, and the enclosing rect after applying rotation is returned */
}

- (void) test21
{
	[view setBoundsRotation:0.0];
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);
	// now try to change the underlying bounds while rotated
	[view setBoundsRotation:45.0];	
	STAssertEquals([view bounds], NSMakeRect(0.0, -sqrt(0.5)*100.0,sqrt(2)*100.0, sqrt(2)*100.0), nil);	// same as before
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, -sqrt(0.5)*100.0,sqrt(2)*100.0, sqrt(2)*100.0), nil);	// same as before
	/* conclusion: this appears to prove the assumption of internally stored bounds */

	// now scale everything down
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];
	STAssertEquals([view bounds], NSMakeRect(0.0, -sqrt(0.5)*100.0/0.5, sqrt(2)*100.0/0.5, sqrt(2)*100.0/0.5), nil);
	// and rotate back
	[view setBoundsRotation:0.0];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0/0.5, 100.0/0.5), nil);
	/* so far everything is linear */
}

- (void) test22
{
	[view setBoundsRotation:0.0];
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);
	// scale down
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0/0.5, 100.0/0.5), nil);

	// and again
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0/0.25, 100.0/0.25), nil);

	// and again
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0/0.125, 100.0/0.125), nil);
	
	// now set bounds
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);
	/* scaling is "wiped out" by setting new bounds */
	
	// rotate not by 45 degrees
	[view setBoundsRotation:30.0];
	STAssertEquals([view bounds], NSMakeRect(0.0, -0.5*100.0, 136.603, 136.603), nil);

	// and scale in a non-uniform way
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.75)];
	STAssertEquals([view bounds], NSMakeRect(0.0, -0.5*100.0/0.75, 136.603/0.5, 136.603/0.75), nil);

	// and set new bounds
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, -0.5*100.0, 136.603, 136.603), nil);
	/* again scaling is wiped out */
	
	/* so far it looks as if scaleUnitSquareToSize directly manipulates the internal bounds
	 * while setBoundsRotation is applied in a special way so that [self bounds] returns the
	 * enclosing rect of the rotated internal bounds
	 */
}

- (void) test23
{
	[view setBoundsRotation:0.0];
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);
	// let's try translations
	[view translateOriginToPoint:NSMakePoint(50.0, 0.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, -0.5*100.0, 136.603, 136.603), nil);
	[view setBoundsRotation:45.0];
	STAssertEquals([view bounds], NSMakeRect(-35.3553, -35.3553, sqrt(2)*100.0, sqrt(2)*100.0), nil);
	/* conclusion: origin is also rotated */
	
	STAssertEquals([view boundsRotation], 45.0f, nil);
	[view translateOriginToPoint:NSMakePoint(-50.0, 0.0)];
	STAssertEquals([view bounds], NSMakeRect(14.6447, -35.3553, sqrt(2)*100.0, sqrt(2)*100.0), nil);
	STAssertEquals([view boundsRotation], 45.0f, nil);
	/* boundsRotation is not derived from the rotation matrix */

	// now rotate back
	[view setBoundsRotation:0.0];
	STAssertEquals([view bounds], NSMakeRect(-14.6447, 35.3553, 100.0, 100.0), nil);
	STAssertEquals([view boundsRotation], 0.0f, nil);
	/* conclusion: translation and rotation are not commutative
	 * which means they are not stored/accumulated as separate iVars and applied when
	 * asking for the current bounds
	 * it appears as if only boundsRotation is accumulated in an iVar and a rotation
	 * matrix is updated in parallel
	 */
}

- (void) test24
{
	[view setBoundsRotation:0.0];
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 100.0, 100.0), nil);
}

#if 0	// convert to SenTest

	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];	// this resets the bounds scaling
	NSLog(@"50: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:45.0];
	NSLog(@"51: %@", NSStringFromRect([view bounds]));
	[view translateOriginToPoint:NSMakePoint(50.0, 0.0)];
	NSLog(@"52: %@", NSStringFromRect([view bounds]));
	[view translateOriginToPoint:NSMakePoint(-50.0, 0.0)];
	NSLog(@"53: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.0];
	NSLog(@"54: %@", NSStringFromRect([view bounds]));	// here we are back to 50
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];	// this resets the bounds scaling
	NSLog(@"60: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:45.0];
	NSLog(@"61: %@", NSStringFromRect([view bounds]));
	[view translateOriginToPoint:NSMakePoint(50.0, 0.0)];
	NSLog(@"62: %@", NSStringFromRect([view bounds]));
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];
	NSLog(@"63: %@", NSStringFromRect([view bounds]));
	[view translateOriginToPoint:NSMakePoint(-100.0, 0.0)];
	NSLog(@"64: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.0];
	NSLog(@"65: %@", NSStringFromRect([view bounds]));	// origin 0,0 size 200,200
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 100.0)];	// this resets the bounds scaling
	NSLog(@"70: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:90.0];
	NSLog(@"71: %@", NSStringFromRect([view bounds]));
	[view translateOriginToPoint:NSMakePoint(50.0, 0.0)];	// should translate y - no, still translates x
	NSLog(@"72: %@", NSStringFromRect([view bounds]));
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 1.0)];		// should scale y - no, scales x
	NSLog(@"73: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.0];
	NSLog(@"74: %@", NSStringFromRect([view bounds]));
	[view scaleUnitSquareToSize:NSMakeSize(1.0, 2.0)];		// should scale y back
	NSLog(@"75: %@", NSStringFromRect([view bounds]));
	[view translateOriginToPoint:NSMakePoint(0.0, -50.0)];	// should translate y back
	// this shows that bounds rotation is handled (mostly) independent of translation&scaling in a second step
	[view setBounds:NSMakeRect(0.0, 0.0, 100.0, 90.0)];	// this resets the bounds scaling
	NSLog(@"80: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:90.0];
	NSLog(@"81: %@", NSStringFromRect([view bounds]));	// (0.0, 0.0) -> (0.0=+x, -100.0=-y-width)
	[view setBounds:NSMakeRect(20.0, 40.0, 100.0, 90.0)];
	NSLog(@"82: %@", NSStringFromRect([view bounds]));	// (20.0, 40.0) -> (20.0=+x, -60.0=-y-x) 
	[view setBoundsRotation:0.0];
	NSLog(@"83: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:90.0];
	NSLog(@"84: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:45.0];
	NSLog(@"85: %@", NSStringFromRect([view bounds]));	// (20.0, 40.0) -> (-14.14=-x*sqrt(0.5), -28.28=-y*sqrt(0.5))
	[view setBounds:NSMakeRect(20.0, 30.0, 40.0, 50.0)];
	NSLog(@"86: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.0];
	NSLog(@"87: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:45.0];
	NSLog(@"88: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:1.0];
	[view setBounds:NSMakeRect(1.0, 10.0, 100.0, 1000.0)];
	NSLog(@"90: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.0];
	NSLog(@"91: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:2.0];
	NSLog(@"92: %@", NSStringFromRect([view bounds]));
	[view setBoundsSize:NSMakeSize(200.0, 300.0)];
	NSLog(@"93: %@", NSStringFromRect([view bounds]));	// this changes even the origin!
	[view setBoundsRotation:0.1];
	NSLog(@"100: %@", NSStringFromRect([view bounds]));
	[view setBounds:NSMakeRect(1.0, 10.0, 100.0, 1000.0)];
	NSLog(@"101: %@", NSStringFromRect([view bounds]));
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.3)];
	NSLog(@"102: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.0];
	NSLog(@"103: %@", NSStringFromRect([view bounds]));
	[view scaleUnitSquareToSize:NSMakeSize(1.0/0.5, 1.0/0.3)];	// neutralizes the size changes
	NSLog(@"104: %@", NSStringFromRect([view bounds]));
	[view setBoundsRotation:0.1];
	NSLog(@"105: %@", NSStringFromRect([view bounds]));	// neutralizes rotation AND (!) size changes
	[view setBoundsRotation:0.1];
	NSLog(@"110: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);
	[view setBounds:NSMakeRect(1.0, 10.0, 100.0, 1000.0)];
	NSLog(@"111: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);
	[view setBoundsRotation:0.2];
	NSLog(@"112: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.2f);
	[view setBoundsRotation:0.1];
	NSLog(@"113: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);	// == 111 (!!!!)
	[view scaleUnitSquareToSize:NSMakeSize(0.5, 0.3)];
	NSLog(@"114: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);
	[view setBoundsRotation:0.2];
	NSLog(@"115: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.2f);	// bounds.size == scaled(100.0, 1000.0)
	[view setBoundsRotation:0.1];
	NSLog(@"116: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);	// != 113 !!!!
	[view setBoundsRotation:0.2];
	NSLog(@"115b: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.2f);	// == 115
	[view setBoundsRotation:0.1];
	NSLog(@"116b: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);	// == 116
	[view scaleUnitSquareToSize:NSMakeSize(1.0/0.5, 1.0/0.3)];	// does NOT neutralize the size changes (immediately)
	NSLog(@"117: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);	// != 111 (!!!!)
	[view setBoundsRotation:0.2];
	NSLog(@"118: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.2f);	// == 112 -- here, size is neutralized again
	[view setBoundsRotation:0.1];
	NSLog(@"119: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);	// == 111
	[view rotateByAngle:0.1];
	NSLog(@"120: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.2f);	// == 112
	[view rotateByAngle:0.0];
	NSLog(@"120b: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.2f);	// == 112
	[view setBoundsRotation:0.1];
	NSLog(@"121: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-0.1f);	// == 111
	
	[view setBounds:(NSRect){{30.4657, 88.5895}, {21.2439, 60.8716}}];
	[view setBoundsRotation:30];
	NSLog(@"130: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-30.0f);
	[view setBounds:(NSRect){{30.4657, 88.5895}, {21.2439, 60.8716}}];
	NSLog(@"131: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-30.0f);
	[view scaleUnitSquareToSize:(NSSize){0.720733, 0.747573}];
	NSLog(@"132: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-30.0f);
	[view setBoundsRotation:30-1e-6];
	NSLog(@"133: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-30.0f);
	[view rotateByAngle:1e-6];
	NSLog(@"134: %@ %g %g", NSStringFromRect([view bounds]), [view boundsRotation], [view boundsRotation]-30.0f);
#endif

@end
