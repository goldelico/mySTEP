//
//  NSFontTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSFontTest.h"

#define STAssertEqualFloats(A, B) STAssertTrue(A == B, @"%g == %g", A, B)

@implementation NSFontTest

- (void) test1
{
	STAssertNotNil([NSFont userFontOfSize:20.0], nil);
	STAssertEqualFloats([[NSFont userFontOfSize:20.0] pointSize], 20.0);
	STAssertEqualFloats([[NSFont userFontOfSize:0.0] pointSize], 12.0);
	STAssertNotNil([NSFont systemFontOfSize:20.0], nil);
	STAssertEqualFloats([[NSFont systemFontOfSize:20.0] pointSize], 20.0);
	STAssertEqualFloats([NSFont systemFontSize], 13.0);
	STAssertEqualFloats([NSFont smallSystemFontSize], 11.0);
	STAssertEqualFloats([[NSFont systemFontOfSize:0.0] pointSize], 13.0);
	STAssertEqualObjects([[NSFont userFontOfSize:0.0] fontName], @"Helvetica", nil);
	STAssertEqualObjects([[NSFont systemFontOfSize:0.0] fontName], @"LucidaGrande", nil);
	STAssertEqualObjects([[NSFont labelFontOfSize:0.0] fontName], @"LucidaGrande", nil);
	STAssertEqualObjects([[NSFont menuFontOfSize:0.0] fontName], @"LucidaGrande", nil);
	/*
	 - systemFontOfSize: 0 is LucidaGrande-13
	 - userFontOfSize: 0 is Helvetica-12
	 */
}

- (void) test2
{
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	NSLog(@"%.10f", [font xHeight]);
	STAssertEqualObjects([font fontName], @"Helvetica", nil);
	STAssertEqualFloats([font pointSize], 12.0);
	STAssertEqualFloats([font ascender], 9.240234375);
	STAssertEqualFloats([font descender], -2.759765625);	// negative value!
	STAssertEqualFloats([font leading], 0.0);
	STAssertEqualFloats([font capHeight], 8.607421875);
	STAssertEqualFloats([font xHeight], 6.275390625);
	STAssertFalse([font isFixedPitch], nil);
}

- (void) test3
{
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	NSGlyph g=[font glyphWithName:@"x"];
	// check glyph dimensions and advancement
}

@end
