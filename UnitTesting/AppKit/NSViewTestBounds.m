//
//  NSViewTestBounds.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSViewTestBounds.h"


@implementation NSViewTestBounds

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
	STAssertTrue(view != nil, nil);
}

- (void) test02
{ // default rotation
	STAssertTrue([view frameRotation] == 0.0, nil);
	STAssertTrue([view boundsRotation] == 0.0, nil);
}

// do rotation tests
// and pinpoint some special observations
// mix setBoundsSize, setBoundsOrigin, setBounds while bounds are rotated

@end
