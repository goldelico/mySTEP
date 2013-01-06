//
//  NSScannerTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSScannerTest.h"


@implementation NSScannerTest

- (void) testFloatExponent
{
	NSScanner *sc=[NSScanner scannerWithString:@"1.0e+2m"];
	float flt=0.0;
	NSString *em=@"";
	[sc scanFloat:&flt];
	[sc scanString:@"m" intoString:&em];
	NSLog(@"flt=%g", flt);
	NSLog(@"em=%@", em);
	NSLog(@"scanLocation=%u", [sc scanLocation]);
	STAssertTrue(flt == 1e+2, @"flt=1e+2");
	STAssertEqualObjects(em, @"m", @"e is part of exponent");
	STAssertTrue([sc scanLocation] == 7, @"all scanned");
	STAssertTrue([sc isAtEnd], @"is at end");
}

- (void) testFloatNonExponent
{
	NSScanner *sc=[NSScanner scannerWithString:@"1.0em"];
	float flt=0.0;
	NSString *em=@"";
	[sc scanFloat:&flt];
	[sc scanString:@"em" intoString:&em];
	NSLog(@"flt=%g", flt);
	NSLog(@"em=%@", em);
	NSLog(@"scanLocation=%u", [sc scanLocation]);
	STAssertTrue(flt == 1.0, @"flt=1.0");
	STAssertEqualObjects(em, @"em", @"em is not part of exponent");
	STAssertTrue([sc scanLocation] == 5, @"all scanned");
	STAssertTrue([sc isAtEnd], @"is at end");
}

/* test
 * isAtEnd
 * scanning integer, hex, longlong
 * scanning strings (found/not found)
 * scanning character set (found/not found)
 * scanning up-to
 * skipping/not skipping
 * case sensitive/insensive
 * (in)dependence from locale
 * dependence on ignored character set (what if this is nil?)
 */

@end
