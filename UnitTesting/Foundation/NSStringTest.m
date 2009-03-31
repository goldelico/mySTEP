//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSStringTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit

@implementation NSStringTest

#define test(NAME, INPUT, METHOD, OUTPUT) - (void) test##NAME; { STAssertEqualObjects(OUTPUT, [INPUT METHOD], nil); }

// test creation, conversions, add, mutability etc.

test(lowercaseString1, @"LowerCase", lowercaseString, @"lowercase");
test(lowercaseString2, @"Lower Case", lowercaseString, @"lower case");
test(lowercaseString3, @"Lower Case ÄÖÜ", lowercaseString, @"lower case äöü");
test(lowercaseString4, @"lowercase", lowercaseString, @"lowercase");
test(lowercaseString5, @"", lowercaseString, @"");

test(stringByDeletingLastPathComponent1, @"/tmp/scratch.tiff", stringByDeletingLastPathComponent, @"/tmp");
test(stringByDeletingLastPathComponent2, @"tmp/scratch.tiff", stringByDeletingLastPathComponent, @"tmp");
test(stringByDeletingLastPathComponent3, @"/tmp/lock/", stringByDeletingLastPathComponent, @"/tmp");
test(stringByDeletingLastPathComponent4, @"/tmp/", stringByDeletingLastPathComponent, @"/");
test(stringByDeletingLastPathComponent5, @"/tmp", stringByDeletingLastPathComponent, @"/");
test(stringByDeletingLastPathComponent6, @"/", stringByDeletingLastPathComponent, @"/");
test(stringByDeletingLastPathComponent7, @"scratch.tiff", stringByDeletingLastPathComponent, @"");

test(stringByDeletingLastPathComponent8, @"//tmp/scratch.tiff", stringByDeletingLastPathComponent, @"/tmp");
test(stringByDeletingLastPathComponent9, @"//", stringByDeletingLastPathComponent, @"/");
// test(stringByDeletingLastPathComponent10, [NSNull null], stringByDeletingLastPathComponent, @"exception...");

// add many more such tests


@end
