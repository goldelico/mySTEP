//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSStringTest.h"

// see http://developer.apple.com/tools/unittest.html

@implementation NSStringTest

#define test(INPUT, METHOD, OUTPUT) - (void) test##INPUT; { STAssertEqualObjects(@#OUTPUT, [@#INPUT METHOD], @"Expected %@, result was %@ instead!", @#OUTPUT, [@#INPUT METHOD]); }

// test(@"LowerCase", lowercaseString, @"lowercase");
// test(@"Lower Case", lowercaseString, @"lower case");
// test(@"Lower Case ÄÖÜ", lowercaseString, @"lower case äöü");
// test(@"lowercase", lowercaseString, @"lowercase");
// test(@"", lowercaseString, @"");

// add many more such tests

// test convertion, add, mutability

- (void) testLowerCase
{
	STAssertEqualObjects(@"lowercase", [@"LowerCase" lowercaseString], @"result was %@ instead!", [@"LowerCase" lowercaseString]);	
}

@end
