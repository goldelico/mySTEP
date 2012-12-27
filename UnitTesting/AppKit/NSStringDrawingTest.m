//
//  NSStringDrawingTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSStringDrawingTest.h"


@implementation NSStringDrawingTest

// test sizing of strings and attributed strings

- (void) test1;
{
	NSSize sz=[@"abc" sizeWithAttributes:nil];
	STAssertTrue(sz.height == 1.25*12, nil);	// default font size is 12pt and 25% line spacing
}

- (void) test2;
{
	NSSize sz=[@"" sizeWithAttributes:nil];	// empty string is the same
	STAssertTrue(sz.width == 0 && sz.height == 1.25*12, nil);	// default font size is 15
}

- (void) test3;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName, nil];
	NSSize sz=[@"abc" sizeWithAttributes:attr];
	STAssertTrue(sz.height == 1.25*12, nil);	// default font appears to be Helvetica 12
}

- (void) test4;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"abc" sizeWithAttributes:attr];
	STAssertTrue(sz.height == 1.25*24, nil);
}

// check that size is the same as infinite bounds for a string with multiple lines

@end
