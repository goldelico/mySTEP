//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSStringTest.h"


@implementation NSStringTest

#define test(NAME, INPUT, METHOD, OUTPUT) - (void) test##NAME; { STAssertEqualObjects(OUTPUT, [INPUT METHOD], nil); }
#define test1(NAME, INPUT, ARG, METHOD, OUTPUT) - (void) test##NAME; { STAssertEqualObjects(OUTPUT, [INPUT METHOD:ARG], nil); }

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

test1(componentsSeparatedByString1, @"a:b", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"b", nil]));
test1(componentsSeparatedByString2, @"ab", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"ab", nil]));
test1(componentsSeparatedByString3, @":b", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"", @"b", nil]));
test1(componentsSeparatedByString4, @"a:", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"", nil]));
test1(componentsSeparatedByString5, @"a::b", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"", @"b", nil]));
test1(componentsSeparatedByString6, @"a:::b", @"::", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @":b", nil]));
test1(componentsSeparatedByString7, @"a::::b", @"::", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"", @"b", nil]));
test1(componentsSeparatedByString8, @":", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"", @"", nil]));
test1(componentsSeparatedByString9, @"", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"", nil]));

// add many more such tests


@end
