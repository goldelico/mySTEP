//
//  NSScannerTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>


@interface NSScannerTest : XCTestCase {
	
}

@end


@implementation NSScannerTest

- (void) testFloatExponent
{
	NSScanner *sc=[NSScanner scannerWithString:@"1.0e+2m"];
	float flt=0.0;
	NSString *em=@"";
	[sc scanFloat:&flt];
	[sc scanString:@"m" intoString:&em];
	XCTAssertEqual(flt, 1e+2f, @"flt=1e+2");
	XCTAssertEqualObjects(em, @"m", @"e is part of exponent");
	XCTAssertEqual([sc scanLocation], (NSUInteger) 7, @"all scanned");
	XCTAssertTrue([sc isAtEnd], @"is at end");
}

- (void) testFloatNonExponent
{
	NSScanner *sc=[NSScanner scannerWithString:@"1.0em"];
	float flt=0.0;
	NSString *em=@"";
	[sc scanFloat:&flt];
	[sc scanString:@"em" intoString:&em];
	XCTAssertEqual(flt, 1.0f, @"flt=1.0");
	XCTAssertEqualObjects(em, @"em", @"em is not part of exponent");
	XCTAssertEqual([sc scanLocation], (NSUInteger) 5, @"all scanned");
	XCTAssertTrue([sc isAtEnd], @"is at end");
}

// to be verified!
- (void) testWeird
{
	NSScanner *sc=[NSScanner scannerWithString:@" b"];
	NSString *str=nil;
	BOOL flag;
	flag=[sc scanString:@" " intoString:&str];
	XCTAssertFalse(flag, @"does not match");
	XCTAssertNil(str, @"string is not modified");
	[sc setCharactersToBeSkipped:nil];	// noting to be skipped
	flag=[sc scanString:@" " intoString:&str];
	XCTAssertTrue(flag, @"does match");
	XCTAssertEqualObjects(str, @" ", @"string is space");
}

/* test
 * isAtEnd
 * scanning integer, hex, longlong
 * scanning strings (found/not found)
 * scanning character set (found/not found)
 * scanning up-to
 * skipping/not skipping
 * case sensitive/insensive
 * default charactersToBeSkipped
 * (in)dependence from locale
 * dependence on ignored character set (what if this is nil?)
 */

@end
