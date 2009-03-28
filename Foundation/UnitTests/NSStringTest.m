//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSStringTest.h"


@implementation NSStringTest

- (void) testLowerCase
{
	STAssertEqualObjects(@"lowercase", [@"LowerCase" lowercaseString],
								 @"result was %@ instead!", 
								 [@"LowerCase" lowercaseString]);	
}

@end
