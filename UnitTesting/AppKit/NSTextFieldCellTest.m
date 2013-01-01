//
//  NSTextFieldCellTest.m
//  AppKit
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSTextFieldCellTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit

@implementation NSTextFieldCellTest

- (void) testTextFieldCell;
{
	NSTextFieldCell *c = [[NSTextFieldCell alloc] init];
	[c setTitle:@"title1"];
	STAssertEqualObjects(@"title1", [c title], nil);
	[c setTitle:@"title2"];
	STAssertEqualObjects(@"title2", [c title], nil);
	STAssertThrows([c setTitle:nil], nil);	// not allowed
	STAssertEqualObjects(@"title2", [c title], nil);	// unchanged
	[c setStringValue:@"string1"];
	STAssertEqualObjects(@"string1", [c stringValue], nil);
	STAssertEqualObjects(@"string1", [c title], nil);	// title has been changed as well!
	[c setTitle:@"title1"];
	STAssertEqualObjects(@"title1", [c stringValue], nil);
	STAssertEqualObjects(@"title1", [c title], nil);	// title has been changed as well!
	[c release];
}

- (void) testCell;
{
	NSCell *c = [[NSCell alloc] init];
	[c setTitle:@"title1"];
	STAssertEqualObjects(@"title1", [c title], nil);
	[c setTitle:@"title2"];
	STAssertEqualObjects(@"title2", [c title], nil);
	STAssertThrows([c setTitle:nil], @"NSCell throws on setTitle:nil");	// not allowed
	STAssertEqualObjects(@"title2", [c title], nil);	// unchanged
	[c setStringValue:@"string1"];
	STAssertEqualObjects(@"string1", [c stringValue], nil);
	STAssertEqualObjects(@"string1", [c title], nil);	// title has been changed as well!
	[c setTitle:@"title1"];
	STAssertEqualObjects(@"title1", [c stringValue], nil);
	STAssertEqualObjects(@"title1", [c title], nil);	// title has been changed as well!
	[c release];
}

- (void) testButtonCell;
{
	NSButtonCell *c = [[NSButtonCell alloc] init];
	[c setTitle:@"title1"];
	STAssertEqualObjects(@"title1", [c title], nil);
	[c setTitle:@"title2"];
	STAssertEqualObjects(@"title2", [c title], nil);
	STAssertNoThrow([c setTitle:nil], @"NSButtonCell accepts setTitle:nil");	// can be set to nil (which is different to NSCell)
	STAssertEqualObjects(@"", [c title], nil);	// title will be cleared
	[c setStringValue:@"string1"];
	STAssertEqualObjects(@"1", [c stringValue], nil);
	STAssertEqualObjects(@"", [c title], nil);	// title has not been changed
	[c setTitle:@"title1"];
	STAssertEqualObjects(@"1", [c stringValue], nil);
	STAssertEqualObjects(@"title1", [c title], nil);	// title has been changed as well!
	[c release];
}

@end
