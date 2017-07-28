//
//  NSTextFieldCellTest.m
//  AppKit
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>


@interface NSTextFieldCellTest : XCTestCase {
	
}

@end

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit

@implementation NSTextFieldCellTest

- (void) testTextFieldCell;
{
	NSTextFieldCell *c = [[NSTextFieldCell alloc] init];
	[c setTitle:@"title1"];
	XCTAssertEqualObjects(@"title1", [c title], @"");
	[c setTitle:@"title2"];
	XCTAssertEqualObjects(@"title2", [c title], @"");
	XCTAssertThrows([c setTitle:nil], @"");	// not allowed
	XCTAssertEqualObjects(@"title2", [c title], @"");	// unchanged
	[c setStringValue:@"string1"];
	XCTAssertEqualObjects(@"string1", [c stringValue], @"");
	XCTAssertEqualObjects(@"string1", [c title], @"");	// title has been changed as well!
	[c setTitle:@"title1"];
	XCTAssertEqualObjects(@"title1", [c stringValue], @"");
	XCTAssertEqualObjects(@"title1", [c title], @"");	// title has been changed as well!
	[c release];
}

- (void) testCell;
{
	NSCell *c = [[NSCell alloc] init];
	[c setTitle:@"title1"];
	XCTAssertEqualObjects(@"title1", [c title], @"");
	[c setTitle:@"title2"];
	XCTAssertEqualObjects(@"title2", [c title], @"");
	XCTAssertThrows([c setTitle:nil], @"NSCell throws on setTitle:nil");	// not allowed
	XCTAssertEqualObjects(@"title2", [c title], @"");	// unchanged
	[c setStringValue:@"string1"];
	XCTAssertEqualObjects(@"string1", [c stringValue], @"");
	XCTAssertEqualObjects(@"string1", [c title], @"");	// title has been changed as well!
	[c setTitle:@"title1"];
	XCTAssertEqualObjects(@"title1", [c stringValue], @"");
	XCTAssertEqualObjects(@"title1", [c title], @"");	// title has been changed as well!
	[c release];
}

- (void) testButtonCell;
{
	NSButtonCell *c = [[NSButtonCell alloc] init];
	[c setTitle:@"title1"];
	XCTAssertEqualObjects(@"title1", [c title], @"");
	[c setTitle:@"title2"];
	XCTAssertEqualObjects(@"title2", [c title], @"");
	XCTAssertNoThrow([c setTitle:nil], @"NSButtonCell accepts setTitle:nil");	// can be set to nil (which is different to NSCell)
	XCTAssertEqualObjects(@"", [c title], @"");	// title will be cleared
	[c setStringValue:@"string1"];
	XCTAssertEqualObjects(@"1", [c stringValue], @"");
	XCTAssertEqualObjects(@"", [c title], @"");	// title has not been changed
	[c setTitle:@"title1"];
	XCTAssertEqualObjects(@"1", [c stringValue], @"");
	XCTAssertEqualObjects(@"title1", [c title], @"");	// title has been changed as well!
	[c release];
}

@end
