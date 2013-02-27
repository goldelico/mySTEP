//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSStringTest.h"


@implementation NSStringTest

#define TEST1(NAME, INPUT, METHOD, OUTPUT) - (void) test##NAME; { STAssertEqualObjects(OUTPUT, [INPUT METHOD], nil); }
#define TEST2(NAME, INPUT, ARG, METHOD, OUTPUT) - (void) test##NAME; { STAssertEqualObjects(OUTPUT, [INPUT METHOD:ARG], nil); }

// FIXME: test creation, conversions, add, mutability, isEqual etc.

TEST1(lowercaseString1, @"LowerCase", lowercaseString, @"lowercase");
TEST1(lowercaseString2, @"Lower Case", lowercaseString, @"lower case");
TEST1(lowercaseString3, @"Lower Case ÄÖÜ", lowercaseString, @"lower case äöü");
TEST1(lowercaseString4, @"lowercase", lowercaseString, @"lowercase");
TEST1(lowercaseString5, @"", lowercaseString, @"");

TEST1(stringByDeletingLastPathComponent1, @"/tmp/scratch.tiff", stringByDeletingLastPathComponent, @"/tmp");
TEST1(stringByDeletingLastPathComponent2, @"tmp/scratch.tiff", stringByDeletingLastPathComponent, @"tmp");
TEST1(stringByDeletingLastPathComponent3, @"/tmp/lock/", stringByDeletingLastPathComponent, @"/tmp");
TEST1(stringByDeletingLastPathComponent4, @"/tmp/", stringByDeletingLastPathComponent, @"/");
TEST1(stringByDeletingLastPathComponent5, @"/tmp", stringByDeletingLastPathComponent, @"/");
TEST1(stringByDeletingLastPathComponent6, @"/", stringByDeletingLastPathComponent, @"/");
TEST1(stringByDeletingLastPathComponent7, @"scratch.tiff", stringByDeletingLastPathComponent, @"");

TEST1(stringByDeletingLastPathComponent8, @"//tmp/scratch.tiff", stringByDeletingLastPathComponent, @"/tmp");
TEST1(stringByDeletingLastPathComponent9, @"//", stringByDeletingLastPathComponent, @"/");
// TEST(stringByDeletingLastPathComponent10, [NSNull null], stringByDeletingLastPathComponent, @"exception...");

TEST2(componentsSeparatedByString1, @"a:b", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"b", nil]));
TEST2(componentsSeparatedByString2, @"ab", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"ab", nil]));
TEST2(componentsSeparatedByString3, @":b", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"", @"b", nil]));
TEST2(componentsSeparatedByString4, @"a:", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"", nil]));
TEST2(componentsSeparatedByString5, @"a::b", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"", @"b", nil]));
TEST2(componentsSeparatedByString6, @"a:::b", @"::", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @":b", nil]));
TEST2(componentsSeparatedByString7, @"a::::b", @"::", componentsSeparatedByString, ([NSArray arrayWithObjects:@"a", @"", @"b", nil]));
TEST2(componentsSeparatedByString8, @":", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"", @"", nil]));
TEST2(componentsSeparatedByString9, @"", @":", componentsSeparatedByString, ([NSArray arrayWithObjects:@"", nil]));

// add many more such tests


@end
