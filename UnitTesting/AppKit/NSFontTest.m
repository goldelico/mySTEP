//
//  NSFontTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSFontTest.h"

@implementation NSFontTest

- (void) test1
{
	STAssertNotNil([NSFont userFontOfSize:20.0], nil);
	STAssertEquals([[NSFont userFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEquals([[NSFont userFontOfSize:0.0] pointSize], 12.0f, nil);
	STAssertNotNil([NSFont systemFontOfSize:20.0], nil);
	STAssertEquals([[NSFont systemFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEquals([NSFont systemFontSize], 13.0f, nil);
	STAssertEquals([NSFont smallSystemFontSize], 11.0f, nil);
	STAssertEquals([[NSFont systemFontOfSize:0.0] pointSize], 13.0f, nil);
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
	STAssertEquals([font pointSize], 12.0f, nil);
	STAssertEquals([font ascender], 9.240234375f, nil);
	STAssertEquals([font descender], -2.759765625f, nil);	// negative value!
	STAssertEquals([font leading], 0.0f, nil);
	STAssertEquals([font capHeight], 8.607421875f, nil);
	STAssertEquals([font xHeight], 6.275390625f, nil);
	STAssertFalse([font isFixedPitch], nil);
}

- (void) test3
{
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	NSGlyph g=[font glyphWithName:@"x"];
	// check glyph dimensions and advancement
}

@end
