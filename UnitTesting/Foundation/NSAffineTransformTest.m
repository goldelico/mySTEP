//
//  NSAffineTransformTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 07.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSAffineTransformTest.h"


@implementation NSAffineTransformTest

- (void) setUp
{
	t=[[NSAffineTransform alloc] init];
	STAssertNotNil(t, nil);
}

- (void) tearDown
{
	[t release];
}

- (void) test01
{
	
}

// flipping, rotation, translation, concatenation, transforming points, ...

@end
